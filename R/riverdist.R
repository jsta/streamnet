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
#' library(nhdR)
#' library(sf)
#'
#' # Generate test dataset
#' bbox <- data.frame(xmin = -73.33838, ymin = 41.35841,
#' xmax = -73.14540, ymax = 41.48593)
#' b0 <- sf::st_sfc(sf::st_polygon(list(rbind(
#'   c(bbox$xmin, bbox$ymin),
#'   c(bbox$xmax, bbox$ymin),
#'   c(bbox$xmax, bbox$ymax),
#'   c(bbox$xmin, bbox$ymax),
#'   c(bbox$xmin, bbox$ymin)))))
#' sf::st_crs(b0) <- 4326
#' b0 <- st_transform(b0, sf::st_crs(nhdR::vpu_shp))
#'
#' outlet_reach <- terminal_reaches(
#'   lon = st_coordinates(st_centroid(b0))[1],
#'   lat = st_coordinates(st_centroid(b0))[2],
#'   approve_all_dl = TRUE)
#' outlet_point <- st_cast(st_line_sample(outlet_reach, sample = 1), "POINT")
#'
#' nhd <- nhd_plus_query(poly = b0, dsn = c("NHDFlowLine"))$sp$NHDFlowLine
#' mouthseg  <- which(nhd$COMID == outlet_reach$comid)
#  mouthvert <- 1
#  nhd_rv <- riverdist::line2network(as(nhd, "Spatial"), tolerance = 1)
#' res <- autoclean(nhd_rv, mouthseg, mouthvert, crs = st_crs(nhd))
#' }
autoclean <- function(rivernetwork, mouthseg, mouthvert, crs, dissolve = FALSE){
  rivernetwork <- riverdist::removeduplicates(rivers = rivernetwork)

  if(dissolve){
    rivernetwork <- riverdist::dissolve(rivernetwork)
  }

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

  rivernetwork_geom <- st_cast(st_sfc(st_multilinestring(rivernetwork$lines)),
                               "LINESTRING")
  st_sf(cbind(rivernetwork$lineID, rivernetwork$sp@data),
        geom = rivernetwork_geom, crs = crs)
  # st_as_sf(rivernetwork)
}
