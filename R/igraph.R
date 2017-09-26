sf2igraph <- function(sf_lines){


}

#' Convert an igraph object to sf
#'
#' @param ig_network igraph network
#'
#' @importFrom sf st_as_sf
#' @export
#' @examples
#' tree <- create_reversed_tree(9)
#' tree_sf <- igraph2sf(tree)
igraph2sf <- function(ig_network){
  # ig_network <- tree

  res <- data.frame(igraph::layout_as_tree(ig_network, mode = "in"))
  names(res) <- c("x", "y")
  res[,1:2] <- apply(res[,1:2] * 10 + abs(min(res[,1:2])) * 10, 2, as.integer)
  res$name <- igraph::V(ig_network)$name

  edge_matrix <- as_data_frame(ig_network, what = "edges")

  # lapply(t(edge_matrix), function(x) {
  #   rbind(,
  #         res[res$name == x[2], c("x", "y")])
  # })

  ordered_vertices <- lapply(t(edge_matrix),
                        function(x) res[res$name %in% x, c("x", "y")])
  by_twos <- cbind(
    seq(1, length(ordered_vertices), by = 2),
    seq(2, length(ordered_vertices), by = 2))

  # mls <- st_sfc(
    mls <- st_multilinestring(
    apply(by_twos, 1, function(x) rbind(ordered_vertices[[x[1]]],
                                        ordered_vertices[[x[2]]])))
    # )

  mls

  (plot(st_multilinestring(list(rbind(c(10,40),c(20,50)), rbind(c(30,40),c(20,50))))))
  # res <- sf::st_as_sf(res, coords = c("x", "y"))
  # res
}



