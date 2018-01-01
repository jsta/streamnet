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
#' @importFrom riverdist removeduplicates dissolve removemicrosegs setmouth trimriver detectroute riverdirection
#' @export
#' @examples \dontrun{
#' mouthseg  <- which(nhd$COMID == outlet_reach$comid)
#  mouthvert <- 1
#  nhd_rv <- riverdist::line2network(as(nhd, "Spatial"), tolerance = 1)
#' res <- autoclean(nhd_rv, mouthseg, mouthvert, crs = st_crs(nhd))
#' }
autoclean <- function(rivernetwork, mouthseg, mouthvert, crs){

  rivernetwork <- riverdist::removeduplicates(rivers = rivernetwork)
  rivernetwork <- riverdist::dissolve(rivernetwork)
  rivernetwork <- removemicrosegs(rivernetwork)

  rivernetwork <- setmouth(seg = mouthseg,
                           vert = mouthvert,
                           rivers = rivernetwork)

  # sequence taken from riverdist::clean ####
  checked <- takeout <- below_mouth <- rep(F, length(rivernetwork$lines))
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

  # remove segments downstream of mouth ####
  # checked <- below_mouth <- rep(F, length(rivernetwork$lines))
  #
  # while(!all(checked)) {
  #   i <- which.min(checked)
  #   (check_upstream <- riverdist::riverdirection(startseg = rivernetwork$mouth$mouth.seg,
  #                                  startvert = rivernetwork$mouth$mouth.vert,
  #                                  endseg = i,
  #                                  endvert = 1,
  #                                  rivers = rivernetwork))
  #   print(check_upstream)
  #
  #   if(check_upstream == "down"){
  #     below_mouth[i] <- TRUE
  #   }
  #   checked[i] <- TRUE
  # }
  #
  # below_mouth  <- which(below_mouth)
  # rivernetwork <- trimriver(rivers = rivernetwork, trim = below_mouth)

  rivernetwork_geom <- st_cast(st_sfc(st_multilinestring(rivernetwork$lines)), "LINESTRING")
  st_sf(rivernetwork$lineID, geom = rivernetwork_geom, crs = crs)
  # st_as_sf(rivernetwork)
}
