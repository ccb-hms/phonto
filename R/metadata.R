meta_tables =
  c(
    T = "QuestionnaireDescriptions",
    Tables  = "QuestionnaireDescriptions",
    V = "QuestionnaireVariables",
    Variables = "QuestionnaireVariables",
    C = "VariableCodebook",
    Codebook = "VariableCodebook"
    )


#' Show meta data information
#'
#' It shows NAHANES medata such as, tables, variables and codebooks.
#'
#' @param meta meta values. If meta set as \code{T} or \code{Tables}, it shows the information of NHANES tables.
#' If meta set as \code{V} or \code{Variables}, it shows the information of NHANES Variables.
#' If meta set as \code{C} or \code{Codebook}, it shows the Codebook information.
#'
#' @return dataframe contains the meta data
#' @export
#'
#' @examples metaData("T")
#' @examples metaData("Codebook")
metaData = function(meta){
  sql = paste0("SELECT * FROM ",paste0("Metadata.",meta_tables[meta]))
  nhanesQuery(sql)
}

