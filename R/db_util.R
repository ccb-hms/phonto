sqlHost <- "localhost"
sqlUserName <- "sa"
sqlPassword <- "yourStrong(!)Password"
sqlDefaultDb <- "NhanesLandingZone"


#' Query data from the Docker database
#'
#' @param sql string of sql
#'
#' @return a data frame of the results
#' @export
#'
#' @examples query("SELECT TOP(50) * FROM QuestionnaireVariables;")
query <- function(sql){
  cn  <- MsSqlTools::connectMsSqlSqlLogin(
    server <- sqlHost,
    user <- sqlUserName,
    password <- sqlPassword,
    database <- sqlDefaultDb
  )

 df <- DBI::dbGetQuery(cn, sql)
 DBI::dbDisconnect(cn)

 df
}



