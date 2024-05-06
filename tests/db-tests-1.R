
## Test that backend database has essential structures

options(width = 80)

library(nhanesA)
library(phonto)
con <- nhanesA:::cn()

## allDBTables <-
##     nhanesQuery(paste("SELECT DISTINCT TABLE_NAME",
##                       "FROM INFORMATION_SCHEMA.TABLES", 
##                       "WHERE TABLE_TYPE = 'BASE TABLE' AND ", 
##                       "TABLE_CATALOG = 'NhanesLandingZone'"))

## head(allDBTables[[1]])

## For schema-based backends (SQL Server / Postgresql)

## Tables in Metadata schema 
MD <- c('"Metadata"."QuestionnaireDescriptions"',
        '"Metadata"."QuestionnaireVariables"', 
        '"Metadata"."VariableCodebook"')

## Selected Tables in Raw and Translated schemas

NH_TABLES <- 
    c("DEMO", "DEMO_C", "AUXAR_J", "BPX_D", "POOLTF_E", "PCBPOL_D",
      "DRXIFF_B")

RAW <- paste0('"Raw"."', NH_TABLES, '"')
TRANSLATED <- paste0('"Translated"."', NH_TABLES, '"')


if (attr(class(con), "package") == "RMariaDB") {
    MD <- paste0("Nhanes", MD)
    RAW <- paste0("Nhanes", RAW)
    TRANSLATED <- paste0("Nhanes", TRANSLATED)
}

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

