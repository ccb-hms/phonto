
# choose the to query translated or Raw table
.tableNameConvert = function(tb_name,translated=TRUE){

  if(translated){
    tb_name = paste0("Translated.",tb_name)
  }else{
    tb_name = paste0("Raw.",tb_name)
  }
  tb_name
}


#' Query data by variable
#'
#' It search the tables contain the given variables and query data union
#' @param vars variables or phenotypes want to search
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#' @param translated whether the variables are translated
#'
#' @return union data frame
#' @export
#'
#' @examples df = queryByVars(c("URXDAZ","URXDMA"))

queryByVars = function(vars=NULL,ystart = NULL,ystop = NULL,translated=TRUE){
  if(is.null(vars) | length(vars) <1) return (NULL)
  tables = nhanesSearchVarName(vars,ystart,ystop)
  # need a try catch here
  unionQuery(tables,vars,translated)

}



#' Joint Query
#'
#' @param tables_n_cols a named list, each name corresponds to a Questionnaire and the value is a list of variable names.
#' @param translated whether the variables are translated
#'
#' @return data frame containing the join of the tables and selected variables
#' @export
#'
#' @examples df = jointQuery( list(BPQ_J=c("BPQ020", "BPQ050A"), DEMO_J=c("RIDAGEYR","RIAGENDR")))
#' @examples cols = list(DEMO_I=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
#'                      DEMO_J=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
#'                      BPQ_I=c('BPQ050A','BPQ020'),BPQ_J=c('BPQ050A','BPQ020'),
#'                      HDL_I=c("LBDHDD"),HDL_J=c("LBDHDD"), TRIGLY_I=c("LBXTR","LBDLDL"),
#'                      TRIGLY_J=c("LBXTR","LBDLDL"))
#' ans = jointQuery(cols)
#' dim(ans)
jointQuery = function(tables_n_cols,translated=TRUE){

  if(is.null(tables_n_cols) | length(tables_n_cols) <1) return (NULL)
  for (tb in names(tables_n_cols)){
    if(!tb %in% validTables){
      stop(paste0("Invalid table name: ",tb,""))
    }
  }

  names(tables_n_cols) = .tableNameConvert(names(tables_n_cols))

  cols_to_tables = list() # it won't be long and we do not know the length ahead.

  # group the data tables according to the colunms
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




  # create SEQN with years
  # want to create a sub sqls like:
  # SELECT SEQN,  BeginYear, EndYear
  # FROM (
  #   SELECT SEQN
  #   FROM DEMO_C
  # ) DEMO_C
  # JOIN Metadata.QuestionnaireDescriptions QD ON QD.TableName = 'DEMO_C'
  seqn_year = rep("", length(tables_n_cols))
  for (i in 1:length(tables_n_cols)){
    tb_name = names(tables_n_cols)[i]
    tb = unlist(strsplit(tb_name, "\\."))[2] # removed prefix, Translated. or Raw.
    temp_sql = paste0("SELECT SEQN, Year
    FROM (
        SELECT SEQN FROM ", tb_name,
        ") ", tb,
        " JOIN Metadata.QuestionnaireDescriptions QD ON QD.TableName='",tb ,"'")
    seqn_year[i] = temp_sql
  }



  sql = "WITH unifiedTB AS ("
  sql = paste0(sql, paste0(paste0(seqn_year, collapse = " UNION ALL "),"),"))


  # create union sql
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

  # tidy columns set
  final_cols = unique(unlist(tables_n_cols))
  final_cols = toString(sprintf("%s", unlist(final_cols)))
  final_cols = paste0(" DISTINCT unifiedTB.SEQN, ",final_cols,",Year AS 'Begin.Year', (Year+1) AS EndYear")

  #joint query sql
  query_sql = paste("SELECT",final_cols,"FROM unifiedTB")
  for (i in 1:length(cols_to_tables)) {
    query_sql = paste0(query_sql," LEFT JOIN ",LETTERS[i]," ON unifiedTB.SEQN=",LETTERS[i],".SEQN")
  }

  # put the sql together
  sql = paste0(sql, "
             ",query_sql)

  nhanesQuery(sql)

}


#' Union Query
#'
#' @param table_names nhanes table names
#' @param cols columns
#' @param translated whether the variables are translated
#'
#' @return data frame
#' @export
#'
#' @examples df = unionQuery(c("DEMO_B","DEMO_D"),c("RIDAGEYR","RIAGENDR"))
unionQuery= function(table_names,cols=NULL,translated=TRUE){

  if(is.null(table_names) | length(table_names) <1) return (NULL)
  for (tb in table_names){
    checkTableNames(tb)
  }
  table_names = .tableNameConvert(table_names,translated)

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


  df = nhanesQuery(sql)

  # add years colunm to the dataframe
  df["years"] = 0
  ydx = 1
  for (tn in table_names) {
    nrw = nhanesNrow(unlist(strsplit(tn,"\\."))[2])
    df[ydx:(ydx+nrw-1),"years"] = rep(unlist(.get_year_from_nh_table(tn)),nrw)
    ydx = ydx + nrw
  }

  df

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
#' @param Translated whether the table name is translated
#'
#' @return an integer of length 1
#' @export
#'
#' @examples nhanesNrow("BMX_I")
nhanesNrow = function(tb_name,translated=TRUE){
  checkTableNames(tb_name)
  tb_name = .tableNameConvert(tb_name,translated)
  sql_str = paste0("SELECT COUNT(*) FROM ",tb_name)
  nhanesQuery(sql_str)[1,1]
}


#' The Number of Columns of an NHANES table
#'
#' @param tb_name NHANES table name
#' @param translated whether the table name is translated
#'
#' @return an integer of length 1
#' @export
#'
#' @examples nhanesNcol("BMX_I")
nhanesNcol = function(tb_name,translated=TRUE){
  length(nhanesColnames(tb_name))
}


#' Column Names for NHANES tables
#'
#' @param tb_name NHANES table name
#' @param translated whether the table name is translated
#'
#' @description Retrieve column names of an NHANES table.
#'
#' @return a character vector of non-zero length equal to the appropriate dimension.
#' @export
#'
#' @examples nhanesColnames("BMX_I")
nhanesColnames = function(tb_name,translated=TRUE){
  checkTableNames(tb_name)
  sql_str = paste0("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '",tb_name,"'")
  nhanesQuery(sql_str)$COLUMN_NAME
}

#' Dimensions of NHANES table
#'
#' @param nh_table NHANES table name
#' @param translated whether the table name is translated
#'
#' @return  retrieves the dim attribute of NHANES table.
#' @export
#'
#' @examples nhanesDim("BMX_I")
nhanesDim = function(nh_table,translated=TRUE){
  checkTableNames(nh_table)
  c(nhanesNrow(nh_table),length(nhanesColnames(nh_table)))
}

#' Return the First of an NHANES table
#'
#' @param nh_table NHANES table name
#' @param n number of rows of NHANES table
#' @param translated whether the table name is translated
#'
#' @return  retrieves the First of an NHANES table
#' @export
#'
#' @examples nhanesHead("BMX_I")
#' @examples nhanesHead("BMX_I",10)
nhanesHead = function(nh_table,n=5,translated=TRUE){
  checkTableNames(nh_table)
  nh_table = .tableNameConvert(nh_table,translated)

  sql = paste0("SELECT TOP(",n, ") * FROM ",nh_table)
  nhanesQuery(sql)
}



#' Return the Last of an NHANES table
#'
#' @param nh_table NHANES table name
#' @param n number of rows of NHANES table
#' @param translated whether the table name is translated
#'
#' @return  retrieves the Last of an NHANES table
#' @export
#'
#' @examples nhanesTail("BMX_I")
#' @examples nhanesTail("BMX_I",10)
nhanesTail= function(nh_table,n=5,translated=TRUE){
  checkTableNames(nh_table)
  nh_table = .tableNameConvert(nh_table,translated)

  sql = paste0("SELECT TOP(",n, ") * FROM ",nh_table," ORDER BY SEQN DESC")
  df = nhanesQuery(sql)
  df = df[order(df$SEQN),]
  df

}



