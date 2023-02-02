
## Query data from the Docker database
## examples: nhanesQuery("SELECT TOP(50) * FROM QuestionnaireVariables;")
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

