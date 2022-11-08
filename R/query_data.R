
#' Search for tables that contain a specified variable
#'
#' @details The NHANES Comprehensive Variable List is scanned to find all data tables that contain the given variable name. Only a single variable name may be entered, and only exact matches will be found.
#' @param varname Name of variable to match.
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#' @param includerdc If TRUE then RDC only tables are included in list (default=FALSE).
#' @param nchar Truncates the variable description to a max length of nchar.
#' @param namesonly 	If TRUE then only the table names are returned (default=TRUE).
#'
#' @return By default, a character vector of table names that include the specified variable is returned. If namesonly=FALSE, then a data frame of table attributes is returned.
#' @export
#'
#' @examples searchTablesByVar('BPXPULS')
searchTablesByVar <- function(varname = NULL,
                              ystart = NULL,
                              ystop = NULL,
                              includerdc = FALSE,
                              nchar = 128,
                              namesonly = TRUE){

  sql <- paste0("SELECT DISTINCT Questionnaire
                      FROM QuestionnaireVariables
                      WHERE Variable = '", varname,"'")
  if(!is.null(ystart)){
    sql <- paste(sql,"AND BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND EndYear <=",ystop)
  }

  res <- query(sql)
  if(namesonly==TRUE){
    res <- res$Questionnaire
  }

  res
}


#' Search for matching table names
#'
#' @param pattern Pattern of table names to match
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#' @param includerdc If TRUE then RDC only tables are included (default=FALSE).
#' @param nchar Truncates the variable description to a max length of nchar.
#' @param details If TRUE then complete table information from the comprehensive data list is returned (default=FALSE).
#'
#' @return Returns a character vector of table names that match the given pattern. If details=TRUE, then a data frame of table attributes is returned. NULL is returned when an HTML read error is encountered.
#' @export
#'
#' @examples searchTableByName("BPX")
searchTableByName <-  function(pattern = NULL,
                               ystart = NULL,
                               ystop = NULL,
                               includerdc = FALSE,
                               nchar = 128,
                               details = FALSE){

  sql <- paste0("SELECT DISTINCT Questionnaire
                  FROM
                      QuestionnaireVariables
                  WHERE Questionnaire LIKE '%",pattern,"%'"
                )
  if(!is.null(ystart)){
    sql <- paste(sql,"AND BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND EndYear <=",ystop)
  }

  res <- query(sql)
  if(details==FALSE){
    res <- res$Questionnaire
  }

  res

}


#' Query Data with names of the tables
#'
#' When multiple tables have been assigned, it will query all the tables, combine them, and only keeps the columns shared by all the tables.
#'
#' @param tb_names names of the tables
#' @param cols columns
#'
#' @return queried data frane
#' @export
#'
#' @examples queryData(tb_names=c("BPX_D","BPX_E"),cols=c("BPXDI1","BPXDI2"))
#'
queryData <- function(tb_names, cols=NULL){
  long_table <- query(paste0("SELECT DISTINCT TableName
                             FROM QuestionnaireVariables
                             WHERE Questionnaire='",tb_names[1],"'"))
  long_table <- long_table$TableName[1]

  if(is.null(cols)){
    cols <- "*"
  }else{
    cols <- paste(c("SEQN",cols),collapse=",")
  }

  sql<- paste0("SELECT ",cols ,
                " FROM ",long_table,
                 " WHERE Questionnaire IN (",toString(sprintf("'%s'", tb_names)),")")

  query(sql)

}

#' Joint Query
#'
#' @param patterns list of the table patterns want to joint and query
#' @param cols columns
#'
#' @return queried data frame
#' @export
#'
#' @examples jointQuery(c("DEMO","BMX"))
#' @examples patterns = c("DEMO","BMX")
#' cols = c("RIDAGEYR","RIAGENDR","BMXBMI","DMDEDUC2")
#' jointQuery(patterns,cols)
jointQuery <- function(patterns,cols=NULL){
  t_sql <- paste0("SELECT DISTINCT TableName
                  FROM QuestionnaireVariables
                  WHERE Questionnaire LIKE '%",stringr::str_trim(patterns[1]),"%'")
  for(tb in patterns[2:length(patterns)]){
    t_sql <- paste0(t_sql," OR Questionnaire LIKE '%",stringr::str_trim(tb),"%'")
  }
  long_tbs <- query(t_sql)$TableName

  if(is.null(cols)){
    cols <- "*"
  }else{
    cols <- paste0(c(paste0(long_tbs[1],".SEQN"),cols),collapse=", ")
  }

  sql <- paste("SELECT ",cols,
               "FROM", long_tbs[1])
  for(long_tb in long_tbs[2:length(long_tbs)]){
    sql <- paste0(sql," INNER JOIN ",long_tb," ON ",long_tbs[1],".SEQN = ",long_tb,".SEQN")
  }

  query(sql)

}



#' Displays a list of variables in the specified NHANES table
#' @description a wrap of nhanesA::nhanesTableVars()
#'
#' @param nh_table  The name of the specific table to retrieve.
#' @param data_group The type of survey (DEMOGRAPHICS, DIETARY, EXAMINATION, LABORATORY, QUESTIONNAIRE). Abbreviated terms may also be used: (DEMO, DIET, EXAM, LAB, Q). It will check all the groups if it is NULL.
#' @param details If TRUE then all columns in the variable description are returned (default=FALSE).
#' @param nchar The number of characters in the Variable Description to print. Default length is 128, which is set to enhance readability cause variable descriptions can be very long.
#' @param namesonly If TRUE then only the variable names are returned (default=FALSE).
#'
#' @return Returns a data frame that describes variable attributes for the specified table. If namesonly=TRUE, then a character vector of the variable names is returned.
#' @export
#'
#' @examples variableDescr("DEMO")
#' @details NHANES tables may contain more than 100 variables. Function nhanesTableVars provides a concise display of variables for a specified table, which helps to ascertain quickly if the table is of interest. NULL is returned when an HTML read error is encountered.
variableDescr <- function(nh_table,
                          data_group = NULL,
                          details = FALSE,
                          nchar = 128,
                          namesonly = FALSE){
  df <- NULL
  if (!is.null(data_group)) {
    df <- nhanesA::nhanesTableVars(data_group, nh_table, details, nchar, namesonly)
  }else{
    for (g in c('DEMO', 'DIET', 'EXAM', 'LAB', 'Q')) {
      tryCatch({
        df <- nhanesA::nhanesTableVars(g, nh_table, details, nchar, namesonly)
      },
      error=function(cond) {
        # message(paste0("No information found in group ",g))
      }
      )
    }

  }
  if(!is.null(df)){
    colnames(df) <- c("Variable","Description")
  }else{
    print(paste("No information be found for table,",nh_table))
  }

  df
}


