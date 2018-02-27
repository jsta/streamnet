#' Find the distance to the closest upstream lake
#'
#' @param lines
#' @param lakes
#' @param outlet integer row index of outlet reach relative to lines
#' @param size_threshold
#'
#' @export
#' @examples \dontrun{
#' data(nhd_sub_lines)
#' data(nhd_sub_lakes)
#'
#' outlet_reach   <- terminal_reaches(network = nhd_sub_lines,
#'                                    approve_all_dl = TRUE)
#' outlet <- which(outlet_reach$comid == nhd_sub_lines$comid)
#'
#'
#' closest_lake_distance(nhd_sub_lines, nhd_sub_lakes, outlet = outlet)
#' }
closest_lake_distance <- function(lines, lakes, outlet, size_threshold = 4){

  # filter lakes by size threshold
  lakes <- lakes[st_area(lakes) >
                   units::as_units(size_threshold, "ha"),]

  # extract lakes that intersect lines
  lakes <- lakes[
    which(unlist(lapply(st_intersects(lakes, lines), length)) > 0),]

  # find terminal reach of each lake and terminal reach of focal lake
  t_reaches    <- terminal_reaches(network = lines, lakewise = TRUE)

  t_reach_pnts <- st_line_sample(t_reaches, sample = c(1))
  t_reach_pnts <- st_cast(t_reach_pnts, "POINT")
  outlet_reach_ind <- which(t_reaches$comid ==
                              data.frame(lines)[outlet, "comid"])
  outlet_reach <- t_reach_pnts[outlet_reach_ind]
  t_reach_pnts <- t_reach_pnts[!(seq_len(length(t_reach_pnts)) %in%
                                   outlet_reach_ind)]
  # mapview(t_reach_pnts) + mapview(outlet_reach, color = "red")

  # use GRASS v.net.distance to calculate network distances
  grass_setup(lines)

  rgrass7sf::writeVECT(lines, "testlines"  ,
                       v.in.ogr_flags = c("o", "overwrite"),
                       ignore.stderr = TRUE)

  rgrass7sf::writeVECT(t_reach_pnts, "treachpnts"  ,
                       v.in.ogr_flags = c("o", "overwrite"),
                       ignore.stderr = TRUE)

  rgrass7sf::writeVECT(outlet_reach, "outpnt"  ,
                       v.in.ogr_flags = c("o", "overwrite"),
                       ignore.stderr = TRUE)

  rgrass7sf::execGRASS("v.net",
                       parameters = list(
                         input = "testlines",
                         points = "treachpnts",
                         output = "linesnet",
                         operation = "connect",
                         threshold = 400,
                         arc_layer = "1",
                         node_layer = "2"
                       ),
                       flags = c("quiet", "overwrite"))

  rgrass7sf::execGRASS("v.net",
                       parameters = list(
                         input = "linesnet",
                         points = "outpnt",
                         output = "linesnet2",
                         operation = "connect",
                         threshold = 400,
                         arc_layer = "1",
                         node_layer = "3"
                       ),
                       flags = c("quiet", "overwrite"))

  rgrass7sf::execGRASS("v.category",
                       parameters = list(
                         input = "linesnet2",
                         option = "report"
                       ),
                       flags = c("quiet", "overwrite"))

  rgrass7sf::execGRASS("v.net.distance",
                       parameters = list(
                         input = "linesnet2",
                         output = "dist2out",
                         from_layer = "2",
                         to_layer = "3"
                         ),
                       flags = c("quiet", "overwrite"))


  res <- rgrass7sf::execGRASS("v.report",
                       parameters = list(
                         map = "dist2out",
                         option = "length"
                       ),
                       flags = c("quiet"))

  v.report map=distance_samples_to_pollution@vnettest option=length
  cat|tcat|dist|length

  rgrass7sf::readVECT("dist2out", ignore.stderr = TRUE)

  # find at least 3 catchment lakes within a euclidean buffer (remove focal lake)
  focal_lake <- lakes[order(st_distance(lakes, outlet_point),
                            decreasing = FALSE),][1,]
  lakes      <- lakes[order(st_distance(lakes, focal_lake),
                            decreasing = FALSE),][2:7,]
  # mapview(test) +
  #   mapview(st_buffer(outlet_point, 2)) + mapview(nhd_sub_lines)

  # climb down the network from each catchment lake to the focal lake
  # breakup lines to the path between each catchment lake and the focal lake
  mapview(st_convex_hull(st_union(lakes))) + mapview(nhd_sub_lines)
  network_table


  # calculate dist along each line

  # return shortest

  # Is it a LakeStream?
  lg <- lagosne_load("1.087.1")
  lake_stream <- lg$lakes.geo[
    lg$lakes.geo$lagoslakeid == lagoslakeid,]$lakeconnection
  if(lake_stream != "DR_LakeStream"){
    return(NA)
  }

  lines_clean_sp <- SpatialLinesDataFrame(as_Spatial(st_geometry(lines_clean)),
                                          data = as.data.frame(lines_clean),
                                          match.ID = FALSE)
  lines_clean_rv <- riverdist::line2network(lines_clean_sp, tolerance = 1)

  # Closest distance to a leaf reach - given that we are limiting the
  # analysis to LakeStreams, this is the location of an upstream lake
  browser()
  if(scale == "iws"){
    l_reaches <- nhdR::leaf_reaches(network = lines_clean,
                                    approve_all_dl = TRUE)
    # browser()
  }else{
    # browser()
    t_reaches <- nhdR::terminal_reaches(network = lines_clean,
                                        approve_all_dl = TRUE, lakewise = TRUE)
    t_iws     <- nhdR::terminal_reaches(network = lines_clean,
                                        approve_all_dl = TRUE, lakewise = FALSE)
    l_reaches <- t_reaches[!(t_reaches$comid %in% t_iws$comid),]
  }

  names(l_reaches) <- tolower(names(l_reaches))
  l_reach_segs     <- which(lines_clean$comid %in% l_reaches$comid)

  mouthseg  <- which(lines_clean$comid == outlet_reach$comid)
  distances <- unlist(lapply(l_reach_segs, function(x) riverdistance(mouthseg,
                                                                     x, 1, 1,
                                                                     lines_clean_rv)))

  # mapview(lines_clean) + mapview(l_reaches, color = "red")

  if(map){
    par(mfrow = c(1, 2))
    plot(lines_clean$geom)
    plot(lines_clean$geom[l_reach_segs], add = TRUE, col = "red")
    riverdistance(mouthseg, l_reach_segs[which.min(distances)],
                  1, 1, lines_clean_rv, map = TRUE)
    par(mfrow = c(1, 1))
  }


  list(
    closest_lake_distance = distances[which.min(distances)],
    num_up_lakes = length(l_reach_segs))
}
