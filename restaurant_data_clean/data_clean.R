rm(list=ls())

pacman::p_load(sp, rgdal, data.table, dplyr, dtplyr, ggplot2)

load_foodspdf <- function(method="wget"){
    base <- "ftp://ftp.kingcounty.gov/gis-web/GISData/"
    dataurl <- paste0(base, "restaurant_inspections_SHP.zip")
    tempfile <- tempfile()
    tempfolder <- tempdir()
    download.file(dataurl, tempfile, method=method)
    unzip(tempfile, exdir=tempfolder)
    datafolder <- paste0(tempfolder, "/restaurant_inspections")
    foodspdf <- readOGR(datafolder)
    foodspdf@data <- as.data.table(foodspdf@data)
    # data is not numeric so we need to convert
    foodspdf@data[,SCORE_INSP:=as.numeric(as.character(SCORE_INSP))]
    foodspdf@data[,VIOLATIONP:=as.numeric(as.character(VIOLATIONP))]
    # there are some score insp that are below zero so we will drop them
    foodspdf <- subset(foodspdf, SCORE_INSP >= 0)
    # get rid of consultations we only want to routine and return inspections
    foodspdf <- subset(foodspdf, TYPE_INSPE != "Consultation/Education - Field")
    # only places with seatings get scores so we need to filter out the others
    foodspdf <- subset(foodspdf, grepl("Seating", SEAT_CAP))
    # We only want 
    foodspdf
}

foodspdf <- load_foodspdf()

facility_inspection_count <- function(foodspdf=load_foodspdf()){
    foodspdfsub <- unique(foodspdf@data[,list(NAME, PROGRAM_ID, 
                                              ADDRESS, DATE_INSPE)])
    foodspdfsub[,.N, by=list(NAME, PROGRAM_ID, ADDRESS)]
}

facility_total_score <- function(foodspdf=load_foodspdf()){
    foodspdfsub <- unique(foodspdf@data[,list(NAME, PROGRAM_ID, ADDRESS,
                                              DATE_INSPE, SCORE_INSP)])
    foodspdfsub[,sum(SCORE_INSP), by=list(NAME, PROGRAM_ID, ADDRESS)]
}

raw_score <- function(foodspdf=load_foodspdf()){
    DT <- as.data.table(left_join(facility_inspection_count(foodspdf),
                                  facility_total_score(foodspdf)))
    DT[,ESTSCORE:=V1/N]
    DT
}

ggplot(data=foodspdf@data,
       aes(x=VIOLATIONP, group=VIOLATIONT, fill=VIOLATIONT)) +
    geom_histogram() + scale_fill_manual(values=c("blue", "red"))

ggplot(data=foodspdf@data, aes(x=SCORE_INSP)) + geom_histogram()

DT <- raw_score(foodspdf)
DT <- left_join(DT, unique(foodspdf@data[,list(NAME, PROGRAM_ID, ADDRESS, 
                                               ZIPCODE, PHONE, LONGITUDE, 
                                               LATITUDE)]))
DT <- as.data.table(DT)

fwrite(DT, file="~/Downloads/rawrestscore.csv", row.names=FALSE)
