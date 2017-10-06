#
# library(igraph)
# library(sp)
# library(mapview)
# data(nhd_sub)
# res <- sf2network(nhd_sub)
# plot(res)

#' Convert sf to SpatialNetwork
#'
#' @importFrom spnetwork SpatialNetwork
#' @importFrom riverdist line2network
#' @export
sf2network <- function(sf_lines){
  sp_lines <- as(sf_lines, "Spatial")
  res <- spnetwork::SpatialNetwork(sp_lines, direction = rep(1, length(sp_lines)))
  # res <- spnetwork::SpatialNetwork(sp_lines)

  browser()
  path <- get.shortest.paths(res@g, 134, 2, output = "both")
  sp <- as.vector(path$vpath[[1]])
  ids <- as_ids(path$epath[[1]])

  plot(res, col = "grey")
  sel <- sp_lines[ids,]
  lines(sel, col = "red", lwd = 2)


  browser()

  rvnet    <- riverdist::line2network(sp_lines, tolerance = 1)
  rvnet_sf <- rvnet2sf(rvnet)

  mapview(rvnet_sf, zcol = "rivID")

  any(unlist(lapply(rvnet$lines, function(x) x[1] > x[length(x)])))

  rvnet$connections[2,3]
  rvnet$connections[3,2]

  apply(rvnet$connections, 1, unique)

  res@g
}



