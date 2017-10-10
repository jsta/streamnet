#' Rivernetwork to sf object
#'
#' @param rvnet rivernetwork object from the riverdist package
#' @param crs crs string or epsg code
#'
#' @importFrom sf st_multilinestring st_sfc st_cast st_sf
#'
#' @export
rvnet2sf <- function(rvnet, crs){
  res_geom <- st_cast(st_sfc(st_multilinestring(rvnet$lines)), "LINESTRING")
  st_sf(rvnet$lineID, geom = res_geom, crs = crs)
}
