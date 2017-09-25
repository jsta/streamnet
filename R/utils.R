#' Create a reversed tree igraph object
#'
#' @param node_n number of nodes
#'
#' @importFrom igraph make_tree graph_from_edgelist V E get.edges
#' @export
#'
#' @examples
#' tree <- create_reversed_tree(11)
#' plot(tree, layout = igraph::layout_as_tree(tree, mode = "in"))
create_reversed_tree <- function(node_n){
  tree2         <- igraph::make_tree(node_n, 2)
  edges         <- igraph::get.edges(tree2, igraph::E(tree2))
  rev_edges     <- edges[, c(2, 1)]

  tree2         <- igraph::graph_from_edgelist(rev_edges)
  igraph::V(tree2)$name <- letters[1:node_n]

  return(tree2)
}
