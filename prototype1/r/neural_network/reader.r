
sum.count <- function( data ) 
{
   raw = type.convert(data[,1])
   idx_c = findHur( data[,2] )
   count=vector()
   for ( i in 1: max(idx_c) ) {
          idx=(idx_c==i)
          count[i]=sum(raw[idx])
   }
   return(count)
}

read <- function(filenm) {
  fileID <- file(filenm,open="rt")

  nFields <- count.fields(fileID)

  mat <- matrix(nrow=length(nFields),ncol=max(nFields))
  convMat <- array(0, dim=c(length(nFields),2))

  invisible(seek(fileID,where=0,origin="start",rw="read"))

  for(i in 1:nrow(mat) ) {
    mat[i,1:nFields[i]] <-scan(fileID,what="",nlines=1,quiet=TRUE)
    hold = mat[i,2]
    }

  close(fileID)
  return(mat)
}

findHur <- function ( namelist )
{
             N      = length ( namelist )
             idx    = vector("numeric")
             i      = 1
             ind    = 1
             k=10

             khold  = substr(namelist[i],1,k)
             idx[1] = ind
             for ( i in 2:N ) {

                  if (  substr(namelist[i],1,k) == khold ) {
                        idx[i] = ind }
                  else {
                        khold  =  substr(namelist[i],1,k)
                        ind    =  ind+1
                        idx[i] = ind
                   }
             }

             return(idx)
}




read.irregular <- function(filenm) {
  fileID <- file(filenm,open="rt")

  nFields <- count.fields(fileID)

  mat <- matrix(nrow=length(nFields),ncol=max(nFields)) 
  convMat <- array(0, dim=c(length(nFields),2))

  invisible(seek(fileID,where=0,origin="start",rw="read"))  

  for(i in 1:nrow(mat) ) {
    mat[i,1:nFields[i]] <-scan(fileID,what="",nlines=1,quiet=TRUE)  
    convMat[i,1]=type.convert(mat[i,1])
    hold = mat[i,2]
    convMat[i,2]=type.convert(paste(
                   substr(hold,1,4),
                   substr(hold,6,7),
                   substr(hold,9,10) ,sep="" ))
    }

  close(fileID)
  return(convMat)
}
