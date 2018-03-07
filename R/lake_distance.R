#' Find the distance to the closest upstream lake, the number of upstream lakes, and the area of upstream lakes
#'
#' @param lines sf lines object
#' @param lakes sf polygon object
#' @param outlet integer row index of outlet reach relative to lines
#' @param size_threshold numeric size above which to consider as a lake
#' @param map logical show a map output of the results?
#'
#' @importFrom utils read.csv capture.output
#' @importFrom graphics plot
#' @importFrom sf st_area st_intersects st_transform
#' @importFrom nhdR terminal_reaches
#' @export
#' @examples \dontrun{
#' library(nhdR)
#'
#' data(nhd_sub_lines)
#' data(nhd_sub_lakes)
#'
#' outlet_reach   <- terminal_reaches(network = nhd_sub_lines,
#'                                    approve_all_dl = TRUE)
#' outlet <- which(outlet_reach[['comid']] == nhd_sub_lines[['comid']])
#'
#' closest_lake_distance(nhd_sub_lines, nhd_sub_lakes, outlet = outlet)
#' }
closest_lake_distance <- function(lines, lakes, outlet, size_threshold = 4,
                                  map = FALSE){

  # filter lakes by size threshold
  lakes     <- lakes[st_area(lakes) >
                   units::as_units(size_threshold, "ha"),]
  lakes     <- st_transform(lakes, st_crs(lines))
  lake_area <- sum(st_area(lakes))
  units(lake_area) <- "ha"

  # extract lakes that intersect lines
  lakes <- lakes[
    which(unlist(lapply(st_intersects(lakes, lines), length)) > 0),]

  # find terminal reach of each lake and terminal reach of focal lake
  t_reaches    <- terminal_reaches(network = lines, lakewise = TRUE, quiet = TRUE)

  t_reach_pnts <- st_line_sample(t_reaches, sample = c(1))
  t_reach_pnts <- st_cast(t_reach_pnts, "POINT")

  outlet_reach_ind <- which(t_reaches[["comid"]] ==
                              lines[["comid"]][outlet])

  if(length(t_reach_pnts) > 1){
    if(length(outlet_reach_ind) > 0){
      outlet_reach <- t_reach_pnts[outlet_reach_ind]
      t_reach_pnts <- t_reach_pnts[!(seq_len(length(t_reach_pnts)) %in%
                                       outlet_reach_ind)]
    }else{ #probably a one-off error
      outlet_reach   <- terminal_reaches(network = lines,
                                         approve_all_dl = TRUE, quiet = TRUE)

      outlet_reach <- t_reach_pnts[
        which.min(apply(st_distance(outlet_reach, t_reach_pnts), 2, min))]

      t_reach_pnts <- t_reach_pnts[
        !(seq_len(length(t_reach_pnts)) %in%
        which.min(st_distance(outlet_reach, t_reach_pnts)))]
    }

    # library(mapview)
    # mapview(t_reach_pnts) + mapview(outlet_reach, color = "red")

    # use GRASS v.net.distance to calculate network distances
    grass_setup(lines)

    capture.output(rgrass7sf::writeVECT(lines, "testlines",
                         v.in.ogr_flags = c("o", "overwrite"),
                         ignore.stderr = TRUE), file = tempfile())

    rgrass7sf::writeVECT(t_reach_pnts, "treachpnts",
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

    # rgrass7sf::execGRASS("v.category",
    #                      parameters = list(
    #                        input = "linesnet2",
    #                        option = "report"
    #                      ),
    #                      flags = c("quiet", "overwrite"))

    rgrass7sf::execGRASS("v.net.distance",
                         parameters = list(
                           input = "linesnet2",
                           output = "dist2out",
                           from_layer = "2",
                           to_layer = "3"
                           ),
                         flags = c("quiet", "overwrite"))

    capture.output(res <- rgrass7sf::execGRASS("v.report",
                         parameters = list(
                           map = "dist2out",
                           option = "length"
                         ),
                         flags = c("quiet"), echoCmd = FALSE), file = tempfile())

    res <- read.csv(textConnection(attr(res, "resOut")), sep = "|")

    if(map){
      plot(st_sf(data.frame(dist = res$dist),
                    st_sfc(st_geometry(t_reach_pnts))))
    }

    list(
      closest_lake_distance = min(res$dist),
      num_up_lakes          = length(t_reach_pnts),
      lake_area             = lake_area)
  }else{
    list(
      closest_lake_distance = NA,
      num_up_lakes          = NA,
      lake_area             = NA)
  }
}
