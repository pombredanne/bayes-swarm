mlph <- function (x,theta,s1,s2)
{
# PURPOSE : To simulate a one hidden layer sigmoidal MLP and
#           return the Jacobian.
# INPUTS  : - x = The network input.
#           - theta = The network weights.
#           - s1 = Number of neurons in the hidden layer.
#           - s2 = Number of neurons in the output layer (=1).
# OUTPUTS : - y = The network output.
#           - H = The Jacobian matrix.

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRANSLATED TO T BY : Alessandro Bonazzi
# DATE    : 20-08-07

     if (is.array(x)) {
        hold = dim (x)
        rows = hold[1]
        N    = hold[2]
     }
     if (is.vector(x)) {
        rows=length(x)
        N   =1
     }
     w2 = array(0, dim=c(s2, s1+1))
     w1 = array(0, dim=c(s1, N+1 ))
     T  = s2*(s1+1) + s1*(N+1)
     H  = array(0, dim=c(T,1))

     L    = 0
     for ( i in 1:s2 ) {
          w2[i,] = theta[(L+1):(L+s1+1)]
          L      = L+s1+1
     }
     for ( i in 1:s1 ) {
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

# Compute the Jacobian:
# =====================
  
     # output layer
     for ( i in 1:s2 ) {
        for (j in 1:(s1+1) ) {
              if ( i == j ) {
                H[i*(s1+1) + j - (s1+1) ,1]= 1
              } else {
                H[i*(s1+1) + j - (s1+1) ,1]= o1[j-1,1]
              }
         }
     }

     # second layer
     for ( i in 1:s1 ) {
        for ( j in 1:(N+1)) {
              rhs = w2[1,i+1]*o1[i,1]*(1-o1[i,1])
              if ( j == 1 ) {
                  H[s2*(s1+1) + i*(N+1) + j - (N+1) ,1] = rhs
              } else {
                  H[s2*(s1+1) + i*(N+1) + j - (N+1) ,1]= rhs * x[j-1]
              }
         }
      }
      return ( list( m=y, H=H))
}
