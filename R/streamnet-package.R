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
#' @details If nhdR::terminal reaches returns a zero length object, this function will return all NA
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
#' coords <- c(lon = -73.17581, lat = 41.38634)
#'
#' res <- calc_metrics(nhd_sub_lines, nhd_sub_lakes)
#'
#' # don't error if lines is only one row
#' calc_metrics(nhd_sub_lines[1,], nhd_sub_lakes)
#'
# lines <- readRDS("/home/jose/Documents/Science/Dissertation/Analysis/lines.rds")
# lakes <- readRDS("/home/jose/Documents/Science/Dissertation/Analysis/lakes.rds")
# calc_metrics(lines, lakes)
#'
#' }
calc_metrics <- function(lines, lakes, map = FALSE){
  res <- list()

  outlet_reach   <- terminal_reaches(network = lines,
                                     approve_all_dl = TRUE, quiet = TRUE)

  if(nrow(outlet_reach) > 0){
    outlet_reach <- outlet_reach[1,]
    outlet_point   <- st_cast(st_line_sample(outlet_reach, sample = 1), "POINT")

    outlet         <- which(outlet_reach$comid == lines$comid)
    nhd_sub_simple <- simplify_network(lines)

    # avg link_length
    res$avg_link_length       <- avg_link_length(nhd_sub_simple)

    # stream order ratio
    if(nrow(lines) > 1){
      res$stream_order_ratio  <- stream_order_ratio(lines,
                                                    outlet = outlet_point)
    }else{
      res$stream_order_ratio <- 1
    }

    # distance to closest upstream lake
    # number of upsream lakes
    # area of upstream lakes
    if(nrow(lines) > 1){
      cld <- closest_lake_distance(lines, lakes, outlet = outlet)
      res$closest_lake_distance <- cld$closest_lake_distance
      res$num_up_lakes          <- cld$num_up_lakes
      res$lake_area             <- cld$lake_area
    }else{
      res$closest_lake_distance <-
        res$num_up_lakes <-
        res$lake_area <- NA
    }
  }else{
    res$closest_lake_distance <-
      res$num_up_lakes <-
      res$lake_area <-
      res$stream_order_ratio <-
      res$avg_link_length <- NA
  }

  res
}
