


## QC based on codebook metadata for one variable at a time. The main
## goal is to detect and report inconsistencies in a variable within
## or across cycles. By default, the variable is looked for in all
## cycles, but specific cycles may also be specified
## (QuestionnaireDescriptions has BeginYear and EndYear for each
## table)

## Metadata: fetch in advance and subset in R, because they are not
## that big, or just get for specific variable? Unless we cache,
## second option is probably better (do once inside qc_var).

.get_cb <- function() nhanesQuery("select * from Metadata.VariableCodebook")
.get_var <- function() nhanesQuery("select * from Metadata.QuestionnaireVariables")
.get_tab <- function() nhanesQuery("select * from Metadata.QuestionnaireDescriptions")



if (FALSE)
{
    var <- .get_var()
    cb <- .get_cb()
    tab <- .get_tab()

    qc_var("PHAFSTMN", var, cb, tab)
    qc_var("LBCBHC", var, cb, tab)
    qc_var("ENQ100", var, cb, tab)
    qc_var("LBXHCT", var, cb, tab)


}

## The specific types of discrepancies we look for are:

## - Whether appears in multiple tables in a given cycle

## If yes, should be followed up by a check of whether values are consistent

qc_var_multtable <- function(x, var, cb, tab)
{
    wtable <- subset(var, Variable == x)$TableName
    tsub <- subset(tab, TableName %in% wtable)
    cycle <- with(tsub, paste(BeginYear, EndYear, sep = "-"))
    if (anyDuplicated(cycle)) {
        o <- order(cycle, tsub$TableName)
        return(list(multiple_tables = data.frame(cycle = cycle[o],
                                                 TableName = tsub$TableName[o])))
    }
    return(NULL)
}
    


## - Inconsistency in Description / SasLabel (mostly benign)

qc_var_description <- function(x, var, cb, tab)
{
    description <- subset(var, Variable == x)[["Description"]]
    nvals <- length(unique(description))
    nvalslc <- length(unique(tolower(description)))
    if (nvals == 1L && nvalslc == 1L) return(NULL) # no problems
    if (nvalslc > 1L) return(list(description_mismatch = table(description)))
    if (nvals > 1L) return(list(description_case_mismatch = table(description)))
}
    

qc_var_saslabel <- function(x, var, cb, tab)
{
    saslabel <- subset(var, Variable == x)[["SasLabel"]]
    nvals <- length(unique(saslabel))
    nvalslc <- length(unique(trimws(tolower(saslabel))))
    if (nvals == 1L && nvalslc == 1L) return(NULL) # no problems
    if (nvalslc > 1L) return(list(saslabel_mismatch = table(saslabel)))
    if (nvals > 1L) return(list(saslabel_case_mismatch = table(saslabel)))
}
    

## - Inconsistency in type (numeric / categorical)

## - Inconsistency in levels for categorical variables (capitalization / other)

## - Presence of 'special' values in numeric variables, and
##   inconsistency in them (including different codes for same
##   value). Should have option to exclude common examples like "Don't
##   know", "Refused", etc.

## - Data coarsening (this may be tricky to identify)

## - Whether variable may be skipped. This requires preparing an
##   initial table-level summary.

## For variables appearing in multiple tables in the same cycle, an
## additional check could be to see if it records the same data. This
## should be a separate check, as it involves accessing the actual
## data.


qc_var <- function(x, var = .get_var(), cb = .get_cb(), tab = .get_tab())
{
    c(qc_var_multtable(x, var, cb, tab),
      qc_var_description(x, var, cb, tab),
      qc_var_saslabel(x, var, cb, tab))
}

