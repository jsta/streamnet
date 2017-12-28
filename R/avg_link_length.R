#' Calculate average link length of stream network
#'
#' @param lines sf linestring collection
#'
#' @export
#' @importFrom riverdist line2network
avg_link_length <- function(lines){

  lines_rv <- riverdist::line2network(as(lines, "Spatial"), tolerance = 1)
  lines    <- streamnet::rvnet2sf(lines_rv, crs = sf::st_crs(lines))
  # mapview(lines, zcol = "rivID")
  lines_clean <- suppressMessages(autoclean(lines_rv,
                                            mouthseg,
                                            mouthvert,
                                            st_crs(lines)))
  # mapview(lines_clean)
  lines_ig <- streamnet::sf2igraph(lines_clean)
  # plot(lines_ig$tree)

  igraph::average.path.length(lines_ig$tree)
}
