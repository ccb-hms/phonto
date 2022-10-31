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
  rownames(overlap) <- substr(rownames(overlap),1,10)
  overlap
}


#' Query data with tables and columns provided by the configuration file
#'
#' @param config configuration file path
#' @param db_file data file path
#'
#' @return data
#' @export
#'
#' @examples df <- query_joint_data("./phenotypes.json","../nhanes.sqlite")
query_joint_data <- function(config="./phenotypes.json",db_file="../nhanes.sqlite"){
  exposures <- jsonlite::read_json(config)
  nhanes_db <- DBI::dbConnect(RSQLite::SQLite(), db_file)
  cols_string = ""
  jon_string = ""
  for(tname  in names(exposures)){
    cols <- paste(tname, unlist(exposures[tname]),sep=".",collapse=", ")
    cols_string <- paste(cols_string,cols,sep=",")
    join <- paste0("INNER JOIN ", tname," ON demo.SEQN=",tname,".SEQN")
    jon_string <- paste(jon_string,join)
  }
  # building the long query string
  main_str <- paste0("SELECT demo.SEQN, RIAGENDR,RIDAGEYR,RIDRETH1,DMDEDUC2",
                     cols_string,
                     " FROM DemographicVariablesAndSampleWeights as demo",
                     jon_string,
                     " WHERE RIDAGEYR>20")
  data <- DBI::dbGetQuery(nhanes_db, main_str)
  # the following query and merge will not need when docker database got fixed.
  years <- DBI::dbGetQuery(nhanes_db, "SELECT SEQN, years from demo")
  data <- merge(data,years, by="SEQN")

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





