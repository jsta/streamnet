#' Convert sf lines to an igraph object
#'
#' @param sf_lines
#'
#' @export
#'
#' @examples
#' tree <- create_reversed_tree(15)
#' tree_sf <- igraph2sf(tree)
#' tree <- sf2igraph(tree_sf)
sf2igraph <- function(sf_lines){

  test <- graph_from_edgelist(cbind(1:10, c(2:10, 1)))

  browser()
  igraph::graph_from_edgelist()

}

#' Convert an igraph object to sf lines
#'
#' @param ig_network igraph network
#'
#' @importFrom sf st_as_sf st_multilinestring
#' @importFrom igraph as_data_frame
#' @export
#' @examples
#' tree <- create_reversed_tree(15)
#' tree_sf <- igraph2sf(tree)
#' plot(tree_sf)
igraph2sf <- function(ig_network){
  res <- data.frame(igraph::layout_as_tree(ig_network, mode = "in"))
  names(res) <- c("x", "y")
  res[,1:2] <- apply(res[,1:2] * 10 + abs(min(res[,1:2])) * 10, 2, as.integer)
  res$name <- igraph::V(ig_network)$name

  edge_matrix <- igraph::as_data_frame(ig_network, what = "edges")
  ordered_vertices <- lapply(t(edge_matrix),
                    function(x) res[res$name %in% x, c("x", "y")])

  by_twos <- cbind(
    seq(1, length(ordered_vertices), by = 2),
    seq(2, length(ordered_vertices), by = 2))

  mls <- lapply(1:nrow(by_twos),
                function(x) as.matrix(rbind(
                  ordered_vertices[[by_twos[x,][1]]],
                  ordered_vertices[[by_twos[x,][2]]])))

  sf::st_multilinestring(mls)
}



