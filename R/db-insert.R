### FIXME: Review for proper quoting of table and variable names
### (remember Bobby Tables)


### Tools to support creation of database to be included in
### Epiconductor docker image. Main steps (assuming postgresql):

## 1. Create database NhanesLandingZone

## 2. create schema Metadata; create schema Raw; create schema Translated;

## 3. Fill in Metadata.QuestionnaireVariables,
##    Metadata.VariableCodebook, possibly using insertTableDB(). These
##    are required to create the codebook for translations (unless we
##    want to download on the fly). Do we need support functions for
##    these?

## 4. Fill in Raw.* and Translated.* tables in a loop


##' Declare one or more non-null columns to be primary key
##'
##' Declare one or more columns in an existing database table to be
##' primary key(s). Requires that the corresponding variables be
##' already defined as non-null.
##' @rdname insertTableDB
##' @param columns Character vector, giving names of one or more columns in the table
##' @author Deepayan Sarkar
##' @export

addPrimaryKey <- function(con, table, columns)
{
    qcol <- DBI::dbQuoteIdentifier(con, columns)
    sql <- sprintf("ALTER TABLE %s ADD PRIMARY KEY (%s);",
                   table,
                   paste0(qcol, collapse = ", "))
    query <- DBI::SQL(sql)
    dbExecute(con, query)
}



## First version from is.wholenumber in example(as.integer)
## isWholeNumber <- function(x, tol = .Machine$double.eps^0.5) all(abs(x - round(x)) < tol)

## But this one is faster and should be OK for NHANES data
isWholeNumber <- function(x) {
    keep <- !is.na(x)
    isTRUE(all(x[keep] == as.integer(x[keep])))
}



##' General purpose DB table insertion
##'
##' Try to insert an R data frame into an existing database with a
##' user-specified table name. Assumes that a table with this name
##' does not already exist.
##' @title insertTableDB: Insert data frame in database
##' @param con An open database connection
##' @param data 
##' @param table Character giving the name of a table. 
##' @param check_integer 
##' @param non_null 
##' @param make_primary_key 
##' @author Deepayan Sarkar
##' @export
insertTableDB <-
    function(con, data, table,
             check_integer = TRUE,
             non_null = NULL,
             make_primary_key = FALSE)
{
    dcols <- names(data)
    if (isTRUE(check_integer)) {
        for (v in dcols) {
            if (isWholeNumber(data[[v]]))
                data[[v]] <- as.integer(data[[v]])
        }
    }
    qtable <- DBI::dbQuoteIdentifier(con, table)
    dtype <- DBI::dbDataType(con, data)
    if (!is.null(non_null)) {
        if (!all(non_null %in% dcols)) {
            stop("Columns specified as non-null do not exists in data:",
                  non_null[!(non_null %in% dcols)] |> paste(collapse = ", "))
        }
        dtype[non_null] <- paste0(dtype[non_null], " NOT NULL")
    }
    DBI::dbCreateTable(con, table, dtype)
    if (isTRUE(make_primary_key)) {
        ## Even if make_primary_key = TRUE, check that the columns
        ## actually uniquely identify rows. This will require some
        ## extra checking, but saves the user from checking
        if (!anyDuplicated(data[non_null]))
            addPrimaryKey(con, qtable, columns = non_null)
    }
    DBI::dbAppendTable(con, table, data)
}


## FIXME: review for the correctness w.r.t. schema 
dbTableNameFromNHANES <- function(x, type = c("raw", "translated"))
{
    type <- match.arg(type)
    switch(type,
           raw = paste0("Raw.", x),
           translated = paste0("Translated.", x))
}

## Simplified reimplentation of nhanesA::nhanesCodebook() to bypass nhanesA

.dbqTableVars <- paste0(
    "SELECT ",
    "Variable AS 'Variable Name:', ",
    "SasLabel AS 'SAS Label:', ",
    "Description AS 'English Text:', ",
    "Target AS 'Target:' ",
    "FROM Metadata.QuestionnaireVariables ",
    "WHERE TableName = '%s'"
)

.dbqTableCodebook <- paste0(
    "SELECT ",
    "Variable, ",
    "CodeOrValue AS 'Code.or.Value', ",
    "ValueDescription AS 'Value.Description', ",
    "Count, ",
    "Cumulative, ",
    "SkipToItem AS 'Skip.to.Item' ",
    "FROM Metadata.VariableCodebook ",
    "WHERE TableName = '%s'"
)

.codebookFromDB <- function(table)
{
    tvars <- .nhanesQuery(sprintf(.dbqTableVars, table))
    tcb <- .nhanesQuery(sprintf(.dbqTableCodebook, table))
    tcb_list <- split(tcb[-1], tcb$Variable)
    cb <- split(tvars, ~ `Variable Name:`) |> lapply(as.list)
    vnames <- names(cb)
    for (i in seq_along(cb)) {
        iname <- vnames[[i]]
        cb[[i]][[iname]] <- tcb_list[[iname]]
    }
    cb
}

.translateNhData <- function(data, codebook, cleanse_numeric = FALSE)
{
    nhanesA:::raw2translated(data, codebook, 
                             cleanse_numeric = cleanse_numeric)
}


##' Insert NHANES table into a database
##'
##' Inserts an NHANES table into a database using the DBI
##' interface. Requires and active database connection, and assumes
##' that a table with this name does not already exist.
##' @param con An open database connection
##' @param x Character giving the name of an NHANES table
##' @param data Data frame. If unspecified, obtained from \code{x}
##'     using \code{\link[pkg:nhanesA]{nhanes}}.
##' @param type Character, whether to insert raw data, translated, or
##'     both.
##' @param codebook The variable codebooks for this table, as returned
##'     by \code{\link[pkg:nhanesA]{nhanesCodebook}}
##' @param make_primary_key Logical flag, whether suitable variables
##'     (usually \code{SEQN}) should be declared as primary keys.
##' @param check_integer Logical flag, whether numeric variables that
##'     are all whole numbers should be stored as integer rather than
##'     float / double.
##' @param cleanse_numeric Logical flag, indicating whether some some
##'     special values for numeric variables should be converted to
##'     missing values. TODO more details.
##' @author Deepayan Sarkar
##' @export

dbInsertNhanesTable <-
    function(con, x, data = nhanes(x, translated = FALSE),
             type = c("raw", "translated", "both"),
             codebook = .codebookFromDB(x),
             make_primary_key = TRUE,
             check_integer = TRUE,
             cleanse_numeric = TRUE)
{
    type <- match.arg(type)
    pk <- if (isTRUE(make_primary_key)) 
              primary_keys(x, require_unique = FALSE)
          else NULL
    if (type %in% c("raw", "both")) {
        target <- dbTableNameFromNHANES(x, type = c("raw", "translated"))
        insertTableDB(con = con, data = data, table = target,
                      check_integer = check_integer,
                      non_null = pk,
                      make_primary_key = make_primary_key)
    }
    if (type %in% c("translated", "both")) {
        target <- dbTableNameFromNHANES(x, type = c("raw", "translated"))
        insertTableDB(con = con,
                      data = .translateNhData(data, codebook,
                                              cleanse_numeric = cleanse_numeric),
                      table = target,
                      check_integer = check_integer,
                      non_null = pk,
                      make_primary_key = make_primary_key)
    }
    invisible()
}



