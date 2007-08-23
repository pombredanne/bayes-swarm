# PURPOSE : To estimate the input-output mapping with inputs x
#           and outputs y generated by the following nonlinear,
#           nonstationary state space model:
#           x(t+1) = 0.5x(t) + [25x(t)]/[(1+x(t))^(2)]
#                    + 8cos(1.2t) + process noise
#           y(t) =  x(t)^(2) / 20  + 6 squareWave(0.05(t-1)) + 3
#                   + time varying measurement noise
#           using a multi-layer perceptron (MLP) and both the EKF and
#           the hybrid importance-samping resampling (SIR) algorithm.            

# AUTHOR  : Nando de Freitas - Thanks for the acknowledgement :-)
# DATE    : 08-09-98
# TRANSLATED TO R BY : Alessandro Bonazzi
# DATE    : 10-08-07

source("hybridsir.r")
# INITIALISATION AND PARAMETERS:
# =============================

N = 120                # Number of time steps.
t = 1:1:N              # Time.
x0 = 0.1               # Initial input.
x = array(0,dim=c(N,1))# Input observation.
y = array(0,dim=c(N,1))# Output observation.
x[1,1] = x0            # Initia input.
actualR = 2            # Measurement noise variance.
actualQ = 1e-2         # Process noise variance.
numSamples=50          # Number of Monte Carlo samples per time step.
s1=10                  # Neurons in the hidden layer.
s2=1                   # Neurons in the output layer - only one in this implementation.
Q = 1e-2               # Process noise variance.
R = 2                  # Measurement noise variance.
initVar1= 10           # Variance of prior for weights in the hidden layer.
initVar2= 10           # Variance of prior for weights in the output layer.
KalmanR = 2            # Kalman filter measurement noise covariance hyperparameter;
KalmanQ = 1e-2         # Kalman filter process noise covariance hyperparameter;
KalmanP = 1            # Kalman filter initial weights covariance hyperparameter;


# GENERATE PROCESS AND MEASUREMENT NOISE:
# ======================================

v = sqrt(actualR)* array(sin(0.1*t),dim=c(N,1))* array(rnorm(N),dim=c(N,1))
w = sqrt(actualQ)* array(rnorm(N),dim=c(N,1))


# GENERATE INPUT-OUTPUT DATA:
# ==========================

y[1,1] = (x[1,1]^(2))/20 + v[1,1]
for ( t in 2:N) {
  x[t,1] = 0.5*x[t-1,1] + 25*x[t-1,1]/(1+x[t-1,1]^(2)) + 8*cos(1.2*(t-1)) + w[t,1]
  y[t,1] = (x[t,1]^(2))/20 + 6*sin(0.05*(t-1))+ 3 + v[t,1] #replace sin with SQUARE
}

# PERFORM SEQUENTIAL MONTE CARLO FILTERING TO TRAIN MLP:
# =====================================================

hyb = hybridsir(x,y,s1,s2,numSamples,Q,initVar1,
           initVar2,R,KalmanR,KalmanQ,KalmanP,N)

postscript(file="figure/problem.eps",horizontal=FALSE)
par(mfrow=c(2,1))
plot(ts(x))
title("Predictor")

plot(ts(y))
title("Response y")
dev.off()

postscript(file="figure/prediction.eps",horizontal=FALSE)
par(mfrow=c(3,1))
plot(ts(hyb$m[1,]),type="s")
title("One step Forecast")

plot(ts(y),type="s")
title("Verification y")

plot(ts(y-hyb$m[1,]),type="b")
title("error")
dev.off()

