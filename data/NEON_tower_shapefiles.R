# Overlay shapefile of eddy covariance tower footprint on NEON CHM data

library(sf)
library(tidyverse)
library(neonUtilities)
library(raster)

# Read shapefile with the boundaries of a eddy covariance tower footprint
NEON_ECtower_fp <- sf::st_read("90percentfootprint/90percent_footprint.shp")

# Filter to the Blandy Farm tower footprint
ECtower_BLAN <- dplyr::filter(NEON_ECtower_fp, SiteID == "BLAN")

# Check current CRS of the footprint shapefile
st_crs(ECtower_BLAN) 

# Reproject the crs from longlat to UTM 17
# Define UTM 17N WGS84 proj4string
utm17nCRS <- "+proj=utm +zone=17 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
ECtower_BLAN_utm <- st_transform(ECtower_BLAN, utm17nCRS)

# Find limits of tower footprint to only download AOP that 
# is co-located with the footprint
BLAN_bbox <- st_bbox(ECtower_BLAN_utm)
BLAN_bbox

# Round easting/northing to nearest 1km for matching AOP tiles
BLAN_easting <- c(752000, 753000, 753000)
BLAN_northing <- c(4327000, 4327000, 4328000)

# Request ecosystem structure data from NEON API

# Download the canopy height tiles (1km grid) that correspond to tower footprint
# This will download to a folder called DP3.30015.001 where your project directory is
tmp <- byTileAOP(dpID = "DP3.30015.001", site = "BLAN", year = "2017",
                 easting = BLAN_easting, northing = BLAN_northing)

# Load the two canopy height as raster files, and merge into 1 raster
BLAN_chm_1 <- raster("DP3.30015.001/2017/FullSite/D02/2017_BLAN_2/L3/DiscreteLidar/CanopyHeightModelGtif/NEON_D02_BLAN_DP3_752000_4327000_CHM.tif")
BLAN_chm_2 <- raster("DP3.30015.001/2017/FullSite/D02/2017_BLAN_2/L3/DiscreteLidar/CanopyHeightModelGtif/NEON_D02_BLAN_DP3_753000_4327000_CHM.tif")

BLAN_chm <- merge(BLAN_chm_1, BLAN_chm_2)

# Check CHM crs
crs(BLAN_chm)

# Make raster a data frame
BLAN_chm_df <- as.data.frame(BLAN_chm, xy=TRUE)

# Plot the tower footprint shapefile onto the CHM
ggplot() +
  geom_raster(data = BLAN_chm_df,
              aes(x = x, y = y, fill = layer)) + 
  geom_sf(data = ECtower_BLAN_utm, color = "white", fill = NA) + 
  scale_fill_gradientn(name = "Canopy Height", colors = terrain.colors(10)) + 
  coord_sf()
  
