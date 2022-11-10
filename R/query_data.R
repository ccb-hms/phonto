
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

  sql <- paste0("SELECT DISTINCT Questionnaire,TableName
                      FROM QuestionnaireVariables
                      WHERE Variable = '", varname,"'")
  if(!is.null(ystart)){
    sql <- paste(sql,"AND BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND EndYear <=",ystop)
  }

  query(sql)

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

  sql <- paste0("SELECT DISTINCT Questionnaire,TableName
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

  query(sql)


}

#' Query data by variable
#'
#' It search the tables contain the given variables and query data union
#' @param vars variables or phenotypes want to search
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#'
#' @return union data frame
#' @export
#'
#' @examples queryByVars(c("URXDAZ","URXDMA"))
#' @examples vars = c("URXDAZ","URXDMA","URXEQU", "URXETD","URXETL","URXGNS")
#' df = queryByVars(vars)
queryByVars = function(vars=NULL,ystart = NULL,ystop = NULL){
  if(is.null(vars) | length(vars) <1) return (NULL)
  vars <- unique(vars)
  sql = paste0("SELECT DISTINCT TableName
                     FROM QuestionnaireVariables
                     WHERE Variable='",vars[1],
                     "'")
  if(length(vars)>=2){
    for(v in vars[2:length(vars)]){
      sql = paste0(sql," OR Variable='",v,"'")
    }
  }
  tables <- query(sql)$TableName
  # need a try catch here
  unionQuery(tables,vars)

}


#' Query Data with names of the tables
#'
#'
#'
#' @param tb_names names of the tables
#' @param cols columns
#'
#' @return queried data frane
#' @export
#'
#' @examples unionQuery(tb_names=c("BPX_D","BPX_E"),cols=c("BPXDI1","BPXDI2"))
#' @examples unionQuery(tb_names=c("PhthalatesPhytoestrogensAndPAHsUrine","PhytoestrogensUrine"),cols=c("URXDAZ","URXDMA"))
#'
unionQuery <- function(tb_names, cols=NULL){
  tb_names = unique(tb_names)
  if(is.null(cols)){
    cols <- "*"
  }else{
    cols <- paste(c("SEQN",cols),collapse=",")
  }

  sql<- paste0("SELECT ",cols ,
                " FROM ",tb_names[1])
  if(length(tb_names)>=2){
    for(tl_n in tb_names[2:length(tb_names)]){
      sql = paste0(sql," UNION SELECT ",cols ,
                   " FROM ",tl_n)
    }

  }
  query(sql)

}

#' Joint Query
#'
#' @param table_names list of the table names want to joint and query
#' @param cols columns
#'
#' @return queried data frame
#' @export
#'
#' @examples jointQuery(c("DEMO","BMX"))
#' @examples jointQuery(c("DEMO","BodyMeasures"))
#' @example  cols = c("RIDAGEYR","RIAGENDR","BMXBMI","DMDEDUC2")
#' jointQuery(c('BodyMeasures','DemographicVariablesAndSampleWeights'),cols)
jointQuery <- function(table_names,cols=NULL){

  if(is.null(cols)){
    cols <- "*"
  }else{
    cols <- paste0(c(paste0(table_names[1],".SEQN"),cols),collapse=", ")
  }

  sql <- paste("SELECT ",cols,
               "FROM", table_names[1])
  if(length(table_names)>=2){
    for(long_tb in table_names[2:length(table_names)]){
      sql <- paste0(sql," INNER JOIN ",long_tb," ON ",table_names[1],".SEQN = ",long_tb,".SEQN")
    }
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


