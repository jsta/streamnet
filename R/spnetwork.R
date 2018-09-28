#' Convert sf lines to SpatialNetwork
#'
#' @param sf_lines sf lines object
#'
#' @importFrom spnetwork SpatialNetwork
#' @importFrom riverdist line2network
#' @importFrom methods as
#'
#' @export
#'
#' @examples \dontrun{
#' data(nhd_sub_lines)
#' res <- sf2network(nhd_sub_lines)
#' plot(res)
#' }
sf2network <- function(sf_lines){
  sp_lines <- as(sf_lines, "Spatial")
  res      <- spnetwork::SpatialNetwork(sp_lines,
                                   direction = rep(1, length(sp_lines)))
  res@g
}



