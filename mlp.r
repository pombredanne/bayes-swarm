mlp <- function ( x, theta, s1, s2 ) 
{
# PURPOSE : To simulate a one hidden layer sigmoidal MLP.
# INPUTS  : - x = The network input.
#           - theta = The network weights.
#           - s1 = Number of neurons in the hidden layer.
#           - s2 = Number of neurons in the output layer (=1).
# OUTPUTS : - y = The network output.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRANSLATED TO R BY : Alessandro Bonazzi
# DATE    : 10-08-07

# fill in weight matrices using the parameter vector:
# ==================================================
     if (is.array(x)) { 
        hold = dim (x)
        rows = hold[1]
        N    = hold[2]
     }
     if (is.vector(x)) {
        rows=length(x)
        N   =1 
     }
     w2   = array(0, dim=c(s2,s1+1))
     w1   = array(0, dim=c(s1,N+1))

     L    = 0
     for ( i in 1:s2 ) {
#         w2[i,] = theta[1,1,(L+1):(L+s1+1)]
          w2[i,] = theta[(L+1):(L+s1+1)]
          L      = L+s1+1
     }
     for ( i in 1:s1 ) {
#         w1[i,] = theta[1,1,(L+1):(L+N+1)]
          w1[i,] = theta[(L+1):(L+N+1)]
          L      = L+N+1
     }


# Compute the network outputs for each layer:
# ==========================================
     hold = array(c(1,x),dim=c(length(x)+1,1))
     u1   = w1 %*% hold

     o1   = 1 / ( 1 + exp ( -u1 ))
     hold = array(c(1,o1[,1]),dim=c(length(o1[,1])+1,1))
     u2   = w2 %*% hold
     y    = u2
     return(y)
}
 
