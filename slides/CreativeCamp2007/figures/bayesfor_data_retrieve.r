bayesfor_ts <- function(stem_id, infile = NULL, db_params = NULL) {
  # retrieves bayes-swarm stem data for the given id or id vector
  # if stem_id is a vector, only matching data is retrieved
  
  # returns a data.frame class object like so:
  #          date   china   india
  # 1  2007-08-01 12.0000 12.0000
  # 2  2007-08-02 12.0000 12.0000
  # 3  2007-08-03 11.0000 14.0000

  # FIXME: bayesfor_ts should be able to either read a .Rdata file
  # or access directly bayes-swarm db via RMySql
  #load("some_data.Rdata")
  
  if ((is.null(infile)) && (is.null(db_params)) ||
    (!is.null(infile)) && (!is.null(db_params)))
    stop("you have to enter either infile or db_params")
  
  if (!is.null(infile)) load(infile)
  else {
    library(RMySQL)
    if (!is.list(db_params) || is.null(db_params$user) || is.null(db_params$password)
      || is.null(db_params$dbname) || is.null(db_params$host))
      stop("db_params must be a list with attributes: user, password, dbname, host")
    mycon <- dbConnect(MySQL(), user=db_params$user, dbname=db_params$dbname,
      host=db_params$host, password=db_params$password)
    ids_list <- eval(paste(stem_id, collapse=", " ))
    query <- dbSendQuery(mycon, paste("SELECT a.id, c.name, avg(a.count) as num, date(a.scantime) as data
                                       FROM words a, int_words c, pages b
                                       WHERE a.id = c.id
                                         AND a.page_id = b.id
                                         AND a.id in (",ids_list,")
                                       GROUP BY a.id, c.name, date(a.scantime);"))
    data <- fetch(query, n = -1)
    data
  }

  if (length(stem_id)==1) {
    stems_data <- data.frame(date=as.Date(subset(data, id==stem_id, select=data)[,1]),
      count=subset(data, id==stem_id, select=num)[,1])
    colnames(stems_data)[2] <- subset(data, id==stem_id, select=name)[1,1]
    stems_data
  }
  else {
    m <- length(stem_id)
    matching_dates_int <- as.integer(as.Date(subset(data, id==stem_id[1], select=data)[,1]))
    for (i in 2:m) {
      matching_dates_next <- as.Date(subset(data, id==stem_id[i], select=data)[,1])
      matching_dates_int <- intersect(matching_dates_int, matching_dates_next)
    }
    matching_dates <- as.Date("1970-01-01") + matching_dates_int
    stems_data <- data.frame(date=matching_dates)

    for (i in 1:m) {
      current_stem_count <- matrix(subset(data, id==stem_id[i], select=num)[,1], 
        length(subset(data, id==stem_id[i], select=num)[,1]),
        1, 
        dimnames=list(as.Date(subset(data, id==stem_id[i], select=data)[,1]), 
          "count"))
      stems_data <- data.frame(stems_data, current_stem_count[paste(matching_dates_int), 1])
      colnames(stems_data)[i+1] <- subset(data, id==stem_id[i], select=name)[1,1]
      rownames(stems_data) <- 1:dim(stems_data)[1]
    }
    stems_data
  }
}
