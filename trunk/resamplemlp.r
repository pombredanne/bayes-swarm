resamplemlp <- function ( xu, q, P )
{
# PURPOSE : Performs the resampling stage of the hybrid SIR
#           in order(number of samples) steps.
# INPUTS  : - xu = The networks weights samples.
#           - q = Normalised importance ratios.
#           - P = The weights covariance for each trajectory.
# OUTPUTS : - x = Resampled networks weights samples.
#           - P = Resampledweights covariance for each trajectory.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# TRANSLATED TO R BY : Alessandro Bonazzi
# DATE : 20-08-07

        hold = dim(xu)
        N    = hold[1]
        time = 1 # hold[2]
        numWeights = hold[2] # hold[3]

        u = runif ( N+1) 
        t = -log(u)
        x = array(10,dim=c(N,time,numWeights))
        T = cumsum(t)
        Q = cumsum(q)

# RESAMPLING:
# ==========
       i <- 1
       j <- 1
       Ptmp = P
       while ( j <= N ) {
             if ( Q[j]*T[N] > T[i] ) {
                 x[i,1,] = xu [j,]
                 P[i,,] = Ptmp[j,,]    
                 i = i+1
             } else {
                 j = j+1
             }
       }
       x[N,,]=x[N-1,,]  


       return ( list( x=x, P=P ))
}
   
