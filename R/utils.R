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

check_grass <- function(){
  file.exists(grass_path())
}

grass_path <- function(){
  flist <- list.files("/usr/lib", pattern = "^grass\\d{2}")
  flist <- flist[which.max(as.numeric(gsub("[^0-9]", "", flist)))]
  file.path("/usr/lib", flist)
}

grass_setup <- function(lines, ...){

  lines_sp <- SpatialLinesDataFrame(as_Spatial(st_geometry(lines)),
                                    data = as.data.frame(lines),
                                    match.ID = FALSE)

  lines_r <- as(raster::raster(
    raster::extent(sp::SpatialLines(lines_sp@lines))), "SpatialGrid")

  rgrass7sf::initGRASS(gisBase = grass_path(),
                       home = tempdir(),
                       override = TRUE,
                       SG = lines_r)

  rgrass7sf::execGRASS("g.mapset", flags = c("quiet"),
                       parameters = list(
                         mapset = "PERMANENT"))

  Sys.setenv(GRASS_PROJSHARE = paste(Sys.getenv("GISBASE"),
                                     "\\proj", sep=""))

  proj4 <- sf::st_crs(lines)$proj4string

  rgrass7sf::execGRASS("g.proj", flags = c("c", "quiet"),
                       parameters = list(
                         proj4 = proj4
                       ))

  rgrass7sf::gmeta(ignore.stderr = TRUE)

}
