#' Calculate stream order with GRASS
#'
#' @param lines lines
#' @param outlet outlet
#' @param ... options passed to rgrass7sf::initGRASS
#'
#' @importFrom rgrass7sf initGRASS execGRASS gmeta readVECT writeVECT
#' @importFrom sf st_crs
#' @importFrom raster raster extent
#' @importFrom sp SpatialLines
#' @export
#'
#' @examples \dontrun{
#' library(mapview)
#'
#' data(nhd_sub)
#'
#' outlet <- st_cast(st_line_sample(
#'               dplyr::filter(nhd_sub, COMID == "7718342"),
#'           sample = 1), "POINT")
#'
#' res <- stream_order(lines = nhd_sub, outlet = outlet)
#' mapview(res, zcol = "strahler")
#'}
stream_order <- function(lines, outlet, ...){

  lines_sp <- SpatialLinesDataFrame(as_Spatial(st_sfc(lines$geometry)),
                                    data = as.data.frame(lines),
                                    match.ID = FALSE)
  lines_r <- as(raster::raster(raster::extent(sp::SpatialLines(lines_sp@lines))), "SpatialGrid")

  rgrass7sf:: initGRASS(gisBase = "/usr/lib/grass72/",
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

  lines <- lines[,!duplicated(tolower(names(lines)))]
  # lines <- lines[!(is.na(lines$ToNode) & is.na(lines$FromNode)),]

  rgrass7sf::writeVECT(lines, "testlines"  ,
                       v.in.ogr_flags = c("o", "overwrite"),
                       ignore.stderr = TRUE)
  rgrass7sf::writeVECT(outlet, "testoutlet",
                       v.in.ogr_flags = c("o", "overwrite"),
                       ignore.stderr = TRUE)

  rgrass7sf::execGRASS("v.stream.order",
            parameters = list(
              input = "testlines",
              points = "testoutlet",
              output = "test"
            ),
            flags = c("quiet"))

  rgrass7sf::readVECT("test", ignore.stderr = TRUE)
}

#' Calculate stream order with igraph
#'
#' @description This function is experimental. The equivalent GRASS
#' function should be used in most cases.
#' @param tree igraph tree object
#'
#' @importFrom igraph degree as_edgelist delete.vertices vcount E V
#' @export
#'
#' @examples \dontrun{
#' tree <- create_reversed_tree(15)
#' igraph::E(tree)$weight <- stream_order_igraph(tree)
#' plot(tree, edge.width = igraph::E(tree)$weight,
#'          layout = layout_as_tree(tree, mode = "in"))
#' }
stream_order_igraph <- function(tree){
  base_order <- 1
  leaf_nodes <- names(which(degree(tree,
                                   v = igraph::V(tree),
                                   mode = "in") == 0,
                            useNames = TRUE))
  edgelist   <- data.frame(as_edgelist(tree))
  edgelist$order <- NA
  names(edgelist)[c(1,2)] <- c("from", "to")
  edgelist$order[edgelist$from %in% leaf_nodes] <- base_order

  tree <- igraph::delete.vertices(tree, leaf_nodes)

  while(igraph::vcount(tree) >= 1){
    base_order <- max(edgelist$order, na.rm = TRUE) + 1
    leaf_nodes <- names(which(degree(tree, v = igraph::V(tree),
                                     mode = "in") == 0,
                              useNames = TRUE))

    raised_nodes <- sapply(leaf_nodes,
          function(x) all(edgelist$order[edgelist$to == x] == base_order - 1))
    raised_nodes <- names(which(raised_nodes))
    flat_nodes <- leaf_nodes[!(leaf_nodes %in% raised_nodes)]

    edgelist$order[edgelist$from %in% raised_nodes] <- base_order
    edgelist$order[edgelist$from %in% flat_nodes] <- base_order - 1

    tree <- igraph::delete.vertices(tree, leaf_nodes)

  }
  edgelist$order
}
