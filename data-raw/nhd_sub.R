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
# mapview(nhd_sub)
crs <- st_crs(nhd_sub)
nhd_sub <- as(nhd_sub, "Spatial")

nhd_sub <- riverdist::line2network(nhd_sub, tolerance = 1)
# riverdist::cleanup(nhd_sub)
nhd_sub <- riverdist::removeduplicates(rivers = nhd_sub)
nhd_sub <- riverdist::dissolve(nhd_sub)
nhd_sub <- removemicrosegs(nhd_sub)

nhd_sub <- setmouth(seg = as.numeric(2),
                    vert = as.numeric(3),
                    rivers = nhd_sub)

checked <- takeout <- rep(F, length(nhd_sub$lines))
while(!all(checked)) {
  i <- which.min(checked)
  theroute <- detectroute(end = nhd_sub$mouth$mouth.seg,
                          start = i,
                          rivers = nhd_sub,
                          stopiferror = FALSE,
                          algorithm = "Dijkstra")
  if(is.na(theroute[1])) {
    takeout[i] <- T
    checked[i] <- T
  }
  else {
    checked[theroute] <- T
  }
}
takeout <- which(takeout)
nhd_sub <- trimriver(rivers = nhd_sub, trim = takeout)

# mapview(nhd_sub$sp)

# outlet <- st_cast(st_line_sample(
#               dplyr::filter(nhd_sub, COMID == "7718342"),
#           sample = 1), "POINT")

nhd_sub_geom <- st_cast(st_sfc(st_multilinestring(nhd_sub$lines)), "LINESTRING")
nhd_sub <- st_sf(nhd_sub$lineID, geom = nhd_sub_geom, crs = crs)

devtools::use_data(nhd_sub, overwrite = TRUE)
