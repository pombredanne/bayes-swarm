mlpratios <- function ( xu,input,y,s1,s2,R)
{
# PURPOSE : To evaluate the normalised importance ratios.
# INPUTS  : - xu = The predicted network weights samples.
#           - input = The input observations.
#           - y = The output observations.
#           - s1 = Number of neurons in the hidden layer.
#           - s2 = Number of neurons in the output layer (=1).
#           - R = Measurement noise variance parameter.
# OUTPUTS : - q = The normalised importance ratios.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRANSLATED TO R BY : Alessandro Bonazzi
# DATE    : 20-08-07


      hold=dim(xu)
      numsamples = hold[1]
      time       = 1 #hold[2]
      numweights = hold[2] # hold[3]

      q          = array ( 0, dim=c(numsamples,1))
      m          = array ( 0, dim=c(numsamples,1))

      for ( i in 1:numsamples ) {
             m[s,1] = mlp ( input, xu[s,], s1, s2 )
             q[s,1] = exp (-.5*solve(R)%*%(y- m[s,1])^(2))
      }
      q = q/ sum(q[,1])

      return(q)
}

