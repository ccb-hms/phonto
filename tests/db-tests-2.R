
## Test that database interface functions in nhanesA work as expected

options(width = 80)

library(nhanesA)
stopifnot(isTRUE(nhanesOptions("use.db")))

## Selected Tables

NH_TABLES <- 
    c("DEMO", "DEMO_C", "AUXAR_J", "BPX_D", "POOLTF_E", "PCBPOL_D",
      "DRXIFF_B")


for (nhtable in NH_TABLES) {
    cat("---- ", nhtable, " (codebook)----", fill = TRUE)
    try(
    {
        d <- nhanesCodebook(nhtable)
        d <- d[sort(names(d))]
        str(d)
    })
}

for (nhtable in NH_TABLES) {
    cat("---- ", nhtable, " (raw)----", fill = TRUE)
    try(
    {
        d <- nhanes(nhtable, translated = FALSE)
        d <- d[sort(names(d))]
        str(d)
    })
}

for (nhtable in NH_TABLES) {
    cat("---- ", nhtable, " (translated)----", fill = TRUE)
    try(
    {
        d <- nhanes(nhtable, translated = FALSE)
        d <- d[sort(names(d))]
        str(d)
    })
}

