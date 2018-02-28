#' Calculate average link length of stream network
#'
#' @param lines sf linestring collection
#' @param simplify logical run simplify_network prior to calculations?
#'
#' @export
#' @importFrom sf st_crs st_cast st_sfc st_length
#' @examples \dontrun{
#' data(nhd_sub)
#' avg_link_length(nhd_sub)
#' }
avg_link_length <- function(lines, simplify = FALSE){
  if(simplify){
    lines <- simplify_network(lines)
  }
  mean(st_length(lines))
}

#' Simplify network
#'
#' Combine(dissolve) adjacent reaches with no junctions
#'
#' @param lines sf data.frame composed of LINESTRING objects
#'
#' @export
#' @importFrom sf st_union st_line_merge
#' @examples \dontrun{
#' data(nhd_sub_lines)
#' res <- simplify_network(nhd_sub_lines)
#'
#' # single line returns the original
#' res <- simplify_network(nhd_sub_lines[1,])
#'
#' }
simplify_network <- function(lines){
  if(nrow(lines) > 1){
    st_cast(st_line_merge(
      st_union(st_cast(lines, "MULTILINESTRING"))), "LINESTRING")
  }else{
    lines
  }
}
