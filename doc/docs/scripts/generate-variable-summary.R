

if (basename(getwd()) != "doc/docs") stop("This script should be run in the phonto/doc/docs/ folder")

require(nhanesA)
require(phonto)
options(warn = 1)
nhanesOptions(log.access = TRUE)
stopifnot(isTRUE(nhanesOptions("use.db"))) # too slow otherwise

sort_by <- function(x, by = NULL, ...)
{
    if (!inherits(by, "formula")) stop("'by' must be a formula")
    f <- .formula2varlist(by, x)
    o <- do.call(order, c(unname(f), list(...)))
    x[o, , drop = FALSE]
}

## start with tables available in the DB
tableDesc <- nhanesQuery("select * from Metadata.QuestionnaireDescriptions")
dim(tableDesc)

## drop pre-pandemic and limited access tables
tableDesc <- subset(tableDesc, !startsWith(TableName, "P_") & UseConstraints == "None")
dim(tableDesc)



## OHXDEN_C gives error: two "Missing" values -- may want to fix somehow eventually
## https://wwwn.cdc.gov/nchs/nhanes/2003-2004/OHXDEN_C.htm#OHXIMP

tablemf <- subset(tableDesc, TableName != "OHXDEN_C")

table_summary <- function(x) {
    if (interactive()) {
        cat("\r", x); flush.console()
    }
    try(nhanesTableSummary(x, use = "both"), silent = TRUE)
}

SUMMARY_FILE <- "variable_summary.rda"
if (file.exists(SUMMARY_FILE)) {
    load(SUMMARY_FILE)
} else {
    table_details <- sapply(sort(tablemf$TableName), table_summary, simplify = FALSE)

    ## any pending errors?

    print(table(notok <- sapply(table_details, inherits, "try-error")))
    if (any(notok)) {
        print(sapply(table_details[notok], as.character))
    }

    ## combine into single data frame
    nhanesVarSummary <- do.call(rbind, table_details[!notok])
    rownames(nhanesVarSummary) <- NULL

    save(nhanesVarSummary, file = SUMMARY_FILE)
}

dim(nhanesVarSummary)

## Number of unique variables

length(unique(nhanesVarSummary$varname))

## Number of unique (varname, label) combinations

nhanesVarSummary$label <- tolower(nhanesVarSummary$label)
nrow(unique(nhanesVarSummary[c("varname", "label")]))

## Some tables have non-unique SEQN, suggesting longitudinal
## measurements.  These may be interesting, but will often have lots
## of variables representing functional data, so we will skip them for
## now

long_tables <- subset(nhanesVarSummary, varname == "SEQN" & !unique)$table
nhanesVarSummary <- subset(nhanesVarSummary, !(table %in% long_tables))

dim(unique(nhanesVarSummary[c("varname", "label")])) # ~11.6k

## add a DataGroup based on table

rownames(tableDesc) <- tableDesc$TableName
nhanesVarSummary$DataGroup <- tableDesc[nhanesVarSummary$table, "DataGroup"]

## are there any variables that go across data group?

varByDataGroup <- xtabs(~ varname + DataGroup, nhanesVarSummary)
table(numGroups <- apply(varByDataGroup, 1, function(x) sum(x > 0)))

## Hmm...

varByDataGroup[numGroups > 1, ]

## So same recorded in multiple tables, which hopefully record the
## same values. No tables are in different data groups, so this is not
## a major problem.


summarizeTable <- function(d) { # tables where variable appears
    with(d, sprintf("%s", paste(sort(table), collapse = ", ")))
}
summarizeNobs <- function(d) { # aggregate non-missing (ignoring possible dups)
    with(d, sum(nobs_data - na_data))
}
summarizeType <- function(d) { # whether numeric or categorical
    with(d, if (all(num)) "numeric"
            else if (all(cat)) sprintf("categorical [%s]",
                                       paste(unique(nlevels), collapse = ", "))
            else "ambiguous")
}

aggVarTable <- unique(nhanesVarSummary[c("varname", "label", "DataGroup")]) |>
    subset(varname != "SEQN") |> sort_by(~ varname + label + DataGroup)

aggVarTable$tables <- ""
aggVarTable$nobs <- NA_real_
aggVarTable$type <- NA_character_

for (i in seq_len(nrow(aggVarTable))) {
    if (interactive() && i %% 100 == 0) cat("\r", i, " / ", nrow(aggVarTable), "      ")
    dsub <- subset(nhanesVarSummary,
                   varname == aggVarTable$varname[[i]] &
                   label == aggVarTable$label[[i]])
    aggVarTable$tables[[i]] <- summarizeTable(dsub)
    aggVarTable$nobs[[i]] <- summarizeNobs(dsub)
    aggVarTable$type[[i]] <- summarizeType(dsub)
}

str(aggVarTable)

names(aggVarTable) <- c("Variable", "Description", "DataGroup", "Source", "Count", "Type")

require(DT)

writeTable <- function(group, out)
{
    vars <-
        DT::datatable(subset(aggVarTable, DataGroup == group),
                      rownames = FALSE,
                      escape = FALSE, editable = FALSE,
                      options = list(columnDefs = list(
                                         list("searchable" = FALSE,
                                              "targets" = c(2, 4))
                                     )))
    saveWidget(vars, file = out,
               selfcontained = FALSE, libdir = "DT")
}


writeTable("Demographics", out = "tables/variable-summary-demographics.html")
writeTable("Questionnaire", out = "tables/variable-summary-questionnaire.html")
writeTable("Examination", out = "tables/variable-summary-examination.html")
writeTable("Laboratory", out = "tables/variable-summary-laboratory.html")
writeTable("Dietary", out = "tables/variable-summary-dietary.html")



