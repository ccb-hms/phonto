
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



#' Check overlap cohorts over the years
#' In the following matrix, 0 means the tables have no data in that year, and 1 means they have data in corresponding years.
#'
#' @param config configuration file path
#' @param db_file data file path
#'
#' @return show the matrix
#' @export
#'
#' @examples check_data(config="./phenotypes.json",db_file="../nhanes.sqlite")
check_data <- function(config="./phenotypes.json",db_file="../nhanes.sqlite"){
  exposures <- jsonlite::read_json(config)
  nhanes_db <- DBI::dbConnect(RSQLite::SQLite(), db_file)

  demo <- DBI::dbGetQuery(nhanes_db, "SELECT years from demo")
  overlap <- matrix(0,nrow = length(exposures),ncol = length(unique(demo$years)))
  colnames(overlap) <- unique(demo$years)
  rownames(overlap) <- names(exposures)
  for(tname  in names(exposures)){
    sql_string <- paste0("SELECT years from demo inner join ", tname, " on demo.SEQN=",tname,".SEQN")
    temp = DBI::dbGetQuery(nhanes_db, sql_string)
    overlap[rownames(overlap)==tname,names(table(temp))]<-1
  }
  DBI::dbDisconnect(nhanes_db)
  # rownames(overlap) <- substr(rownames(overlap),1,10)
  overlap
}


#' Query data with tables and columns provided by the configuration file
#'
#' @param config configuration file path
#' @param db_file data file path
#' @param na.keep all rows with NA values are remove when set as FALSE,
#'
#' @return data
#' @export
#'
#' @examples df <- query_joint_data("./phenotypes.json","../nhanes.sqlite")
query_data <-
  function(config = "./phenotypes.json",
           db_file = "./nhanes.sqlite",
           na.keep = TRUE) {
    exposures <- jsonlite::read_json(config)
    nhanes_db <- DBI::dbConnect(RSQLite::SQLite(), db_file)
    tbl1 <- names(exposures)[1]
    select_string  <- ""
    if(unlist(exposures[tbl1])[1]=="*"){
      select_string <- paste0("SELECT ",tbl1,".*")
    }else{
      select_string <- paste0("SELECT ",
                              tbl1,
                              ".SEQN, ",
                              paste(
                                tbl1,
                                unlist(exposures[[1]]),
                                sep = ".",
                                collapse = ", "
                              ))
    }

    join_string <- ""
    for (tname  in names(exposures)[2:length(exposures)]) {
      cols <-
        paste(tname,
              unlist(exposures[tname]),
              sep = ".",
              collapse = ", ")
      select_string <- paste(select_string, cols, sep = ", ")
      join <-
        paste0("INNER JOIN ", tname, " ON ", tbl1, ".SEQN=", tname, ".SEQN")
      join_string <- paste(join_string, join)
    }
    # not_null <- ""
    # if (!na.keep) {
    #   not_null <-
    #     paste0("WHERE ",
    #            paste(unlist(exposures), collapse = " IS NOT NULL AND "),
    #            " IS NOT NULL")
    # }
    #
    # sql_str <- paste(select_string, "FROM", tbl1, join_string, not_null)

    sql_str <- paste(select_string, "FROM", tbl1,join_string)

    data <- DBI::dbGetQuery(nhanes_db, sql_str)
    if(!na.keep){
      data <- na.omit(data)
    }

    DBI::dbDisconnect(nhanes_db)
    data
  }


#' Create data frame shows the variable
#'
#' @param phs_types the data types assigned to phenotype by the phseant function
#' @param dsc_config search tables
#'
#' @return results data frame
#' @export
#'
#' @examples function(phs_types,dsc_config)
phseant_table <- function(phs_types,dsc_config){

  phs_types <- phs_types[! names(phs_types) %in% c('SEQN','years')]

  exposures <- jsonlite::read_json(dsc_config)
  desc_df <- matrix(ncol = 2, nrow = 0)
  for(tn in names(exposures)){
    values <- unlist(exposures[tn])
    des <- nhanesA::nhanesTableVars(values[1], values[2])
    des <- des[des$Variable.Name!="SEQN",]
    desc_df <- rbind(desc_df,des)
  }

  desc_df <- desc_df[!duplicated(desc_df$Variable.Name),]
  desc_df <- desc_df[desc_df$Variable.Name %in% names(phs_types),]

  colnames(desc_df) <- c("Variable","Description")
  phs_df <- data.frame(Variable=names(phs_types),PHSEANT=phs_types)
  desc_df <- merge(desc_df,phs_df,by="Variable")
  desc_df <- desc_df[,c("Variable","PHSEANT","Description")]

  rownames(desc_df) <- 1:nrow(desc_df)
  desc_df

}





