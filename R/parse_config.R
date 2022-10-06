#' Read configuration information for the table
#'
#' @param table_name table name
#'
#' @return parsed json file contented or NULL
#' @export
#'
#' @examples read_conf("DEMO_I")
#' @examples read_conf(table_name="DEMO_I")
read_conf <- function(table_name="DEMO_I"){
  tab <- unlist(strsplit(table_name,"_"))[1]
  cfg_file <- paste0("config/",tab,".json")
  res <- NULL
  if (tab=="" | !file.exists(cfg_file)){
    print(paste0("No configeration file can be found for table ",table_name,"!"))

  }else{
    res <- jsonlite::fromJSON(cfg_file)

  }

  res

}
