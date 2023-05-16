epv = Sys.getenv("EPICONDUCTOR_CONTAINER_VERSION")
cldate = Sys.getenv("COLLECTION_DATE")
if(grepl("\\d{1,4}[.]\\d{1,4}[.]\\d{1,4}",epv)){
  message("EpiConductor Version: ", epv)
}else{
  message("YOU ARE NOT IN THE CONTAINER, DO SOMETHING ELSE!")
}
if(grepl("\\d{2}-\\d{2}-\\d{2,4}",cldate)){
  message("Data Collection Date: ", cldate)
}else{
  message("YOU ARE NOT IN THE CONTAINER, DO SOMETHING ELSE!")
}

