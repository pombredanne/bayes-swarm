gradupdate <- function(xu,input,y,s1,s2,P,KalmanR,KalmanQ)
{
# PURPOSE : Updates each of the sample trajectories using and extended
#           Kalman filter.
# INPUTS  : - xu = The networks weights samples.
#           - input = The network input.
#           - y = The network output.
#           - P = The weights covariance for each trajectory.
#           - s1 = Number of neurons in the hidden layer.
#           - s2 = Number of neurons in the output layer (1).
#           - KalmanR = EKF measurement noise hyperparameter.
#           - KalmanQ = EKF process noise hyperparameter.
# OUTPUTS : - x = The updated weights samples.
#           - P = The updated weights covariance for each trajectory.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRANSLATED TO R BY : Alessandro Bonazzi
# DATE    : 20-08-07
      source("mlph.r")
      hold       = dim(xu)
      N          = hold[1]
      time       = 1 #hold[2]
      numWeights = hold[2] # hold[3]

      x = array(10, dim=c(N,time,numWeights))

# GRADIENT PROPAGATION
# ====================

      increment = array ( 0, dim=c(1,1,numWeights))
      m         = array ( 0, dim=c(N, 1))
      H         = array ( 0, dim=c(numWeights, N ))
      Qekf      = KalmanQ * diag( vector("numeric",numWeights)+1)
      Rekf      = KalmanR
      Pekf     = diag( vector("numeric",numWeights)+1)
      xekf      = array ( 0, dim=c(1,numWeights))

     
      for ( s in 1:N ) {
    #     hold = mlph ( input, xu[s,1,], s1, s2 )
          hold = mlph ( input, xu[s,], s1, s2 )

          m[s,1] = hold$m
          H[,s] =  hold$H
          Pekf  =  P[s,,]
          K     =  (Pekf + Qekf) %*% H[,s] %*%  solve(
                   (( Rekf + t(H[,s])%*% ( Pekf + Qekf ) %*% H[,s] ) ))
          error =  y - m[s,1]
          xekf[1,] = xu[s,]
    #     xekf[1,] = xu[s,1,]
          x[s,1,]  = t(xekf) + K %*% error

          P[s,,]   = Pekf - K%*%t(H[,s]) %*% ( Pekf + Qekf ) + Qekf

       }
       return(list(x=x,P=P))
}

