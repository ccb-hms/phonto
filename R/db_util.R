
#' Query data from the Docker database
#'
#' It is an internal function.
#'
#' @param sql string of sql
#'
#' @return a data frame of the results
#'
#' @examples query("SELECT TOP(50) * FROM QuestionnaireVariables;")
nhanesQuery <- function(sql){

  cn  <- MsSqlTools::connectMsSqlSqlLogin(
    server <- "localhost",
    user <- "sa",
    password <- "yourStrong(!)Password",
    database <- "NhanesLandingZone"
  )

 df <- DBI::dbGetQuery(cn, sql)
 DBI::dbDisconnect(cn)

 df
}

