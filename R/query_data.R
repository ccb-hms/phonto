


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
#' @param tables_n_cols a named list, each name corresponds to a Questionnaire and the value is a list of variable names.
#'
#' @return data frame containing the join of the tables and selected variables
#' @export
#'
#' @examples jointQuery( list(BPQ_J=c("BPQ020", "BPQ050A"), DEMO_J=c("RIDAGEYR","RIAGENDR")))
#' @examples cols = list(DEMO_I=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2","years"),
#'                      DEMO_J=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2","years"),
#'                      BPQ_I=c('BPQ050A','BPQ020'),BPQ_J=c('BPQ050A','BPQ020'),
#'                      HDL_I=c("LBDHDD"),HDL_J=c("LBDHDD"), TRIGLY_I=c("LBXTR","LBDLDL"),
#'                      TRIGLY_J=c("LBXTR","LBDLDL"))
#' ans = jointQuery(cols)
#' dim(ans)
jointQuery <- function(tables_n_cols){
  cols_to_tables = list() # it won't be long and we do not know the lenth ahead.
  for (cl in names(tables_n_cols)){
    col = tables_n_cols[[cl]]
    col = toString(sprintf("%s", unlist(col)))
    col = paste0("SEQN, ",col)
    if(!col %in% names(cols_to_tables)){
      cols_to_tables[[col]] = cl
    }else{
      cols_to_tables[[col]]=c(cols_to_tables[[col]],cl)
    }
  }

  sql = "WITH"
  i = 1
  for (cn in names(cols_to_tables)) {
    sql = paste(sql,LETTERS[i],"AS","(SELECT", cn," FROM ",cols_to_tables[[cn]][1])
    i = i+1
    if(length(cols_to_tables[[cn]])>1){
      for (j in 2:length(cols_to_tables[[cn]])) {
        tb1 = cols_to_tables[[cn]][j]
        sql = paste(sql,"UNION ALL SELECT", cn," FROM ",cols_to_tables[[cn]][j])
      }
    }
    sql = paste0(sql,"),")
  }

  sql = substring(sql,1,nchar(sql)-1)

  final_cols = unique(unlist(tables_n_cols))
  final_cols = toString(sprintf("%s", unlist(final_cols)))
  final_cols = paste0("A.SEQN, ",final_cols)

  query_sql = paste("SELECT",final_cols,"FROM A")
  for (i in 2:length(cols_to_tables)) {
    query_sql = paste0(query_sql," JOIN ",LETTERS[i]," ON A.SEQN=",LETTERS[i],".SEQN")
  }

  sql = paste0(sql, "
             ",query_sql)

  # print(sql)
  nhanesQuery(sql)

}


#' Union Query
#'
#' @param table_names nhanes table names
#' @param cols columns
#'
#' @return data frame
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
      sql = paste0(sql," UNION ALL SELECT ",cols ,
                   " FROM ",tl_n)
    }

  }

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
#' @examples checkDataConsistency("DEMO_C","DEMO_D")
checkDataConsistency = function(table1,table2){
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


#' The Number of Rows of an NHANES table
#'
#' @param tb_name NHANES table name
#'
#' @return an integer of length 1
#' @export
#'
#' @examples nhanesNrow("BMX_I")
nhanesNrow = function(tb_name){
  sql_str = paste0("SELECT COUNT(*) FROM ",tb_name)
  nhanesQuery(sql_str)[1,1]
}


#' The Number of Columns of an NHANES table
#'
#' @param tb_name NHANES table name
#'
#' @return an integer of length 1
#' @export
#'
#' @examples nhanesNcol("BMX_I")
nhanesNcol = function(tb_name){
  length(nhanesColnames(tb_name))
}


#' Column Names for NHANES tables
#'
#' @param tb_name NHANES table name
#'
#' @description Retrieve column names of an NHANES table.
#'
#' @return a character vector of non-zero length equal to the appropriate dimension.
#' @export
#'
#' @examples nhanesColnames("BMX_I")
nhanesColnames = function(tb_name){
  sql_str = paste0("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '",tb_name,"'")
  nhanesQuery(sql_str)$COLUMN_NAME
}

#' Dimensions of NHANES table
#'
#' @param tb_name NHANES table name
#'
#' @return  retrieves the dim attribute of NHANES table.
#' @export
#'
#' @examples nhanesDim("BMX_I")
nhanesDim = function(tb_name){

  c(nhanesNrow(tb_name),length(nhanesColnames(tb_name)))
}


