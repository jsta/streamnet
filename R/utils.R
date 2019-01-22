#' Convert a raster to stream network
#'
#' @param r raster
#' @param origin index
#'
#' @importFrom raster flip as.matrix
#' @importFrom sf st_polygon st_relate st_linestring
#' @importFrom igraph graph_from_data_frame shortest_paths
#' @importFrom stats setNames
#' @export
#'
#' @examples \dontrun{
#' library(raster)
#'
#' foo <- matrix(0,ncol=9,nrow=9)
#' foo[1:4,3] <- 1
#' foo[5,4] <- 1
#' foo[6:9,5] <- 1
#' foo <- raster(foo)
#' origin <- which.min(apply(
#'              which(as.matrix(flip(foo, "y")) == 1, arr.ind = TRUE), 1, sum))
#' res <- raster2network(foo, origin)
#'
#' mapview::mapview(res)
#' }
raster2network <- function(r, origin){

  st_rook    <- function(a, b = a) st_relate(a, b, pattern = "F***1****")
  st_queen   <- function(a, b = a) st_relate(a, b, pattern = "F***T****")

  boxify     <- function(x){# turn into polygon grid with dt as centerpoints
    # x <- as.numeric(x)
    st_polygon(
      list(
        rbind(x - 0.5,
              c(x[1] + 0.5, x[2] - 0.5),
              x + 0.5,
              c(x[1] - 0.5, x[2] + 0.5),
              x - 0.5)
      )
    )
  }

  to_igraph  <- function(dt_poly){
    res <- unclass(st_queen(dt_poly))
    res <- setNames(res, seq_len(length(res)))
    res <- utils::stack(res)
    names(res) <- c("from", "to")

    graph_from_data_frame(res)
  }

  to_network <- function(dt_ig, dt_origin, dt_pts){
    path_nodes <- lapply(names(V(dt_ig)), function(x) {
      res_paths <- shortest_paths(dt_ig, from = x, to = as.character(dt_origin))
      as.numeric(names(unclass(res_paths$vpath)[[1]]))
    })

    path_lines <- st_sfc(
      lapply(seq_len(length(path_nodes)),
        function(x) st_linestring(st_coordinates(dt_pts[path_nodes[[x]],]))))
    path_lines <- path_lines[which(st_length(path_lines) > 0)]

    st_cast(st_line_merge(st_union(st_cast(path_lines, "MULTILINESTRING"))),
            "LINESTRING")
  }

  dt        <- data.frame(which(raster::as.matrix(flip(r, "y")) == 1, arr.ind = TRUE))
  dt_pts    <- st_as_sf(dt, coords = c("col", "row"))
  dt_poly   <- st_sfc(apply(dt, 1, function(x) boxify(x)))
  dt_ig     <- to_igraph(dt_poly)

  to_network(dt_ig, origin, dt_pts)
}

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

  lines_sp <- SpatialLinesDataFrame(as_Spatial(sf::st_geometry(lines)),
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

install_grass_extensions <- function(){
  tryCatch(rgrass7sf::initGRASS(gisBase = grass_path(),
                                home = tempdir(),
                                override = TRUE),
           error = function(e) NULL)

  rgrass7sf::execGRASS("g.extension",
                       parameters = list(
                         extension = "v.stream.order",
                         operation = "add"))
}
