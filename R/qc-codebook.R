


## QC based on codebook metadata for one variable at a time. The main
## goal is to detect and report inconsistencies in a variable within
## or across cycles. By default, the variable is looked for in all
## cycles, but specific cycles may also be specified
## (QuestionnaireDescriptions has BeginYear and EndYear for each
## table)

## Metadata: fetch in advance and subset in R, because they are not
## that big, or just get for specific variable? Unless we cache,
## second option is probably better (do once inside qc_var).



.where_clause <- function(variable = NULL, table = NULL)
{
    case <- 1L + length(variable) + 2 * length(table)
    switch(case,
           "",
           sprintf("where Variable = '%s'", variable),
           sprintf("where TableName = '%s'", table),
           sprintf("where Variable = '%s' and TableName = '%s'", variable, table))
}

metadata_cb <- function(variable = NULL, table = NULL)
{
    nhanesQuery(paste("select * from Metadata.VariableCodebook",
                      .where_clause(variable, table)))
}
metadata_var <- function(variable = NULL, table = NULL)
{
    nhanesQuery(paste("select * from Metadata.QuestionnaireVariables",
                      .where_clause(variable, table)))
}
metadata_tab <- function(table = NULL)
{
    nhanesQuery(paste("select * from Metadata.QuestionnaireDescriptions",
                      .where_clause(NULL, table)))
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

qc_var_description <- function(x, var, cb, tab, ignore.case = FALSE)
{
    description <- subset(var, Variable == x)[["Description"]]
    if (ignore.case) description <- tolower(description)
    tt <- table(description)
    if (length(tt) > 1) list(description_mismatch = table(description))
    else NULL
}
    

qc_var_saslabel <- function(x, var, cb, tab, ignore.case = FALSE)
{
    saslabel <- subset(var, Variable == x)[["SasLabel"]]
    if (ignore.case) saslabel <- tolower(saslabel)
    tt <- table(saslabel)
    if (length(tt) > 1) list(saslabel_mismatch = table(saslabel))
    else NULL
}

qc_var_target <- function(x, var, cb, tab, ignore.case = FALSE)
{
    target <- subset(var, Variable == x)[["Target"]]
    if (ignore.case) target <- tolower(target)
    tt <- table(target)
    if (length(tt) > 1) list(target_mismatch = table(target))
    else NULL
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





##' QC report for a variable in NHANES
##'
##' @title qc_var: QC on NHANES variable
##' @param x Character string naming a variable in one or more NHANES tables 
##' @param var Optional data frame containing variable metadata
##' @param cb Optional data frame containing codebook metadata
##' @param tab Optional data frame containing table metadata
##' @return An object of S3 class \code{"qc_var"} with suitable print and summary methods.
##' @export
##' @author Deepayan Sarkar
qc_var <- function(x, var = metadata_var(x), cb = metadata_cb(x), tab = metadata_tab())
{
    res <- c(qc_var_multtable(x, var, cb, tab),
             qc_var_description(x, var, cb, tab),
             qc_var_saslabel(x, var, cb, tab),
             qc_var_target(x, var, cb, tab))
    if (is.null(res)) res <- list()
    structure(res,
              variable = x,
              class = "qc_var")
}

#' @rdname qc_var
#' @export
#' @param object An object of class \code{"qv_var"}
#' @param ... Additional arguments, ignored
summary.qc_var <- function(object, ...)
{
    data.frame(Variable = attr(object, "variable"),
               multtable = !is.null(object$multiple_tables),
               description = !is.null(object$description_mismatch),
               saslabel = !is.null(object$saslabel_mismatch),
               target = !is.null(object$target_mismatch))
}



#' @rdname qc_var
#' @export
print.qc_var <- function(x, ...)
{
    ok <- TRUE
    cat("Variable: ", attr(x, "variable"))
    if (!is.null(x$multiple_tables))
    {
        ok <- FALSE
        cat("\nAppears in multiple tables within same cycle:\n")
        ## wcycle <- which(duplicated(x$multiple_tables$cycle))
        ## wsub <- subset(x$multiple_tables, cycle %in% cycle[wcycle])
        tapply(x$multiple_tables, ~ cycle, function(d) paste(d$TableName, collapse = " / ")) |>
            array2DF(responseName = "Tables") |> print()
    }
    if (!is.null(x$description_mismatch))
    {
        ok <- FALSE
        cat("\nMismatch in Description:\n")
        print(array2DF(x$description_mismatch, responseName = "Frequency"))
    }
    if (!is.null(x$saslabel_mismatch))
    {
        ok <- FALSE
        cat("\nMismatch in Saslabel:\n")
        print(array2DF(x$saslabel_mismatch, responseName = "Frequency"))
    }
    if (!is.null(x$target_mismatch))
    {
        ok <- FALSE
        cat("\nMismatch in Target:\n")
        print(array2DF(x$target_mismatch, responseName = "Frequency"))
    }
    if (ok) cat(" --- no problems found")
    invisible(x)
}




if (FALSE)
{
    var <- metadata_var()
    cb <- metadata_cb()
    tab <- metadata_tab()

    qc_var("PHAFSTMN", var, cb, tab)
    qc_var("LBCBHC", var, cb, tab)
    qc_var("ENQ100", var, cb, tab)
    qc_var("LBXHCT", var, cb, tab)


    system.time({
        var <- metadata_var()
        cb <- metadata_cb()
        tab <- metadata_tab()
        qc_var("LBCBHC", var, cb, tab)
    })

    system.time(qc_var("LBCBHC"))


    qc_var("PHAFSTMN")
    qc_var("ENQ100")


    qc_var("LBCBHC")
    qc_var("LBXHCT")

    
}

