
#' Download/Load an NHANES table and return as a data frame.
#'
#' @param nh_table The name of the specific table to retrieve.
#'
#' @return
#' @export
#'
#' @examples nhanes('BPX_E')
#' @description Use to download/load NHANES data tables that are in SAS format.
nhanes = function(nh_table){
  sql = paste0("SELECT * FROM ",nh_table)
  df = query(sql)

  cols = paste0("SELECT Variable from
                QuestionnaireVariables where Questionnaire='",
                nh_table,
                "'")
  cols = query(cols)
  cols = cols$Variable
  cols = cols[!cols %in% c("years","DownloadUrl","Questionnaire")]
  df[,cols]
}


#' Search for tables that contain a specified variable
#'
#' @details The NHANES Comprehensive Variable List is scanned to find all data tables that contain the given variable name. Only a single variable name may be entered, and only exact matches will be found.
#' @param varnames Names of variable to match.
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
#' @examples searchTablesByVar(c('BPXPULS','BMXBMI'))
#' @examples searchTablesByVar(c('BPXPULS','BMXBMI'),ystop=2004)
searchTablesByVar <- function(varnames = NULL,
                              ystart = NULL,
                              ystop = NULL,
                              includerdc = FALSE,
                              nchar = 128,
                              namesonly = TRUE){

  sql <- paste0("SELECT DISTINCT Variable,
                        Questionnaire,TableName,
                        CONCAT(q.BeginYear, '-', q.EndYear) AS years
                      FROM QuestionnaireVariables q
                      WHERE Variable IN (", toString(sprintf("'%s'", varnames)),")")



  if(!is.null(ystart)){
    sql <- paste(sql,"AND BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND EndYear <=",ystop)
  }

  df = query(sql)
  for(v in varnames){
    if(!(v %in% df$Variable)){
      warning(paste("Variable ",v, "is not found in the database!"))
    }
  }
  df

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

  sql <- paste0("SELECT DISTINCT
                        Questionnaire,TableName,
                        CONCAT(q.BeginYear, '-', q.EndYear) AS years
                      FROM QuestionnaireVariables q
                  WHERE Questionnaire LIKE '%",pattern,"%'"
  )
  if(!is.null(ystart)){
    sql <- paste(sql,"AND BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND EndYear <=",ystop)
  }

  df = query(sql)

  if(is.null(df) | nrow(df)==0){
    warning(paste("Cannot find any table name like:",pattern,"!"))
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

translate = function(var_df, data){
  for(i in 1:nrow(var_df)){
    data[data[,var_df[i,]$Variable] == var_df[i,]$CodeOrValue,
         var_df[i,]$Variable] = var_df[i,]$ValueDescription
  }
  data[unique(var_df$Variable)] = lapply(data[unique(var_df$Variable)], factor)
  data
}

#' Display code translation information.
#'
#' @param nh_table The name of the NHANES table to retrieve.
#' @param colnames 	The names of the columns to translate.
#' @param data If a data frame is passed, then code translation will be applied directly to the data frame.
#'             In that case the return argument is the code-translated data frame.
#' @param nchar Applies only when data is defined. Code translations can be very long. Truncate the length by setting nchar (default = 32).
#' @param mincategories The minimum number of categories needed for code translations to be applied to the data (default=2).
#' @param details If TRUE then all available table translation information is displayed (default=FALSE).
#' @param dxa If TRUE then the 2005-2006 DXA translation table will be used (default=FALSE).
#' @details Most NHANES data tables have encoded values. E.g. 1 = 'Male', 2 = 'Female'. Thus it is often helpful to view the code translations and perhaps insert the translated values in a data frame. Only a single table may be specified, but multiple variables within that table can be selected. Code translations are retrieved for each variable.
#'
#' @return The code translation table (or translated data frame when data is defined). Returns NULL upon error.
#' @export
#'
#' @examples nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1")
#' @examples data = nhanes("DEMO_C")
#' nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1"),data)
nhanesTranslate = function(
    nh_table,
    colnames = NULL,
    data = NULL,
    nchar = 32,
    mincategories = 2,
    details = FALSE,
    dxa = FALSE
    ){

  sql = "SELECT Variable,CodeOrValue,ValueDescription
             FROM VariableCodebook WHERE Questionnaire='"

  if(details==T){
    sql = "SELECT Variable,CodeOrValue,ValueDescription,Count,Cumulative,SkipToItem FROM VariableCodebook
            WHERE Questionnaire='"
  }
  sql = paste0(sql,nh_table,"'")
  sql = paste0(sql,"AND Variable IN (", toString(sprintf("'%s'", colnames)),")")

  df = query(sql)

  if(!is.null(data)){
    data = translate(df,data)
    return(data)
  }else{
    return(df)
  }

}

