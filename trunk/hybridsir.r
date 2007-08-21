hybridsir <- function(input,y,s1,s2,S,Q,initVar1,initVar2,
                         R,KalmanR,KalmanQ,KalmanP,tsteps) 
{
# PURPOSE : To train an MLP with the hybrid SIR algorithm.
# INPUTS  : - input = The input observations.
#           - y = The output observation.
#           - s1 = Number of neurons in the hidden layer.
#           - s2 = Number of neurons in the output layer (1).
#           - S = Number of samples describing the network weights.
#           - Q = Process noise variance parameter.
#           - initVar1 = Initial variance of the hidden layer weights.
#           - initVar2 = Initial variance of the output layer weights.
#           - R = Measurement noise variance parameter.
#           - KalmanR = EKF measurement noise hyperparameter.
#           - KalmanQ = EKF process noise hyperparameter.
#           - KalmanP = initial EKF covariances for each trajectory.
#           - tsteps = Number of time steps (input error checking).
# OUTPUTS : - x = Samples describing the network weights.
#           - q = Normalised importance ratios.
#           - m = Samples describing the network one-step-ahead prediction.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRANSLATED TO R BY : Alessandro Bonazzi
# DATE    : 10-08-07

      source("mlp.r")
      source("predictmlp.r")
      source("gradupdate.r")
      source("mlpratios.r")
      source("resamplemlp.r")
 
      hold = dim(y)  # rows = Max number of time steps.
      rows = hold[1]
      hold = dim(input)
      r    = hold[1]
      inputdim = hold[2]

      T = s2*(s1+1) + s1*(inputdim+1)   # Number of states (MLP weights).
      Nstd = 3                    # No of standard deviations for error bars
      x =  array(0,dim=c(S,rows,T))
      xu=  array(0,dim=c(S,rows,T))
      q =  array(0,dim=c(S,rows))
      m =  array(0,dim=c(S,rows))
      H =  array(0,dim=c(T,S))
      P =  array(0,dim=c(S,T,T))

      for ( s in 1:S ) {
           P[s,,]= sqrt(KalmanP)*diag(T)
      }

# SAMPLE FROM THE PRIOR:
# =====================
    
      x[,1,] = sqrt(initVar2)* array(rnorm(S*1*T),dim=c(S,1,T))
      hold   = T-(s1+1)
      x[,1,(s1+2):T] = sqrt(initVar1)* array(rnorm(S*1*hold),dim=c(S,1,hold))

# UPDATE AND PREDICTION STAGES:
# ============================
 
      for ( t in 1:(rows-1) ) {
            
            for ( s in 1:S )  {
                   m[s,t+1] = mlp ( input[t+1,], x[s,t,], s1, s2 )
            }

            xu [,t,] = predictmlp(x[,t,],Q)
            Z        = gradupdate(xu[,t,],input[t+1,],y[t+1,1], 
                           s1,s2,P,KalmanR,KalmanQ )
            xu [,t,] = Z$x
            P        = Z$P
            q[,t]    = mlpratios(xu[,t,],input[t+1,],y[t+1,1],
                           s1,s2,R)
            Z        = resamplemlp(xu[,t,],q[,t],P)
        
            x[,t+1,] = Z$x
            P        = Z$P

       }

       hyb <- list ( x=x, q=q, m=m )
       return(hyb)
              
}













