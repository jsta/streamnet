#' Convert sf lines to an igraph object
#'
#' @param sf_lines
#'
#' @importFrom sf st_sfc st_cast st_length st_line_sample
#' st_coordinates st_distance
#' @importFrom igraph E graph_from_edgelist "E<-"
#' @export
#'
#' @examples
#' tree    <- create_reversed_tree(15)
#' tree_sf <- igraph2sf(tree)
#' tree    <- sf2igraph(tree_sf, tolerance = 1)
#' plot(tree$tree,
#'      edge.width = tree$weights,
#'      layout = igraph::layout_as_tree(tree$tree, mode = "in"))
sf2igraph <- function(sf_lines, tolerance = 1){

  sf_lines_split <- st_cast(st_sfc(sf_lines), "LINESTRING")

  sf_lines_be <- lapply(sf_lines_split, function(x)
    st_cast(st_line_sample(x, sample = c(0, 1)), "POINT"))

  sf_lines_starts <- do.call(rbind,
                             lapply(sf_lines_be, function(x)
                               st_coordinates(x[1])))
  sf_lines_ends   <- do.call(rbind,
                           lapply(sf_lines_be, function(x)
                             st_coordinates(x[2])))

  sf_lines_starts <- suppressWarnings(st_as_sf(data.frame(sf_lines_starts),
                              coords = c("X", "Y")))
  sf_lines_ends   <- suppressWarnings(st_as_sf(data.frame(sf_lines_ends),
                              coords = c("X", "Y")))

  # look for ends that are close to starts
  dist_mat_raw   <- st_distance(sf_lines_starts, sf_lines_ends)
  dist_mat       <- which(dist_mat_raw < tolerance, arr.ind = TRUE)[,c(2, 1)]
  terminal_edges <- which(colSums(dist_mat_raw > 1) == ncol(dist_mat_raw))
  dist_mat       <- rbind(
    t(sapply(terminal_edges,
             function(x) cbind(x, ncol(dist_mat_raw) + 1))), dist_mat)

  # test <- st_sf(st_sfc(sf_lines_split))
  # test$id <- factor(1:nrow(test))
  # ggplot() + geom_sf(data = test, aes(color = id))

  weights <- suppressWarnings(sf::st_length(sf_lines_split))
  tree <- igraph::graph_from_edgelist(dist_mat, directed = TRUE)
  E(tree)$weight <- weights

  list(tree = tree, weights = weights)
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
