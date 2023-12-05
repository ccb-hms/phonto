
if (basename(getwd()) != "docs") stop("This script should be run in the phonto/docs/ folder")

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


str(tableDesc)
## make this a searchable table

## add TableName without cycle suffix
drop_table_suffix <- function(x) gsub("_[ABCDEFGHIJ]$", "", x)
tableDesc$TableBase <- drop_table_suffix(tableDesc$TableName)
tableDesc <- sort_by(tableDesc, ~ TableBase + TableName)

dim(unique(tableDesc[c("TableBase", "Description", "DataGroup")]))

shortDesc <- function(nh_table, do_missing = FALSE) {
    if (interactive() && runif(1) < 0.1) cat("\r", nh_table, "   ")
    cb <- nhanesCodebook(nh_table)
    nvars <- length(cb) - 1 # exclude 1st variable, which is usually ID
    ## ncases should be same regardless of which variable we pick, but not checking here.
    ## Maybe something a reimplementation of nhanesAttr() should check
    ncases <- try(tail(cb[[2]][[length(cb[[2]])]]$Cumulative, 1), silent = TRUE)
    if (inherits(ncases, "try-error")) ncases <- NA_integer_
    if (do_missing) {
        nmissing <- function(comp) {
            ## info not always available, so try
            e <- try({
                varInfoTable <- comp[[length(comp)]]
                n <- subset(varInfoTable, Value.Description == "Missing")$Count
                if (length(n) != 1L) stop("Missing values in ", nh_table, ": ", nmissing)
                n
            }, silent = TRUE)
            if (inherits(e, "try-error")) NA_integer_ else e
        }
        nmissing_by_var <- sapply(cb[-1], nmissing)
        sprintf("[%d x %d] (%g %% NA)", ncases, nvars, 
                round(100 * (sum(nmissing_by_var, na.rm = TRUE) / 
                             (ncases * sum(!is.na(nmissing_by_var)))), 1))
    }
    else
        sprintf("[%d x %d]", ncases, nvars)
}


summarizeTables <- function(tableDesc)
{
  tableSummary <- (
    xtabs(~ TableBase + Description + DataGroup, tableDesc) 
    |> as.data.frame.table() 
    |> subset(Freq > 0, select = -Freq)
  )
  subtableLinks <- function(i) {
    ## all tables matching i-th row of tableSummary
    dmatch <- 
      subset(tableDesc, 
             TableBase == tableSummary$TableBase[i] & 
               Description == tableSummary$Description[i])
    tab_links <- 
      with(dmatch, 
           {
             links <- sprintf("<a href='%s' target='_nhanes'>%s</a> %s", 
                              DocFile, TableName, ShortDesc)
             ## some have DocFile == ""
             bad_doc <- trimws(dmatch$DocFile) == ""
             links[bad_doc] <-
               sprintf("<span style='color: red;'>%s</span> %s", 
                       TableName[bad_doc], ShortDesc[bad_doc])
             paste(links, collapse = ", ")
           })
  }
  tableSummary[["Tables"]] <- sapply(seq_len(nrow(tableSummary)),
                                     subtableLinks)
  rownames(tableSummary) <- as.character(seq_len(nrow(tableSummary)))
  tableSummary
}

## This will take a little time
tableDesc <- within(tableDesc, {
    ShortDesc <- sapply(TableName, shortDesc)
})

tab_summary <- summarizeTables(tableDesc)

library(toHTML)
cat(toHTML(tab_summary), file = "tables/table-summary.html", sep = "\n")

