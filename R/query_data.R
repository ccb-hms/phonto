


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



#' Joint Query
#'
#' @param tables_n_cols
#'
#' @return
#' @export
#'
#' @examples jointQuery( list(BPQ_J=c("BPQ020", "BPQ050A"), DEMO_J=c("RIDAGEYR","RIAGENDR")))
jointQuery <- function(tables_n_cols){
  tb_names = names(tables_n_cols)

  cols=toString(sprintf("%s", unlist(tables_n_cols)))

  sql<- paste0("SELECT ",cols ,
                " FROM ",tb_names[1])

  if(length(tb_names)>=2){
    for(long_tb in tb_names[2:length(tb_names)]){
      sql <- paste0(sql," INNER JOIN ",long_tb," ON ",tb_names[1],".SEQN = ",long_tb,".SEQN")
    }
  }


  # print(sql)
  nhanesQuery(sql)

}


#' Union Query
#'
#' @param table_names
#' @param cols
#'
#' @return
#' @export
#'
#' @examples unionQuery(c("DEMO_B","DEMO_D"),c("RIDAGEYR","RIAGENDR"))
unionQuery= function(table_names,cols=NULL){

  if(is.null(cols)){
    cols <- "*"
  }else{
    cols <- paste0("SEQN, ",toString(sprintf("%s", cols)))
  }

  sql <- paste("SELECT ",cols,
               "FROM", table_names[1])
  if(length(table_names)>=2){
    for(tl_n in table_names[2:length(table_names)]){
      sql = paste0(sql," UNION SELECT ",cols ,
                   " FROM ",tl_n)
    }

  }

  print(sql)
  nhanesQuery(sql)

}



#' Check Variable Consistency
#'
#' Check if the variables across over two tables and encoded as the same values.
#'
#'
#' @param table1 NHANES table name 1
#' @param table2 NHANES table name 2
#'
#' @return it returns a matrix, and the first and second row show whether the variable existing in table 1 or table 2, TRUE values means existing, FALSE means not existing. The third whether the variables are encoded in the same values if they shown in both tables, TRUE means encoded as the same, FALSE means they are encoded as the different value.
#'
#' @export
#'
#' @examples checkDataConst("DEMO_C","DEMO_D")
checkDataConst = function(table1,table2){
  data1 = nhanes(table1)
  data2 = nhanes(table2)
  cols=union(colnames(data1), colnames(data2))
  len_cols = length(cols)
  res = matrix(data=FALSE,nrow=3,ncol=len_cols)
  colnames(res) = cols
  rownames(res) = c(table1,table2,"Encode")
  for (i in 1:len_cols) {
    if (cols[i] %in% colnames(data1)){
      res[1,i]=TRUE
    }

    if (cols[i] %in% colnames(data2)){
      res[2,i]=TRUE
    }

    if(cols[i] %in% colnames(data2) & cols[i] %in% colnames(data2)){
      code1 = nhanesTranslate(table1,cols[i])
      code2 = nhanesTranslate(table1,cols[i])
      res[3,i] = all.equal(code1[[cols[i]]],code2[[cols[i]]])
    }else{
      res[3,i] = NA
    }
  }

  res

}


