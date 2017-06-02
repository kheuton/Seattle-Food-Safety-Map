library(leaflet)
library(data.table)
library(MapSuite)

rm(list=ls())

  # Set up directories
  shp_dir<-"C:/Users/stubbsrw/Desktop/restaurant_inspections/"
  shapefile_name<-"restaurant_inspections"
  
  if(!file.exists(paste0(shp_dir,"shp.Rdata"))){
    shp<-readOGR(paste0(shp_dir, shapefile_name,".shp"), layer=shapefile_name) 
    save(shp,file=paste0(shp_dir,"shp.Rdata"))
  }else{
    load(paste0(shp_dir,"shp.Rdata"))
  }
    
# Shapefile Prep
#~~~~~~~~~~~~~~~~~~~~
  # Re-project shp to projection used by web stuff, not what it comes in
  wgs_84<-"+proj=longlat +datum=WGS84 +no_defs"
    
  # From: http://spatialreference.org/ref/sr-org/7483/proj4/
    shp<-spTransform(shp, CRS(wgs_84))

  # Data.table with x,y coordinates:
    data<-cbind(shp@data,data.table(shp@coords))
    setnames(data,"coords.x1","long")
    setnames(data,"coords.x2","lat")

# Make Leaflet Map
#~~~~~~~~~~~~~~~~~~~~
    # You can find the emojis here: http://www.seattleglobalist.com/2017/01/17/seattle-king-county-food-safety-ratings-emojis/60993
  
    
m <- leaflet(data = data[1:100,]) %>% 
  setView(lng =-122.3321  , lat = 47.6062 , zoom = 8) %>% 
  addProviderTiles(providers$CartoDB.Positron) %>% 
  addMarkers(~long, ~lat, popup = ~as.character(NAME), label = ~as.character(NAME))

m 
