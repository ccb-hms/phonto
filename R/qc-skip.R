
## Identify questions in a table that might lead to skipping, and
## which variables are potentially skipped as a result. This will need
## to assume that the order is known, which we will take from the
## codebook (make sure that's the order in the database as well).

##' Find variables that may have been skipped based on response to a
##' previous question.
##'
##' @param table Name of a NHANES table
##' @return data frame
##' @author Deepayan Sarkar
##' @export
get_skip_info <- function(table)
{
    ## Look at codebook for a table and decide which variables may get
    ## skipped over

    var <- phonto:::metadata_var(table = "AA_H")
    cb <- phonto:::metadata_cb(table = "AA_H")

    cb <-
        nhanesQuery(sprintf("select Variable, SkipToItem from Metadata.VariableCodebook where TableName = '%s'",
                            table))

    skipvars <- subset(cb, !is.na(SkipToItem))

    ## Sanity check: non-NA values of SkipToItem should be either
    ## another variable, or "End of Section"

    uvars <- unique(cb$Variable)
    stopifnot(all(skipvars$SkipToItem %in% c(uvars, "End of Section")))

    ## For each variable, we want to know (a) if this variable _might_
    ## have been skipped based on response to a previous question, and
    ## (b) if so, which question. Part (b) can have multiple
    ## answers. For now, we will only count the number of variables
    ## that could cause such skipping, without recording what they
    ## are. Hopefully this is a good starting point; we can add more
    ## information later if necessary.

    maybe_skipped <- structure(numeric(length(uvars)), names = uvars)
    due_to <- structure(character(length(uvars)), names = uvars)

    ## Example: table = "WHQ_B"
    ##    Variable     SkipToItem
    ## 25   WHQ060        WHD080A
    ## 31   WHQ070         WHQ090
    ## 32   WHQ070         WHQ090
    ## 33   WHQ070         WHQ090
    ## 61  WHD080M End of Section
    ## 63  WHD080N End of Section
    ## 66   WHQ090         WHD110
    ## 67   WHQ090         WHD110
    ## 68   WHQ090         WHD110
    ## 96  WHD100M End of Section
    ## 98  WHD100N End of Section

    ## First map to integers
    iskipvars <- list(Variable = match(skipvars$Variable, uvars),
                      SkipToItem = match(skipvars$SkipToItem, uvars,
                                         nomatch = length(uvars) + 1L))

    ## Only those strictly in-between are potentially skipped
    for (i in seq_len(nrow(skipvars))) {
        ind <- seq(iskipvars$Variable[i] + 1L,
                   iskipvars$SkipToItem[i] - 1L)
        maybe_skipped[ind] <- maybe_skipped[ind] + 1
        due_to[ind] <- ifelse(nzchar(due_to[ind]),
                              paste(due_to[ind], skipvars$Variable[[i]], sep = ","),
                              skipvars$Variable[[i]])
    }
    data.frame(Table = table, Variable = uvars,
               MaybeSkipped = maybe_skipped > 0, SkippedDueTo = due_to,
               row.names = NULL)
}

