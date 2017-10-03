#' Calculate stream order with GRASS
#'
#' @param lines lines
#' @param outlet outlet
#' @param ... options passed to rgrass7sf::initGRASS
#'
#' @importFrom rgrass7sf initGRASS execGRASS gmeta readVECT writeVECT
#' @export
#'
#' @examples \dontrun{
#' library(nhdR)
#' library(sf)
#' library(dplyr)
#' library(mapview)
#'
#' bbox <- data.frame(xmin = -73.33838, ymin = 41.32841,
#'                    xmax = -73.14540, ymax = 41.66593)
#' b0 <- sf::st_sfc(sf::st_polygon(list(rbind(
#'     c(bbox$xmin, bbox$ymin),
#'     c(bbox$xmax, bbox$ymin),
#'     c(bbox$xmax, bbox$ymax),
#'     c(bbox$xmin, bbox$ymax),
#'     c(bbox$xmin, bbox$ymin)))))
#' sf::st_crs(b0) <- 4326
#' b0 <- st_transform(b0, st_crs(nhdR::vpu_shp))
#'
#' nhd <- nhd_plus_query(poly = b0, dsn = c("NHDWaterbody", "NHDFlowLine"))
#'
#' outlet <- st_cast(st_line_sample(
#'               dplyr::filter(nhd$sp$NHDFlowLine, COMID == "7718342"),
#'           sample = 1), "POINT")
#'
#' res <- stream_order(lines = nhd$sp$NHDFlowLine, outlet = outlet)
#' mapview(res, zcol = "strahler")
#'}
stream_order <- function(lines, outlet, ...){

  rgrass7sf:: initGRASS(gisBase = "/usr/lib/grass72/",
            home = tempdir(),
            override = TRUE)

  rgrass7sf::execGRASS("g.mapset", flags = c("quiet"),
            parameters = list(
              mapset = "PERMANENT"))

  Sys.setenv(GRASS_PROJSHARE = paste(Sys.getenv("GISBASE"),
                                     "\\proj", sep=""))

  proj4 <- st_crs(lines)$proj4string

  rgrass7sf::execGRASS("g.proj", flags = c("c"),
            parameters = list(
              proj4 = proj4
            ))

  rgrass7sf::gmeta()

  lines <- lines[,!duplicated(tolower(names(lines)))]
  # lines <- lines[!(is.na(lines$ToNode) & is.na(lines$FromNode)),]

  rgrass7sf::writeVECT(lines, "testlines"  ,
                       v.in.ogr_flags = c("o", "overwrite"))
  rgrass7sf::writeVECT(outlet, "testoutlet",
                       v.in.ogr_flags = c("o", "overwrite"))

  rgrass7sf::execGRASS("v.stream.order",
            parameters = list(
              input = "testlines",
              points = "testoutlet",
              output = "test"
            ))

  rgrass7sf::readVECT("test")
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
