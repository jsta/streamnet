#' sim_dla
#'
#' @export
#' @importFrom stats runif
#' @examples \dontrun{
#' raster::image(sim_dla())
#' }
sim_dla <- function(){
  res  <- list()
  max  <- 40000      # /* number of iterations  */
  size <- 401        # /* size of grid array  */
  seed <- 68111			 # /* seed for number generator */
  rad  <- 180
  old  <- 0
  mem  <- NULL

  gauss_ran <- function(){
    calc_rr <- function(){
      r1 <- 2.0 * runif(1) - 1.0  #    /* choose random point in */
      r2 <- 2.0 * runif(1) - 1.0	#     /* the unit circle */
      rr <- r1 * r1 + r2 * r2

      list(r1 = r1, r2 = r2, rr = rr)
    }

    if(old == 0){
      rr <- calc_rr()
      r1 <- rr$r1
      r2 <- rr$r2
      rr <- rr$rr
      while((rr >= 1) | (rr == 0)){
        rr <- calc_rr()
        r1 <- rr$r1
        r2 <- rr$r2
        rr <- rr$rr
      }

      fac <- sqrt(-2 * log(rr) / rr)
      mem <<- 5000 * r1 * fac # /* save for next call */
      old <<- 1               # /* set flag */

      return(as.integer(5000 * r2 * fac))
    }else{
      old <<- 0
      return(mem)
    }
  }

  # hist(sapply(1:4000, function(x) gauss_ran()))

  grid <- matrix(0, nrow = length(0:(size - 1)), ncol = length(0:(size - 1)))
  grid[200, 200] <- 1	 #		/* one particle at the center */
  # set.seed(seed)

  for(i in 0:(max - 1)){
    # i <- 0
    hit   <- 0
    angle <- (2 * pi * runif(1))                #	random angle */
    x     <- as.integer(200 + rad * cos(angle)) # coordinates */
    y     <- as.integer(200 + rad * sin(angle))

    dist  <- gauss_ran()                        # random number gaussian dist. */

    if(dist < 0){
      step <- -1
    }else{
      step <- 1
    }

    trav <- 0
    while(hit == 0 && x < 399 &&
          x > 1 && y < 399 && y > 1 && trav < abs(dist)){
      if(grid[x + 1, y] +
         grid[x - 1,y] +
         grid[x, y + 1] +
         grid[x, y - 1] >= 1){
          hit <- 1        #    /* one neighbor is occupied */
          grid[x,y] <- 1  #    /* particle sticks, walk is over */
      }else{
        if(runif(1) < 0.5){
          x <- x + step #      /* move horizontally */
        }else{
          y <- y + step  #      /* move vertically */
        }
      }

      trav <- trav + 1
    }
  }

  min_grid <- min(
    range(which(colSums(grid) > 0))[1],
    range(which(rowSums(grid) > 0))[1])
  max_grid <- max(
    range(which(colSums(grid) > 0))[2],
    range(which(rowSums(grid) > 0))[2])

  grid[min_grid:max_grid, min_grid:max_grid]
}

#' Vizualize the dla simulation
#'
#' @param r raster made from output of sim_dla
#' @param origin integer index of network origin
#'
#' @importFrom raster raster t
#' @export
#'
#' @examples \dontrun{
#' dt <- sim_dla()
#' viz_dla(raster(dt), which.max(dt))
#' image(dt)
#' }
viz_dla <- function(r, origin){
  r   <- flip(raster::t(raster::raster(r)), "y")
  res <- raster2network(r, origin)

  # plot(res)
  mapview::mapview(res)
}
