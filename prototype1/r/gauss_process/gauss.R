########################
# Gaussian Process -  v 0.1
# 29/09/07
# A. Bonazzi
# bayesfor
# reference : http://www.rainsoft.de/publications/gp_for_ml.pdf


# set grid
x= 1: 10
# simulate obs for the first 4 grid points
y1= sin(x[1:4]/2)

n=length(x)

# set some parameters for Covariance Matrix
# ! not optimal yet!!!
sigma=1
l1=20
sigmav=0

K=myCov(x, n, sigma, l1, sigmav )

# do the job
Kinv = solve(K)

ly1 = length(y1)
ly2 = n-ly1

C=Kinv[( ly1+1 ) : (ly1 + ly2 ), ( ly1+1 ) : (ly1 + ly2 ) ]
BT = Kinv[ ( ly1+1 ) : (ly1 + ly2 ), 1:ly1 ]

y2m <-  -solve(C) %*% BT %*% y1


# plot input data + mean of forecast
plot(ts(c(y1,y2m)))

y=c(y1,y2m)
error=c(rep(0,ly1),sqrt(diag(solve(C))) )

# do be done, plot with error bar....
%plotCI( y, uiw= error, liw = uiw, err='y')
     


     
myCov <-  function( x, n, sigma, l1, sigmav ) {

   d=array(0, dim=c(n,n))
   for ( i in 1:n) {
       for ( j in 1:n ) {
           d[i,j] = sqrt( (  x[i] - x[j] )^2)
        }
    }

K= sigma * exp ( -1/(2*l1) * d^2 )
noise=array(rnorm(n*n), dim=c(n,n))
K = K + noise*sigmav
   
return(K)
}





     

     


     



     
