library(nhdR)
library(sf)

bbox <- data.frame(xmin = -73.33838, ymin = 41.32841,
                   xmax = -73.14540, ymax = 41.66593)
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

devtools::use_data(nhd_sub, overwrite = TRUE)
