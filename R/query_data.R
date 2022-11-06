
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
                      WHERE Variable = '", varname,"';")
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
  df <- NULL
  if (length(tb_names)<2){
    df <- nhanesA::nhanes(tb_names)
  }else{
    df <- nhanesA::nhanes(tb_names[1])
    for (tn in tb_names[2:length(tb_names)]) {
      tb_tmp <- nhanesA::nhanes(tn)
      com_cols <- intersect(colnames(df), colnames(tb_tmp))
      df <- rbind(df[, com_cols], tb_tmp[, com_cols])
    }
  }
  if(!is.null(cols)){
    cols <- intersect(colnames(df), cols)
    df <- df[,c("SEQN",cols)]
  }

  df

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


