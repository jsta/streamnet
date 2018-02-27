#' streamnet.
#'
#' @name streamnet
#' @docType package
NULL

#' nhd_sub_lines
#'
#' @name nhd_sub_lines
#' @docType data
NULL

#' nhd_sub_lakes
#'
#' @name nhd_sub_lakes
#' @docType data
NULL

#' Calculate connectivity metrics
#'
#' @inheritParams closest_lake_distance
#' @export
#'
#' @examples \dontrun{
#'
#' data(nhd_sub_lines)
#' data(nhd_sub_lakes)
#'
#' res <- calc_metrics(nhd_sub_lines, nhd_sub_lakes)
#'
#' }
calc_metrics <- function(lines, lakes, map = FALSE){
  outlet_reach   <- terminal_reaches(network = lines,
                                     approve_all_dl = TRUE)
  outlet_point   <- st_cast(st_line_sample(outlet_reach, sample = 1), "POINT")
  outlet         <- which(outlet_reach$comid == lines$comid)
  nhd_sub_simple <- simplify_network(lines)

  res <- list()

  # avg link_length
  res$avg_link_length       <- avg_link_length(nhd_sub_simple)

  # stream order ratio
  res$stream_order_ratio    <- stream_order_ratio(lines,
                                                  outlet = outlet_point)

  # distance to closest upstream lake
  # number of upsream lakes
  cld <- closest_lake_distance(lines, lakes, outlet = outlet)
  res$closest_lake_distance <- cld$closest_lake_distance
  res$num_up_lakes          <- cld$num_up_lakes

  res
}
