
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

# Define the schema-qualified table references
metadata_questionnaire_descriptions <- dplyr::tbl(cn(), I(MetadataTable("QuestionnaireDescriptions")))



# Get unique columns
unique_columns <- unique(unlist(tables_n_cols))

# Create a list to store unioned queries for each unique set of columns
unioned_queries <- list()

# Process each unique set of columns
for (cols in unique(tables_n_cols)) {
  # Get tables that have the same set of columns
  tables_with_cols <- names(tables_n_cols)[sapply(tables_n_cols, function(x) all(x == cols))]

  # Create a unioned query for the tables with the same set of columns
  unioned_query <- purrr::map(tables_with_cols, function(tb_name) {
    dplyr::tbl(cn(), I(tb_name)) |>
      dplyr::select(SEQN, dplyr::all_of(cols))
  }) |>
    purrr::reduce(dplyr::union_all)

  unioned_queries[[toString(cols)]] <- unioned_query
}






# Placeholder for the combined query
unifiedTB <- NULL

# Iterate over each table name and perform the union_all operation
for (tb_name in names(tables_n_cols)) {
  tb = unlist(strsplit(tb_name, "\\."))[2] # removed prefix, Translated. or Raw.
  tb = gsub("\"|\'", "", tb)
  temp_query <- dplyr::tbl(cn(), I(tb_name)) |>
    dplyr::select(SEQN) |>
    dplyr::mutate(TableName = tb) |>
    dplyr::left_join(metadata_questionnaire_descriptions, by = "TableName") |>
    dplyr::select(SEQN, BeginYear, EndYear)
  if (is.null(unifiedTB)) {
    unifiedTB <- temp_query
  } else {
    unifiedTB <- dplyr::union_all(unifiedTB, temp_query)
  }
}

# Collect the final result
unifiedTB = unifiedTB |> dplyr::distinct()


# # # # Create individual column queries
final_query = unifiedTB

for (un in unioned_queries) {
  final_query = final_query |> dplyr::left_join(un, by = "SEQN")
}


final_cols <- unique(unlist(tables_n_cols))
final_query <- final_query |>
  dplyr::select(SEQN, dplyr::all_of(final_cols), BeginYear, EndYear) |>
  dplyr::mutate('Begin.Year' = BeginYear)

final_query |> dplyr::collect() |> as.data.frame() # return data frame

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

metadata_questionnaire_descriptions <- dplyr::tbl(cn(), I(MetadataTable("QuestionnaireDescriptions")))

# Create SEQN, BeginYear, and EndYear for each table
unifiedTB = purrr::map(names(tables_n_cols), function(tb_name) {
  tb = unlist(strsplit(tb_name, "\\."))[2] # removed prefix, Translated. or Raw.
  tb = gsub("\"|\'", "", tb)
  dplyr::tbl(cn(), I(tb_name)) |>
    dplyr::select(SEQN) |>
    dplyr::mutate(TableName = tb) |>
    dplyr::left_join(metadata_questionnaire_descriptions, by = "TableName") |>
    dplyr::select(SEQN, BeginYear, EndYear)
}) |> purrr::reduce(dplyr::union_all) |>  dplyr::distinct()

# Union all tables with the same columns
unioned_query = purrr::map(names(tables_n_cols), function(tb_name) {
  dplyr::tbl(cn(), I(tb_name)) |>
    dplyr::select(SEQN, dplyr::all_of(unique(unlist(tables_n_cols))))
}) |>
  purrr::reduce(dplyr::union_all)
# print(unioned_query)

# Join with unifiedTB to get the final result
final_query = unifiedTB |>
  dplyr::left_join(unioned_query, by = "SEQN")

# Collect the results into a data frame
final_query |> dplyr::collect() |> as.data.frame()

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
  dplyr::tbl(cn(), I(RawTable(tb_name))) |> dplyr::collect() |> nrow()
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
  dplyr::tbl(cn(), I(RawTable(tb_name))) |> dplyr::collect() |> ncol()
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
  dplyr::tbl(cn(), I(RawTable(tb_name))) |> colnames()
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
  dplyr::tbl(cn(), I(RawTable(nh_table))) |> dim()
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
  dplyr::tbl(cn(), I(nh_table)) |> dplyr::collect() |> head(n)
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
  dplyr::tbl(cn(), I(nh_table)) |> dplyr::collect() |> tail(n)

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

