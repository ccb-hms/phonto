

## Manually curated list of variables that form primary keys for a
## given table. For most tables, this is SEQN.

## This list needs to be updated periodically


##' Look up primary keys for a given NHANES table
##'
##' Most NHANES tables contain a variables called SEQN that represents
##'   a participant ID, and hence can be used as a primary key for
##'   join operations. Some tables are in the long format, potentially
##'   containing multiple observations per participant, where other
##'   variables along with SEQN serve as a composite primary key. Yet
##'   other tables have no participant ID, where the primary key
##'   variable depends on the specific context. For some tables
##'   (mostly those containing dietary components codes and drug /
##'   supplement codes) the intended primary key columns are not
##'   actually unique.
##' @title primary_keys: Primary keys for NHANES table
##' @param x Character string giving name of an NHANES table
##' @param require_unique Logical; whether the likely intended primary
##'     key variables should be returned even if they do not uniquely
##'     identify rows.
##' @return Character vector giving variables that should serve as
##'     primary keys for the table. May be \code{NULL} if
##'     \code{require_unique = TRUE}.
##' @author Deepayan Sarkar
primary_keys <- function(x, require_unique = FALSE)
{
    stopifnot(length(x) == 1)
    ## For these tables, there is NO combination that can resonably
    ## serve as primary key, even though we can find a combination
    ## that almost works. These "intended" combinations are returned
    ## by the switch statement below, but here we keep the option to
    ## short-circuit that lookup and just return NULL, so that the DB
    ## doesn't try to set any primary keys.
    exceptions <-
        c("RXQANA_C", "DS1IDS_G", "DS1IDS_J", "DSQ2_B", "DSQIDS_J",
          "P_RXQ_RX", "RXQ_RX_B", "DSBI", "DS1IDS_F", "DS1IDS_I",
          "P_DS1IDS", "DS2IDS_E", "DSQIDS_G", "DSQIDS_I", "PAQIAF",
          "PAQIAF_C", "PAQIAF_D", "RXQANA_B", "DS2IDS_F", "DS2IDS_H",
          "DS2IDS_I", "DS2IDS_J", "DSQ2_C", "P_DSQIDS", "PAQIAF_B",
          "RXQ_RX_C", "RXQ_RX_D", "RXQ_RX_E", "RXQ_RX_F", "RXQ_RX_G",
          "DS1IDS_E", "DS1IDS_H", "P_DS2IDS", "DSQIDS_E", "DSQIDS_H",
          "RXQ_RX", "RXQ_RX_H", "RXQ_RX_I", "RXQ_RX_J")
    if (require_unique && x %in% exceptions) return(NULL)
    switch(x,
           ## tables which have duplicate SEQN
           ## Audiometry 
           P_AUXAR = , AUXAR_I = , AUXAR_J = c("SEQN", "RFXSEAR", "RFXLEVEL"),
           P_AUXTYM = , AUXTYM_I = , AUXTYM_J = c("SEQN", "TYXPEAR"),
           P_AUXWBR = , AUXWBR_I = , AUXWBR_J = c("SEQN", "WBXFEAR"),
           ## Diet
           P_DR1IFF = , DR1IFF_C = , DR1IFF_D = , DR1IFF_E = ,
           DR1IFF_F = , DR1IFF_G = , DR1IFF_H = , DR1IFF_I = ,
           DR1IFF_J = c("SEQN", "DR1ILINE"),
           P_DR2IFF = , DR2IFF_C = , DR2IFF_D = , DR2IFF_E = ,
           DR2IFF_F = , DR2IFF_G = , DR2IFF_H = , DR2IFF_I = ,
           DR2IFF_J = c("SEQN", "DR2ILINE"),
           DRXIFF = , DRXIFF_B = c("SEQN", "DRXILINE"),
           ## Dietary supplements
           DS1IDS_E = , DS1IDS_F = , DS1IDS_G = , DS1IDS_H = , DS1IDS_I = , 
           DS2IDS_E = , DS2IDS_F = , DS2IDS_G = , DS2IDS_H = , DS2IDS_I = , 
           DSQ2_B = , DSQ2_C = , DSQ2_D = ,
           DSQFILE2 = c("SEQN", "DSDSUPID"),
           ## Dietary supplements, but can be repeated (for multiple sources)
           DSQIDS_E = , DSQIDS_F = , DSQIDS_G = , DSQIDS_H = ,
           DSQIDS_I = c("SEQN", "DSDSUPID"),
           ## NCHS supplement id variable name changed in cycle J?
           P_DS1IDS = , P_DS2IDS = , P_DSQIDS = , DS1IDS_J = , DS2IDS_J = ,
           DSQIDS_J = c("SEQN", "DSDPID"),
           ## Miscellaneous
           FFQDC_C = , FFQDC_D = c("SEQN", "FFQ_VAR", "FFQ_FOOD"),
           PAQIAF = , PAQIAF_B = , PAQIAF_C = , PAQIAF_D = c("SEQN", "PADACTIV", "PADLEVEL"),
           PAXDAY_G = , PAXDAY_H = c("SEQN", "PAXSSNDP"),
           PAXHR_G = , PAXHR_H = c("SEQN", "PAXSSNHP"),
           P_RXQ_RX = , RXQ_RX = , RXQ_RX_B = , RXQ_RX_C = , RXQ_RX_D = , RXQ_RX_E = ,
           RXQ_RX_F = , RXQ_RX_G = , RXQ_RX_H = , RXQ_RX_I = , RXQ_RX_J = c("SEQN", "RXDDRGID"),
           RXQ_ANA = c("SEQN", "RXQ310"),
           RXQANA_B = , RXQANA_C = c("SEQN", "RXD310"),
           SSHPV_F = c("SEQN", "SSHPTYPE"),

           ## these 'pooled' tables have SAMPLEID
           BFRPOL_D = , BFRPOL_E = , BFRPOL_F = , BFRPOL_G = ,
           BFRPOL_H = , BFRPOL_I = , DOXPOL_D = , DOXPOL_E = ,
           DOXPOL_F = , DOXPOL_G = , PCBPOL_D = , PCBPOL_E = ,
           PCBPOL_F = , PCBPOL_G = , PCBPOL_H = , PCBPOL_I = ,
           PSTPOL_D = , PSTPOL_E = , PSTPOL_F = , PSTPOL_G = ,
           PSTPOL_H = , PSTPOL_I = "SAMPLEID",
           
           ## These have neither SEQN nor SAMPLEID

           P_DRXFCD = , DRXFCD_C = , DRXFCD_D = , DRXFCD_E = , DRXFCD_F = ,
           DRXFCD_G = , DRXFCD_H = , DRXFCD_I = , DRXFCD_J = "DRXFDCD",
           DRXFMT = , DRXFMT_B = "START",
           DRXMCD_C = , DRXMCD_D = , DRXMCD_E = , DRXMCD_F = , DRXMCD_G = "DRXMC",
           DSBI = c("DSDIID", "DSDBID"),
           DSII = c("DSDPID", "DSDIID"),
           DSPI = "DSDPID",
           FOODLK_C = , FOODLK_D = "FFQ_FOOD",
           PFC_POOL = c("PFCANA", "PFCRACE", "PFCGENDR", "PFCAGE", "PFCPOOL"),
           RXQ_DRUG = "RXDDRGID",
           SSBFR_B = , SSPCB_B = , SSPST_B = "POOLID",
           VARLK_C = , VARLK_D = "FFQ_VAR",

           ## default
           "SEQN")
}

