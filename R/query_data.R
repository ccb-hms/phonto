
# inner function to convert columns for the tables
.convertColunms = function(tables_n_cols,translated){

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
  cols_to_tables
}


#' Query NHANES data from Database
#' FIXME: More information goes here.
#'
#' @param sql query string for Microsoft SQL Server database.
#'
#' @return data frame
#' @export
#'
#' @examples  demo = nhanesQuery("select * from Translated.DEMO_C")
#' @examples  demo = nhanesQuery("select * from Raw.DEMO_C")
nhanesQuery = function(sql){
  return(.nhanesQuery(sql))
}

#' Joint Query
#'
#' The jointQuery function is designed for merging and joining tables from different surveys over various years and returning the resultant data frame.
#' The primary objective of this function is to union given variables and tables from the same survey across different years, join different surveys, and return a unified data frame.
#'
#'
#'
#' @param tables_n_cols a named list, each name corresponds to a Questionnaire and the value is a list of variable names.
#' @param translated whether the variables are translated
#'
#' @return This function returns a data frame containing the joined data from the specified tables and selected variables.
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
.checkTableNames(names(tables_n_cols))
names(tables_n_cols) = .convertTranslatedTable(names(tables_n_cols),translated)
cols_to_tables = .convertColunms(tables_n_cols,translated)


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
    temp_sql = paste0("SELECT SEQN, BeginYear, EndYear
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
  final_cols = paste0(" DISTINCT unifiedTB.SEQN, ",final_cols,",BeginYear AS 'Begin.Year', EndYear")

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
#' The unionQuery function is used for merging or unifying tables from the same survey over different years and returning the resultant data frame.
#' The main goal of this function is to union given variables and tables from the same survey across different years.
#'
#' @param tables_n_cols a named list, each name corresponds to a Questionnaire and the value is a list of variable names.
#' @param translated A boolean parameter, default is TRUE. This indicates whether the variables are translated or not.
#'
#' @return data frame
#' @export
#'
#' @examples df = unionQuery( list(DEMO_I=c("RIDAGEYR","RIAGENDR"), DEMO_J=c("RIDAGEYR","RIAGENDR")))
unionQuery= function(tables_n_cols,translated=TRUE){

if(is.null(tables_n_cols) | length(tables_n_cols) <1) return (NULL)
.checkTableNames(names(tables_n_cols))
names(tables_n_cols) = .convertTranslatedTable(names(tables_n_cols),translated)
cols_to_tables = .convertColunms(tables_n_cols,translated)

 if(length(cols_to_tables)>1){
   stop("Please make sure the tables and chave the same columns")
 }

  seqn_year = rep("", length(tables_n_cols))
  for (i in 1:length(tables_n_cols)){
    tb_name = names(tables_n_cols)[i]
    tb = unlist(strsplit(tb_name, "\\."))[2] # removed prefix, Translated. or Raw.
    temp_sql = paste0("SELECT SEQN, BeginYear, EndYear
    FROM (
        SELECT SEQN FROM ", tb_name,
        ") ", tb,
        " JOIN Metadata.QuestionnaireDescriptions QD ON QD.TableName='",tb ,"'")
    seqn_year[i] = temp_sql
  }



  sql = "WITH unifiedTB AS ("
  sql = paste0(sql, paste0(paste0(seqn_year, collapse = " UNION ALL "),"),"))




 # create union sql

  # tidy columns set
cols = unique(unlist(tables_n_cols))
cols = toString(sprintf("%s", unlist(cols)))
table_names = names(tables_n_cols)
 union_sql <- paste("SELECT SEQN,",cols,
               "FROM", table_names[1])
  if(length(table_names)>=2){
    for(tl_n in table_names[2:length(table_names)]){
      union_sql = paste0(union_sql," UNION ALL SELECT SEQN,",cols ,
                   " FROM ",tl_n)
    }

  }

   # put the sql together
  sql = paste0(sql, "UTables AS (",union_sql,") ")
  final_cols = paste0(" DISTINCT unifiedTB.SEQN, ",cols,",BeginYear AS 'Begin.Year', EndYear")

  sql = paste0(sql, "SELECT ",final_cols," FROM unifiedTB LEFT JOIN UTables ON unifiedTB.SEQN=UTables.SEQN")
  nhanesQuery(sql)

}



#' Check Variable Consistency
#'
#' Compare variables between two tables and report whether they are encoded the same.
#'
#'
#' @param table1 NHANES table name 1
#' @param table2 NHANES table name 2
#'
#' @description The function extracts both tables from the database and determines the union of their column names. A matrix with three rows and one column for each entry in the union is returned.  The first row indicates whether the variable was found in the first table and similarly the second row indicates whether the variable was found in the second table.  The third row of the matrix indicates whether or not the same encoding was used in both tables.  Users will typically want to use this function before merging tables.
#'
#' @return A matrix with columns named using the union of the column names for the two tables and three rows.
#'
#' @export
#'
#' @examples checkDataConsistency("DEMO_C","DEMO_D")
checkDataConsistency = function(table1,table2){
  data1 = nhanesA::nhanes(table1)
  data2 = nhanesA::nhanes(table2)
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
      code1 = nhanesA::nhanesTranslate(table1,cols[i])
      code2 = nhanesA::nhanesTranslate(table1,cols[i])
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
  .checkTableNames(tb_name)
  sql_str = paste0("SELECT COUNT(*) FROM Raw.",tb_name)
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
#'
#' @description Retrieve column names of an NHANES table.
#'
#' @return a character vector of non-zero length equal to the appropriate dimension.
#' @export
#'
#' @examples nhanesColnames("BMX_I")
nhanesColnames = function(tb_name){
  .checkTableNames(tb_name)
  sql_str = paste0("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE
                      TABLE_SCHEMA='raw' AND
                      TABLE_NAME = '",tb_name,"'")
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
  .checkTableNames(nh_table)
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
  .checkTableNames(nh_table)
  nh_table = .convertTranslatedTable(nh_table,translated)
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
  .checkTableNames(nh_table)
  nh_table = .convertTranslatedTable(nh_table,translated)

  sql = paste0("SELECT TOP(",n, ") * FROM ",nh_table," ORDER BY SEQN DESC")
  df = nhanesQuery(sql)
  df = df[order(df$SEQN),]
  df

}

#' dataDescription
#'
#' The dataDescription function retrieves comprehensive metadata for NHANES variables from the NHANES Codebook.
#' The metadata includes English language descriptions (English Text), targeting information (Target), as well as SAS Labels,
#' to provide a high level overview of each variable.
#'
#'
#'
#' @param tables_n_cols A named list where each element represents a specific NHANES questionnaire along with a set of variables. The element names signify the questionnaire titles, and their corresponding values consist of vectors that contain the desired variables from each respective questionnaire.
#'
#'
#' @return This function returns a data frame containing metadata on the specified variables. Only unique variable names and variable descriptions are returned, i.e., if the list contains the same questionnaire/variables across different survey years, and if all metadata is consistent, then only one row for this variable will be return
#' @export
#'
#' @examples dataDescription(list(BPQ_J=c("BPQ020", "BPQ050A"), DEMO_J=c("RIDAGEYR","RIAGENDR")))
#' @examples cols = list(DEMO_I=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
#'                      DEMO_J=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
#'                      BPQ_I=c('BPQ050A','BPQ020'),BPQ_J=c('BPQ050A','BPQ020'),
#'                      HDL_I=c("LBDHDD"),HDL_J=c("LBDHDD"), TRIGLY_I=c("LBXTR","LBDLDL"),
#'                      TRIGLY_J=c("LBXTR","LBDLDL"))
#' ans = jointQuery(cols)
#' ans_description = dataDescription(cols)
#'
#'
dataDescription = function(tables_n_cols){
cols <- tables_n_cols[!duplicated(tables_n_cols)]
ls_tmp = lapply(names(cols), function(l){
  tmp_list = lapply(cols[[l]],function(cn){nhanesA::nhanesCodebook(nh_table = l, colname = cn)})
  df <- do.call(rbind, lapply(tmp_list, function(inner_list) {
    data.frame(
      #Questionnaire = l,
      VariableName = inner_list$`Variable Name:`,
      SASLabel = inner_list$`SAS Label:`,
      EnglishText = inner_list$`English Text:`,
      Target = inner_list$`Target:`
    )
  }))
})
do.call(rbind, ls_tmp)
}

