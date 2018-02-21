#' Retrieve stream network draining to a given lake
#'
#' @param wb_coords numeric vector of length 2: lat, lon
#' @param dset character dataset identifier: nhdh, nhdplusv2
#'
#' @importFrom hydrolinks link_to_waterbodies get_shape_by_id traverse_flowlines
#' @importFrom sf st_geometry
#' @importFrom purrr when
#' @export
#' @examples \dontrun{
#' wb_coords <- c(44.00467, -88.43445)
#' res <- hlk_traverse(wb_coords)
#' }

hlk_traverse <- function(wb_coords, dset = "nhdh"){
  wb_id <- link_to_waterbodies(wb_coords[1], wb_coords[2],
                               1, dataset = dset)
  wb_id <- purrr::when(wb_id, any(names(.) %in% "COMID")
                ~ .$COMID,
                ~.$PERMANENT_)

  nhd_wb <- get_shape_by_id(wb_id, feature_type = "waterbody", dataset = dset)

  f_lines <- traverse_flowlines(max_distance = Inf, direction = "in",
                                start = wb_id,
                                dataset = dset, md5check = FALSE)
  f_lines <- purrr::when(f_lines, any(names(.) %in% "COMID")
                ~ .$COMID,
                ~.$PERMANENT_)

  upstream_shp <- get_shape_by_id(f_lines, dataset = dset,
                                  feature_type = "flowline")

  list(nhd_wb = nhd_wb, upstream_shp = upstream_shp)
}
