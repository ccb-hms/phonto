


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
  tables <- nhanesQuery(sql)$TableName
  # need a try catch here
  unionQuery(tables,vars)

}


#' Query Data with names of the tables
#'
#'
#'
#' @param tb_names names of the tables
#' @param cols columns, the function will query all the columns if it is set to NULL as default.
#'
#' @return it combines the researched results and returns the results as a data frame.
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
  nhanesQuery(sql)

}

#' Joint Query
#'
#' @param table_names list of the table names want to joint and query
#' @param cols columns
#'
#' @return it merges the researched results and returns the results as a data frame.
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

  nhanesQuery(sql)

}


