bayesfor_ts <- function(stem_id) {
  # retrieves bayes-swarm stem data for the given id or id vector
  # if stem_id is a vector, only matching data is retrieved
  # returns a data.frame class object
  
  # FIXME: bayesfor_ts should be able to either read a .Rdata file
  # or access directly bayes-swarm db via RMySql
  load("some_data.Rdata")

  if (length(stem_id)==1) {
    data.frame(count=subset(data, id==stem_id, select=num)[,1], 
      date=as.Date(subset(data, id==stem_id, select=data)[,1]))
  }
  else {
    m <- length(stem_id)
    matching_dates <- as.Date(subset(data, id==stem_id[1], select=data)[,1])
    for (i in 2:m) {
      matching_dates_next <- as.Date(subset(data, id==stem_id[i], select=data)[,1])
      matching_dates <- intersect(matching_dates, matching_dates_next)
    }
    stems_data <- data.frame(date=matching_dates)
    matching_dates_int = as.integer(matching_dates)
    for (i in 1:m) {
      current_stem_count <- matrix(subset(data, id==stem_id[i], select=num)[,1], 
        length(subset(data, id==stem_id[i], select=num)[,1]),
        1, 
        dimnames=list(as.Date(subset(data, id==stem_id[i], select=data)[,1]), 
          "count"))
      stems_data <- data.frame(stems_data, current_stem_count[paste(matching_dates_int), 1])
      colnames(stems_data)[i+1] <- subset(data, id==stem_id[i], select=name)[1,1]
    }
    stems_data
  }
}
