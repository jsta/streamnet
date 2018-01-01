#' Calculate average link length of stream network
#'
#' @param lines sf linestring collection
#'
#' @export
#' @importFrom riverdist line2network
#' @importFrom sf st_crs st_cast st_sfc st_length
avg_link_length <- function(lines, outlet_reach){

  mouthseg  <- which(lines$COMID == outlet_reach$comid)
  mouthvert <- 1

  lines_rv <- riverdist::line2network(as(lines, "Spatial"), tolerance = 1)
  lines_sf <- streamnet::rvnet2sf(lines_rv, crs = sf::st_crs(lines))

  lines_clean <- suppressMessages(autoclean(lines_rv,
                                            mouthseg,
                                            mouthvert,
                                            st_crs(lines)))
  # mapview(lines_clean)
  lines_explode <- st_cast(st_sfc(lines_clean$geom), "LINESTRING")
  mean(st_length(lines_explode))
}
