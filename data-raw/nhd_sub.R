library(nhdR)
library(sf)
library(riverdist)

bbox <- data.frame(xmin = -73.33838, ymin = 41.35841,
                   xmax = -73.14540, ymax = 41.48593)
b0 <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(bbox$xmin, bbox$ymin),
    c(bbox$xmax, bbox$ymin),
    c(bbox$xmax, bbox$ymax),
    c(bbox$xmin, bbox$ymax),
    c(bbox$xmin, bbox$ymin)))))
sf::st_crs(b0) <- 4326
b0 <- st_transform(b0, sf::st_crs(nhdR::vpu_shp))

nhd <- nhd_plus_query(poly = b0, dsn = c("NHDFlowLine"))
nhd_sub <- nhd$sp$NHDFlowLine
# mapview::mapview(nhd_sub)
crs <- st_crs(nhd_sub)
nhd_sub_sp <- as(nhd_sub, "Spatial")

nhd_sub_rv <- riverdist::line2network(nhd_sub_sp, tolerance = 1)
# riverdist::showends(2, nhd_sub)
nhd_sub_rv <- suppressMessages(autoclean(nhd_sub_sp,
                                      mouthseg = 2,
                                      mouthvert = 3,
                                      crs = crs))

# mapview::mapview(nhd_sub, zcol = "rivID")

devtools::use_data(nhd_sub, overwrite = TRUE)
devtools::use_data(nhd_sub_rv, overwrite = TRUE)
