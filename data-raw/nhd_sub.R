library(nhdR)
library(sf)
library(concaveman)

coords <- c(lon = -73.17581, lat = 41.38634)
poly   <- nhd_plus_query(coords[1], coords[2], dsn = "NHDWaterbody",
                         buffer_dist = 0.01)$sp$NHDWaterbody

nhd_sub_lines      <- extract_network(coords[1], coords[2],
                                 buffer_dist = 0.02, maxsteps = Inf)

nhd_line_to_points <- st_sf(st_cast(st_union(nhd_sub_lines), "POINT"))
nhd_sub_catchment  <- concaveman::concaveman(nhd_line_to_points)$polygons

nhd_sub_lakes      <- nhd_plus_query(poly = nhd_sub_catchment,
                                     dsn = "NHDWaterbody")$sp$NHDWaterbody

# mapview(nhd_sub_catchment) + mapview(nhd_sub_lakes) + mapview(nhd_sub_lines)

devtools::use_data(nhd_sub_lines, overwrite = TRUE)
devtools::use_data(nhd_sub_lakes, overwrite = TRUE)
# devtools::use_data(nhd_sub_rv, overwrite = TRUE)
