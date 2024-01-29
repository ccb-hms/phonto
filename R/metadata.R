meta_tables =
  c(
    T = "QuestionnaireDescriptions",
    Tables  = "QuestionnaireDescriptions",
    V = "QuestionnaireVariables",
    Variables = "QuestionnaireVariables",
    C = "VariableCodebook",
    Codebook = "VariableCodebook"
    )


#' Retrieve meta data information from the SQL database
#'
#' Retrieve NHANES medata tables, variables and codebooks.
#'
#' @param meta meta values. If meta set as \code{T} or \code{Tables}, it shows the information on NHANES tables.
#' If meta set as \code{V} or \code{Variables}, it returns the information of NHANES Variables.
#' If meta set as \code{C} or \code{Codebook}, it returns the Codebook information.
#'
#' @return dataframe containing the meta data
#' @export
#'
#' @examples metaData("T")
#' @examples metaData("Codebook")
metaData = function(meta){
  sql = paste0("SELECT * FROM ",paste0("Metadata.",meta_tables[meta]))
  nhanesQuery(sql)
}

#' Retrieve variable meta data information from Metadata.QuestionnaireVariables

#'
#' @param varList: This is a named list, the names are valid NHANES table/questionnaire names
#' and the elements are the names of variables.
#'
#' @return A named list of dataframes, the names correspond to the names from the input list
#' and the values are dataframes that contain the information in the corresponding rows
#' of the Metadata.QuestionnaireVariables table
#' @export
#'
#' @examples input = list(AA_H = c("SEQN", "WTSA2YR", "URX2NP"),
#'     DEMO=c("SEQN", "RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2", "INDFMPIR"))
#' @examples ans = variableMetaData(input)
#' @examples ans[[1]][1,]
variableMetaData = function(varList) {
  if( !is.list(varList)) stop("malformed input")

  varNames = names(varList)
  ans = vector(mode="list", length=length(varList))
  names(ans) = varNames

  for(i in 1:length(varList)) {
    sql = paste0("SELECT * FROM Metadata.QuestionnaireVariables where
        TableName = '", varNames[i], "'" )
    ans[[i]] = nhanesQuery(sql)
  }
  return(ans)
}
