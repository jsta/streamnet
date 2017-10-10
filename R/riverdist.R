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


#' Automatically clean a rivernetwork object
#'
#' @param rivernetwork rivernetwork object from the riverdist package
#' @param mouthseg integer
#' @param mouthvert integer
#' @param crs crs string or epsg code
#'
#' @importFrom riverdist removeduplicates dissolve removemicrosegs setmouth trimriver detectroute
#' @export
autoclean <- function(rivernetwork, mouthseg, mouthvert, crs){
  rivernetwork <- riverdist::removeduplicates(rivers = rivernetwork)
  rivernetwork <- riverdist::dissolve(rivernetwork)
  rivernetwork <- removemicrosegs(rivernetwork)

  rivernetwork <- setmouth(seg = mouthseg,
                           vert = mouthvert,
                           rivers = rivernetwork)

  # sequence taken from riverdist::clean ####
  checked <- takeout <- rep(F, length(rivernetwork$lines))
  while(!all(checked)) {
    i <- which.min(checked)
    theroute <- detectroute(end = rivernetwork$mouth$mouth.seg,
                            start = i,
                            rivers = rivernetwork,
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
  rivernetwork <- trimriver(rivers = rivernetwork, trim = takeout)
  rivernetwork_geom <- st_cast(st_sfc(st_multilinestring(rivernetwork$lines)), "LINESTRING")
  st_sf(rivernetwork$lineID, geom = rivernetwork_geom, crs = crs)
  # st_as_sf(rivernetwork)
}
