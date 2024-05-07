
## Test that backend database has essential structures

options(width = 80)

library(nhanesA)
library(phonto)
con <- nhanesA:::cn()

cn <- function() con

## We assume that we have three types of tables (in three schemas when
## schemas are supported): Metadata, Raw, Translated. Naming
## conventions may be different for different backends. We use
## constructor functions to determine suitably quoted identifiers.

.constructId <- function(conn, schema, table)
{
    backend <- class(conn) |> attr("package")
    switch(backend,
           odbc = sprintf('"%s"."%s"', schema, table),
           RPostgres = sprintf('"%s.%s"', schema, table),
           RMariaDB = sprintf('Nhanes%s.%s', schema, table),
           stop("Unsupported DB backend: ", backend))
}

MetadataTable <- function(x, conn = cn()) .constructId(conn, "Metadata", x)
RawTable <- function(x, conn = cn()) .constructId(conn, "Raw", x)
TranslatedTable <- function(x, conn = cn()) .constructId(conn, "Translated", x)



## allDBTables <-
##     nhanesQuery(paste("SELECT DISTINCT TABLE_NAME",
##                       "FROM INFORMATION_SCHEMA.TABLES", 
##                       "WHERE TABLE_TYPE = 'BASE TABLE' AND ", 
##                       "TABLE_CATALOG = 'NhanesLandingZone'"))

## head(allDBTables[[1]])

## For schema-based backends (SQL Server / Postgresql)

## Tables in Metadata schema 
MD <- MetadataTable(c("QuestionnaireDescriptions", "QuestionnaireVariables", "VariableCodebook"))

## Selected Tables in Raw and Translated schemas

NH_TABLES <- 
    c("DEMO", "DEMO_C", "AUXAR_J", "BPX_D", "POOLTF_E", "PCBPOL_D",
      "DRXIFF_B")

RAW <- RawTable(NH_TABLES)
TRANSLATED <- TranslatedTable(NH_TABLES)


extractTable <- function(con, dbtable) {
    sql <- sprintf("SELECT * FROM %s", dbtable)
    DBI::dbGetQuery(con, sql)
}

for (dbtable in c(MD, RAW, TRANSLATED)) {
    cat("---- ", dbtable, " ----", fill = TRUE)
    try(
    {
        d <- extractTable(con, dbtable)
        print(sort(names(d)))
        print(dim(d))
    })
}

