rm(list=ls())
pacman::p_load(ggplot2, leaflet, data.table, dplyr, dtplyr, sp, rgdal)  

load_zip <- function(method="wget"){
  dataurl <- "http://www.ofm.wa.gov/pop/geographic/tiger10/zcta510.zip"
  tempfile <- tempfile()
  tempfolder <- tempdir()
  download.file(dataurl, tempfile, method=method)
  unzip(tempfile, exdir=tempfolder)
  zipspdf <- readOGR(tempfolder)
  return(zipspdf)
}


spdf2leaf <- function(df, col="data", label=NULL){
  df@data$data <- df@data[,col]
  lab_label <- ifelse(is.null(label), col, label)
  
  # pop up info
  popup <- paste0("ZIPCODE: ", df@data$ZIPCODE, 
                  "<br> Value: ", df@data$data)
  
  # color palette
  pal <- colorNumeric(palette="YlGnBu", domain=df@data$data)
  
  # see map
  map1<-leaflet() %>%
    addProviderTiles("CartoDB.Positron") %>%
    addPolygons(data=df, fillColor=~pal(data), color="#b2aeae", weight=0.3,
                fillOpacity=0.5, smoothFactor=0.2, popup=popup) %>%
    addLegend("bottomright", pal=pal, values=df$data,
              title = lab_label, opacity = 1)
  map1
}

DF <- fread("~/Downloads/rawrestscore.csv")
DF[,ZIPCODE:=substr(ZIPCODE, 1, 5)]
DFZIP <- DF[, list(MEAN=mean(ESTSCORE)),by=ZIPCODE]
DFZIP <- left_join(DFZIP, DF[, list(MEDIAN=median(ESTSCORE)),by=ZIPCODE]) 

zipspdf <- load_zip()
zipspdf@data$ZIPCODE <- as.character(zipspdf@data$ZCTA5CE10)
zipspdf@data <- left_join(zipspdf@data, as.data.frame(DFZIP))
p4s <- "+title=WGS 84 (long/lat) +proj=longlat +ellps=WGS84 +datum=WGS84"
zipspdf <- spTransform(zipspdf, CRS(p4s))
head(zipspdf@data)

spdf2leaf(zipspdf, "MEAN", "Mean Value<br>Raw Score")
spdf2leaf(zipspdf, "MEDIAN", "Median Value<br>Raw Score")
