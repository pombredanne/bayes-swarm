**Introduction**

A simple neural-network model applied to
bayesfor  data.


We consider the time series of stem "CHINA" and "INDIA" that was
collected during the first month of bayesfor activities.
The data consists on daily mean of stem counts.

![http://www.bo.ingv.it/~bonazzi/bayesfor/china_india_data.png](http://www.bo.ingv.it/~bonazzi/bayesfor/china_india_data.png)

**The Model**

We define the stem "CHINA" to be a predictor of the stem "INDIA", and we propose a neural network model to describe the relation between the two stems.

```
    #x : CHINA
    #y : INDIA
    #w : weight of neural network
    #d : uncertainty  for neural network
    #v : measurement error


    w_{t+1} = w_t + d_t
    y_t     = g( w_t, x_t ) + v_k

```


The solution of this problem is the  posterior density p( W | Y ), where
Y = { y\_1, y\_2, ..., y\_t } and W = { w\_1, w\_2, ... , w\_t }.
However for the application we consider, we are really interested only
on the filtering density p( w\_t | y\_t ), this because we only want
to predict the behavior of our observation at a specific time.

This filtering density is estimate in two stages: prediction and update.
```

   p ( w_t | w_{t-1} )   # prediction
   p ( w_t | y_k     )   # update
```


The bayes rule is use to solve the update stage:
```
    p( w_t | y_k ) = p ( y_t | w_t ) p ( w_k | Y_{t-1} ) /
                             p( y_t | Y_{t-1} )
```


To avoid the computation of multi-dimensional integrations, Monte Carlo
methods are used.

**Preliminary Results**

![http://www.bo.ingv.it/~bonazzi/bayesfor/timeseries.png](http://www.bo.ingv.it/~bonazzi/bayesfor/timeseries.png)

This plot shows the time-series of stem "INDIA" (green) and "CHINA" (red).
Those are the same data displayed on figure 1.
The black points are the neural-network forecast for the stem "INDIA", based
on "CHINA". At each time, we observe a probability distribution
for the forecast stem INDIA. The Monte Carlo Markov Chain simulation is based
on 1000 samples.

![http://www.bo.ingv.it/~bonazzi/bayesfor/histogram.png](http://www.bo.ingv.it/~bonazzi/bayesfor/histogram.png)


This figure shows the forecast distribution at time step 37.
The green line is the observed value.


