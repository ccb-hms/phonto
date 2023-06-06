container_version = Sys.getenv("EPICONDUCTOR_CONTAINER_VERSION")
collection_date = as.Date(Sys.getenv("COLLECTION_DATE"), format="%m-%d-%y")
if(!is.null(container_version)){
  message("EpiConductor Container Version: ", container_version)
}else{
  message("YOU ARE NOT IN THE CONTAINER, call nhanesA functions()")
}
if(!is.null(collection_date)){
  message("Data Collection Date: ", collection_date)
}else{
  message("YOU ARE NOT IN THE CONTAINER, DO SOMETHING ELSE!")
}

