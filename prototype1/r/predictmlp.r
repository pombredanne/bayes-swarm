predictmlp <- function (x,Q)
{
# PURPOSE : Performs the prediction step of the hybrid SIR
#           algorithm.
# INPUTS  : - x = The current network weights samples.
#           - Q = Process noise variance parameter.
# OUTPUTS : - xu = Predicted network weights samples.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRASLATED TO R BY : Alessandro Bonazzi
# DATE    : 14-08-07

         xu = x + sqrt(Q)*rnorm(length(x))
         return(xu)

}
