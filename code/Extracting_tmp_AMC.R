#################################################################################
#
# Francisco Cavalcanti
# Website: https://sites.google.com/view/franciscocavalcanti/
# GitHub: https://github.com/FranciscoCavalcanti
# Twitter: https://twitter.com/Franciscolc85
# LinkedIn: https://www.linkedin.com/in/francisco-de-lima-cavalcanti-5497b027/
#
#################################################################################


#################################################################################
#
# The purpose is to extract monthly data of
# Temperature
# for every Brazilians AMC
#
# There are two important datasets:
#
# 1) Shapefile data of AMC for Brazil
# 2) NetCDF data of temperature from CRU
#
# The outcome is .csv files by month and AMC
#
#################################################################################


####################
# install packages
####################

# install.packages("ncdf4", "raster", "sf", "tmap")
# install.packages("tmap")
# install.packages("tidyverse")

# installing packages
# packages_vector <- c("ggplot2", "tidyverse", "dplyr")
# geopackages <- c("raster", "ncdf4", "sf")
# lapply(packages_vector, require, character.only = TRUE) # the "lapply" function means "apply this function to the elements of this list or more restricted data
# lapply(geopackages, require, character.only = TRUE)

####################
# Folder Path
####################

user <- Sys.info()[["user"]]
message(sprintf("Current User: %s\n"))
if (user == "Francisco") {
  ROOT <- "C:/Users/Francisco/Dropbox"
} else if (user == "f.cavalcanti") {
  ROOT <- "C:/Users/Francisco/Dropbox"
} else {
  stop("Invalid user")
}

out_dir <- file.path(ROOT, "Consultancy", "2021-Steven_Helfand", "New_Database_on_Climate", "build", "cru")
tmp_dir <- file.path(ROOT, "Consultancy", "2021-Steven_Helfand", "New_Database_on_Climate", "tmp")
data_shp_dir <- file.path(ROOT, "data_sources", "Shapefiles", "AMC_Ehrl")
data_ncdf_dir <- file.path(ROOT, "data_sources", "Climatologia", "CRU", "input")

####################
# load library
####################
library(R.utils)
library(tidyverse)
library(ncdf4)
library(raster)
library(sf)
library(tmap)
library(stringr)

# read shapefile
setwd(data_shp_dir)
shapefile <- st_read("amc_1980_2010.shp")
crs(shapefile)

# convert crs
shapefile <- st_transform(shapefile,
  crs = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0")
)

# additional check in the shapefile
str(shapefile)
extent(shapefile)
crs(shapefile)

###############################
# Extracting data from CRU
###############################

# Unzip
setwd(data_ncdf_dir)
fileinput <- list.files(pattern = "cru_ts4.05.1901.2020.tmp.dat.nc")
fileouput <- file.path(tmp_dir, "temperature.nc")
gunzip(fileinput, # Pathname of input file
  fileouput, # Pathname of output file
  overwrite = TRUE,
  remove = FALSE
)

# the data format: netcdf
setwd(tmp_dir)
list_files <- list.files(pattern = ".nc")
print(list_files)
length(list_files)

# call netcdf file
temp_file1 <- raster::brick(list_files) # read netcdf file

# check the data
extent(temp_file1)
crs(temp_file1)

# no need to convert longitude [0 360] to [-180 180]
# otherswise, run code:
# temp_file1 <- rotate(temp_file1)

# Ensure command extract is from raster package
extract <- raster::extract

# Extract the mean value of cells within AMC polygon
# Alternative: look to "mask" function ?mask
masked_file <- extract(temp_file1,
  shapefile,
  fun = mean,
  na.rm = TRUE,
  df = F,
  small = T,
  sp = T,
  weights = TRUE,
  normalizedweights = TRUE
)

#################################################
# Loop
#################################################

nl <- masked_file@data %>%
  length()

# begin of loop
for (i in 27:nl) {


  # extract only relevant variables
  munic <- masked_file$GEOCODIG_M
  amc_1980 <- masked_file$amc_1980_2
  tmp <- masked_file[i]
  date <- masked_file[i] %>%
    names() %>%
    str_sub(start = 2, end = 11)

  # Compile the codes for AMC and time variable in one dataframe
  df <- data.frame(munic, amc_1980, tmp, date)

  # rename variables
  colnames(df)[3] <- "monthly_tmp"

  # save data as .csv
  setwd(out_dir)
  write.csv(df,
    paste0(out_dir, "/amc_tmp_csv/", date, "_amc_tmp.csv"),
    row.names = TRUE,
  ) # overwrites

  # print
  print(i)
  print(date)
  # end of loop
}


# remove all
setwd(tmp_dir)
deletefiles <- list.files(pattern = ".nc")
file.remove(deletefiles)
