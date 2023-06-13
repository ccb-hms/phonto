
## Query data from the Docker database
## examples: nhanesQuery("SELECT TOP(50) * FROM Metadata.QuestionnaireVariables;")
nhanesQuery <- function(sql){

  # suppress warining from DBI::dbConnect()
  before <- getTaskCallbackNames()
    cn  <- MsSqlTools::connectMsSqlSqlLogin(
      server = "localhost",
      user ="sa",
      password="yourStrong(!)Password",
      database="NhanesLandingZone")
    after <- getTaskCallbackNames()
    removeTaskCallback(which(!after %in% before))

    df <- DBI::dbGetQuery(cn, sql)
    DBI::dbDisconnect(cn)

  df
}

# query table names from Metadata.QuestionnaireVariables
validTables = nhanesQuery("SELECT DISTINCT TableName FROM Metadata.QuestionnaireVariables;")$TableName

# check if the table names are valid
checkTableNames = function(table_name){
   if(is.null(table_name)){
    stop("Table name cannot be null!")
  }
  if(!all(table_name %in% validTables)){
    stop(paste0("Invalid table name: ",table_name,""))
  }
}
