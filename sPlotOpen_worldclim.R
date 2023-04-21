library(geodata)
library(rnaturalearth)
library(terra)
library(sf)
library(tidyverse)

region = rnaturalearth::ne_countries(continent = "South America", returnclass = "sf")
st_write(region, "data/modeldomain.gpkg", append = FALSE)

# worldclim for prediction
wc = rast(list.files("~/data/global_environmental_layer/geodata_5m/", full.names = TRUE))
wc = crop(wc, region)
names(wc) = names(wc) |> str_remove(pattern = "wc2.1_5m_")

# add latitude and longitude as a layer
wc$lat = terra::init(wc, "y")
wc$lon = terra::init(wc, "x")
writeRaster(wc, "data/predictors.tif", overwrite = TRUE)


# worldclim full resolution for extracting
wcf = rast(list.files("~/data/global_environmental_layer/geodata_30s/", full.names = TRUE))
wcf = crop(wcf, region)
names(wcf) = names(wcf) |> str_remove(pattern = "wc2.1_30s_")
wcf$lat = terra::init(wcf, "y")
wcf$lon = terra::init(wcf, "x")



# splot data

load("~/data/sPlotOpen/sPlotOpen.RData")


splot = header.oa |>
    filter(Resample_1 == TRUE) |>
    filter(Continent == "South America") |> 
    st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) |> 
    left_join(CWM_CWV.oa |> select(c("PlotObservationID", "Species_richness", "SLA_CWM", "LDMC_CWM"))) |> 
    select(c("PlotObservationID", "GIVD_ID", "Country", "Biome",
             "Species_richness", "LDMC_CWM", "SLA_CWM")) |> 
    na.omit()


splot = terra::extract(wcf, splot, ID = FALSE, bind = TRUE) |>
    st_as_sf() |> 
    na.omit()



plots_uni = splot[!duplicated(c(splot$lat, splot$lon)),]
plots_uni = plots_uni |> na.omit()

st_write(plots_uni, "data/plots.gpkg", append = FALSE)


