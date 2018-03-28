#include <Rcpp.h>
using namespace Rcpp;

// This is a simple example of exporting a C++ function to R. You can
// source this function into an R session using the Rcpp::sourceCpp
// function (or via the Source button on the editor toolbar).

//' gauss_ran
//'
//' @export
// [[Rcpp::export]]
NumericVector gauss_ran() {
  return runif(1); // equivalent to drand48
}




// You can include R code blocks in C++ files processed with sourceCpp
// (useful for testing and development). The R code will be automatically
// run after the compilation.
//

/*** R
gauss_ran()
*/
