---
layout: default
title: "Introduction to Continuous NHANES"
author: "Deepayan Sarkar"
editor_options: 
  chunk_output_type: console
---



The [National Health and Nutrition Examination
Survey](https://www.cdc.gov/nchs/nhanes/about_nhanes.htm) (NHANES) is
a program of the National Center for Health Statistics (NCHS), which
is part of the US Centers for Disease Control and Prevention (CDC). It
measures the health and nutritional status of adults and children in
the United States in a series of surveys that combine interviews and
physical examinations.

Although the program began in the early 1960s, its structure was
changed in the 1990s.  Since 1999, the program has been conducted on
an ongoing basis, where a nationally representative sample 
of about 5,000 persons (across 15 counties) is examined each year,
with public-use data released in two-year cycles. This phase of the
program is referred to as [continuous
NHANES](https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/).

The NHANES interview includes demographic, socioeconomic, dietary, and
health-related questions. The examination component consists of
medical, dental, and physiological measurements, as well as laboratory
tests administered by highly trained medical personnel. Although the
details of the responses recorded vary from cycle to cycle, there is a
substantial amount of consistency, making it possible to compare data
across cycles.  Sampling weights are provided along with demographic
details for each participant; see the NHANES [analytic
guidelines](https://wwwn.cdc.gov/nchs/nhanes/analyticguidelines.aspx)
for details.


# Public-use data: web resources

NHANES makes a large volume of data available for download. However,
rather than a single download, these data are made available as a
number of separate SAS transport files, referred to as "data files",
for each cycle. Each such data file contains records for several
related variables. A comprehensive list of data files available for
download is available
[here](https://wwwn.cdc.gov/Nchs/Nhanes/search/DataPage.aspx), along with
subsets broken up into the following "components": 
[Demographics](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Demographics),
[Dietary](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Dietary),
[Examination](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Examination),
[Laboratory](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Laboratory), and
[Questionnaire](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=Questionnaire).

For each data file listed in these tables, a link to a Doc File (which
is an HTML webpage describing the data file) and a link to a SAS
transport file is provided. An additional list of limited access data
files are documented
[here](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx?Component=LimitedAccess),
but the corresponding data file download links are not available.

A table of _variables_ is separately available for each component, and
gives more detailed information about both the variables and the data
files they are recorded in, although these tables do not provide
download links directly: 
[Demographics](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Demographics),
[Dietary](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Dietary),
[Examination](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Examination),
[Laboratory](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Laboratory),
[Questionnaire](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Questionnaire).

In addition, a [search interface](https://wwwn.cdc.gov/nchs/nhanes/search/) is also available.

For reasons [not
specified](https://wwwn.cdc.gov/nchs/nhanes/sasviewer.aspx), NHANES
releases data files as SAS transport files, and provides links to
proprietary Windows-only software that can supposedly be used to
convert these files to CSV files.


# Public-use data: R resources

The goal of this project is to provide and document an alternative
access path to NHANES data and documentation _via_ the R ecosystem. It
builds on the [__nhanesA__](https://cran.r-project.org/package=nhanesA) R
package, along with utilities such as SQL databases and docker, to
enable more efficient analyses of NHANES data.

## The __nhanesA__ package

The [__nhanesA__](https://github.com/cjendres1/nhanes) package provides
a user-friendly interface to download and process data and
documentation files from the NHANES website. To use the utilities in
this package, we first need to know a few more details about how
NHANES data and documentation are structured.

Each available data file, which we henceforth call an NHANES _table_,
can be identified uniquely by a name. Generally speaking, each
public-use table has a corresponding data file (a SAS transport file,
with extension `xpt`) and a corresponding documentation file (a
webpage, with extension `htm`). The URLs from which these files can be
downloaded can usually be predicted from the table name, and the
_cycle_ it belongs to. Cycles are typically of 2-year duration,
starting from `1999-2000`.

Although there are exceptions, a table that is available for one cycle
will typically be available for other cycles as well, with a suffix
appended to the name of the table indicating the cycle. To make these
details concrete, let us use the `nhanesManifest()` function in the
__nhanesA__ package to download the [list of available
tables](https://wwwn.cdc.gov/nchs/nhanes/search/datapage.aspx) and
look at the names and URLs for the `DEMO` data files, which contain
demographic information and sampling weights for each study
participant.



```r
library(nhanesA)
manifest <- nhanesManifest("public")
manifest <- manifest[order(manifest$Table), ]
subset(manifest, startsWith(Table, "DEMO"))
```

```
     Table                            DocURL                           DataURL     Years
354   DEMO   /Nchs/Nhanes/1999-2000/DEMO.htm   /Nchs/Nhanes/1999-2000/DEMO.XPT 1999-2000
353 DEMO_B /Nchs/Nhanes/2001-2002/DEMO_B.htm /Nchs/Nhanes/2001-2002/DEMO_B.XPT 2001-2002
352 DEMO_C /Nchs/Nhanes/2003-2004/DEMO_C.htm /Nchs/Nhanes/2003-2004/DEMO_C.XPT 2003-2004
350 DEMO_D /Nchs/Nhanes/2005-2006/DEMO_D.htm /Nchs/Nhanes/2005-2006/DEMO_D.XPT 2005-2006
351 DEMO_E /Nchs/Nhanes/2007-2008/DEMO_E.htm /Nchs/Nhanes/2007-2008/DEMO_E.XPT 2007-2008
355 DEMO_F /Nchs/Nhanes/2009-2010/DEMO_F.htm /Nchs/Nhanes/2009-2010/DEMO_F.XPT 2009-2010
356 DEMO_G /Nchs/Nhanes/2011-2012/DEMO_G.htm /Nchs/Nhanes/2011-2012/DEMO_G.XPT 2011-2012
357 DEMO_H /Nchs/Nhanes/2013-2014/DEMO_H.htm /Nchs/Nhanes/2013-2014/DEMO_H.XPT 2013-2014
358 DEMO_I /Nchs/Nhanes/2015-2016/DEMO_I.htm /Nchs/Nhanes/2015-2016/DEMO_I.XPT 2015-2016
359 DEMO_J /Nchs/Nhanes/2017-2018/DEMO_J.htm /Nchs/Nhanes/2017-2018/DEMO_J.XPT 2017-2018
            Date.Published
354 Updated September 2009
353 Updated September 2009
352 Updated September 2009
350 Updated September 2009
351         September 2009
355         September 2011
356   Updated January 2015
357           October 2015
358         September 2017
359          February 2020
```

The __nhanesA__ package allows both data and documentation files to be
accessed, either by specifying their URL explicitly, or simply using
the table name, in which case the relevant URL is constructed from
it. For example,


```r
demo_b <- nhanesFromURL("/Nchs/Nhanes/2001-2002/DEMO_B.XPT", translated = FALSE)
demo_c <- nhanes("DEMO_C", translated = FALSE)
```


```r
str(demo_b[1:10])
```

```
'data.frame':	11039 obs. of  10 variables:
 $ SEQN    : num  9966 9967 9968 9969 9970 ...
 $ SDDSRVYR: num  2 2 2 2 2 2 2 2 2 2 ...
 $ RIDSTATR: num  2 2 2 2 2 2 2 2 2 1 ...
 $ RIDEXMON: num  2 1 1 2 2 2 1 2 1 NA ...
 $ RIAGENDR: num  1 1 2 2 1 2 1 2 1 1 ...
 $ RIDAGEYR: num  39 23 84 51 16 14 44 63 13 80 ...
 $ RIDAGEMN: num  472 283 1011 612 200 ...
 $ RIDAGEEX: num  473 284 1012 612 200 ...
 $ RIDRETH1: num  3 4 3 3 2 2 3 1 4 3 ...
 $ RIDRETH2: num  1 2 1 1 5 5 1 3 2 1 ...
```

```r
str(demo_c[1:10])
```

```
'data.frame':	10122 obs. of  10 variables:
 $ SEQN    : int  21030 21056 21076 21126 21217 21423 21479 21546 21597 21653 ...
 $ SDDSRVYR: num  3 3 3 3 3 3 3 3 3 3 ...
 $ RIDSTATR: num  1 1 1 1 1 1 1 1 1 1 ...
 $ RIDEXMON: num  NA NA NA NA NA NA NA NA NA NA ...
 $ RIAGENDR: num  2 1 1 1 2 1 1 2 2 2 ...
 $ RIDAGEYR: num  30 36 47 4 76 23 5 2 5 0 ...
 $ RIDAGEMN: num  361 439 573 51 922 277 70 33 60 0 ...
 $ RIDAGEEX: num  NA NA NA NA NA NA NA NA NA NA ...
 $ RIDRETH1: num  3 3 4 3 3 3 5 1 3 1 ...
 $ RIDRETH2: num  1 1 2 1 1 1 4 3 1 3 ...
```

The data in these files appear as numeric codes, and must be
interpreted using codebooks available in the documentation files,
which can be parsed as follows.


```r
demo_b_codebook <-
    nhanesCodebookFromURL("/Nchs/Nhanes/2001-2002/DEMO_B.htm")
demo_b_codebook$RIDSTATR 
```

```
$`Variable Name:`
[1] "RIDSTATR"

$`SAS Label:`
[1] "Interview/Examination Status"

$`English Text:`
[1] "Interview and Examination Status of the Sample Person."

$`Target:`
[1] "Both males and females 0 YEARS -\r 150 YEARS"

$RIDSTATR
# A tibble: 3 × 5
  `Code or Value` `Value Description`               Count Cumulative `Skip to Item`
  <chr>           <chr>                             <int>      <int> <lgl>         
1 1               Interviewed Only                    562        562 NA            
2 2               Both Interviewed and MEC examined 10477      11039 NA            
3 .               Missing                               0      11039 NA            
```

```r
demo_b_codebook$RIAGENDR
```

```
$`Variable Name:`
[1] "RIAGENDR"

$`SAS Label:`
[1] "Gender"

$`English Text:`
[1] "Gender of the sample person"

$`Target:`
[1] "Both males and females 0 YEARS -\r 150 YEARS"

$RIAGENDR
# A tibble: 3 × 5
  `Code or Value` `Value Description` Count Cumulative `Skip to Item`
  <chr>           <chr>               <int>      <int> <lgl>         
1 1               Male                 5331       5331 NA            
2 2               Female               5708      11039 NA            
3 .               Missing                 0      11039 NA            
```

By default, the data access step converts the raw data into more
meaningful values using the corresponding codebook.


```r
demo_c <- nhanes("DEMO_C", translated = TRUE)
str(demo_c[1:10])
```

```
'data.frame':	10122 obs. of  10 variables:
 $ SEQN    : int  21145 21538 21829 21597 21764 21767 21848 21076 21160 21217 ...
 $ SDDSRVYR: chr  "NHANES 2003-2004 Public Release" "NHANES 2003-2004 Public Release" "NHANES 2003-2004 Public Release" "NHANES 2003-2004 Public Release" ...
 $ RIDSTATR: chr  "Interviewed Only" "Interviewed Only" "Interviewed Only" "Interviewed Only" ...
 $ RIDEXMON: chr  NA NA NA NA ...
 $ RIAGENDR: chr  "Male" "Male" "Male" "Female" ...
 $ RIDRETH1: chr  "Non-Hispanic Black" "Mexican American" "Non-Hispanic White" "Non-Hispanic White" ...
 $ RIDRETH2: chr  "Non-Hispanic Black" "Mexican American" "Non-Hispanic White" "Non-Hispanic White" ...
 $ DMQMILIT: chr  "No" "No" "Yes" NA ...
 $ DMDBORN : chr  "Born in 50 US States or Washington DC" "Born in 50 US States or Washington DC" "Born in 50 US States or Washington DC" "Born in 50 US States or Washington DC" ...
 $ DMDCITZN: chr  "Citizen by birth or naturalization" "Citizen by birth or naturalization" "Citizen by birth or naturalization" "Citizen by birth or naturalization" ...
```

Further analysis can be performed on these resulting datasets which
are regular R data frames.

Other tools that make it easier to work with these datasets by
creating a local database, or creating a search interface, are
described elsewhere. We conclude this document with a brief look at
how frequently NHANES data files are published and / or updated, based
on the information contained in the table manifest.


## Frequency of NHANES data releases

Recall from above that the NHANES table manifest includes a
`Date.Published` column.  This allows us to tabulate NHANES data
release dates. We expect that bulk releases of tables happen all
together, generally in two year intervals, while some tables may be
released or updated on a as-needed basis.

The release information (available by month of release) can be
summarized by tabulating the `Date.Published` field:

```r
xtabs(~ Date.Published, manifest) |> sort() |> tail(20)
```

```
Date.Published
           March 2008         December 2007             July 2010             June 2020 
                   12                    13                    13                    13 
 Updated October 2014             July 2022           August 2021         December 2018 
                   14                    15                    17                    17 
        November 2007         November 2021 Updated November 2020              May 2004 
                   17                    18                    19                    21 
            June 2002        September 2011          October 2015        September 2013 
                   34                    37                    38                    38 
       September 2017        September 2009         February 2020    Updated April 2022 
                   40                    41                    48                    59 
```

Parsing these dates systematically, we get


```r
pubdate <- manifest$Date.Published
updates <- startsWith(pubdate, "Updated")
datesplit <- strsplit(pubdate, split = "[[:space:]]")
datesplit[updates] <- lapply(datesplit[updates], "[", -1)
pub_summary <-
    data.frame(updated = updates,
               year = sapply(datesplit, "[[", 2) |> as.numeric(),
               month = sapply(datesplit, "[[", 1) |> factor(levels = month.name))
```

Although there are a few too many months, we can plot the number of
releases + updates by month as follows.


```r
pubfreq <- xtabs(~ interaction(month, year, sep = "-") + updated, pub_summary)
npub <- rowSums(pubfreq)
npub.date <- as.Date(paste0("01", "-", names(npub)), format = "%d-%B-%Y")
xyplot(npub ~ npub.date, type = "h", grid = TRUE,
       xlab = "Month", ylab = "Number of tables published / updated") +
    latticeExtra::layer(panel.text(x[y > 30], y[y > 30],
                                   format(x[y > 30], "%Y-%m"),
                                   pos = 3, cex = 0.75))
```

<img src="figures/nhanes-intro-bymonth-1.svg" width="100%" />


We can also plot the release / update frequency by year as follows.


```r
xtabs(~ year + updated, pub_summary) |>
    barchart(horizontal = FALSE, ylab = "Number of tables",
             auto.key = list(text = c("Original", "Update"), columns = 2),
             scales = list(x = list(rot = 45)))
```

<img src="figures/nhanes-intro-byyear-1.svg" width="100%" />

A full table of number of releases by month is given by the following,
showing that there is at least one update almost every month.


```r
pubfreq0 <- pubfreq[rowSums(pubfreq) > 0, , drop = FALSE]
pubfreq0
```

```
                                   updated
interaction(month, year, sep = "-") FALSE TRUE
                     June-2002         34    0
                     February-2003      0    1
                     September-2003     1    0
                     January-2004       5    0
                     May-2004          21    3
                     June-2004          2    0
                     July-2004         10    1
                     September-2004     5    3
                     November-2004      2    0
                     December-2004      2    0
                     January-2005       3    1
                     February-2005      4    2
                     April-2005         1    0
                     June-2005          1    3
                     August-2005        1    0
                     October-2005       0    2
                     November-2005      7    0
                     December-2005      7    1
                     January-2006       2    0
                     February-2006      6    0
                     March-2006         3    3
                     April-2006         7    6
                     May-2006           2    2
                     June-2006          6    2
                     July-2006          8    1
                     August-2006       11    7
                     September-2006     4    1
                     November-2006      1    0
                     December-2006      4    0
                     January-2007       1    2
                     February-2007      1    0
                     March-2007         1    5
                     May-2007           1    1
                     June-2007          0    2
                     July-2007          2    3
                     August-2007        0    3
                     September-2007     0    1
                     October-2007       2    3
                     November-2007     17    7
                     December-2007     13    2
                     January-2008      12    1
                     February-2008      4    0
                     March-2008        12    2
                     April-2008        12    2
                     May-2008           4    2
                     June-2008          4    3
                     July-2008          7    0
                     August-2008        1    0
                     September-2008     2    1
                     October-2008       3    0
                     December-2008      4    0
                     January-2009       2    1
                     February-2009      1    0
                     March-2009         4    0
                     April-2009         4    0
                     May-2009           1    0
                     June-2009          1    4
                     July-2009          0    5
                     August-2009        1    1
                     September-2009    41    5
                     October-2009       3    1
                     December-2009      2    3
                     January-2010       8    0
                     February-2010      1    1
                     March-2010         5    0
                     April-2010         2    5
                     May-2010           2    5
                     June-2010          3    1
                     July-2010         13    4
                     August-2010        3    2
                     September-2010     6    1
                     October-2010       1    3
                     November-2010      2    2
                     March-2011         0    1
                     April-2011         0    3
                     June-2011          3    0
                     August-2011        2    1
                     September-2011    37    6
                     October-2011       4    1
                     November-2011      1    0
                     December-2011      5    0
                     January-2012      11    5
                     February-2012      3    1
                     March-2012         1    6
                     April-2012         6    0
                     May-2012           2    0
                     June-2012         12    0
                     July-2012          2    0
                     August-2012        4    1
                     September-2012     3    1
                     October-2012       1    0
                     November-2012      2    0
                     December-2012      1    0
                     January-2013       3    1
                     February-2013      4    1
                     March-2013         2    1
                     April-2013         2    2
                     May-2013           0    9
                     June-2013          3    3
                     July-2013          5    0
                     August-2013        0    1
                     September-2013    38    0
                     October-2013       2    2
                     November-2013      8    0
                     December-2013      1    1
                     January-2014       4    0
                     February-2014      3    2
                     March-2014         7    1
                     April-2014         1    1
                     May-2014           0    1
                     June-2014          1    0
                     July-2014          4    1
                     August-2014        1    1
                     September-2014     6    1
                     October-2014       0   14
                     November-2014      1    0
                     December-2014      4    4
                     January-2015       4    2
                     February-2015      4    6
                     March-2015         1    0
                     May-2015           0    5
                     June-2015          0    2
                     July-2015          1    0
                     August-2015        1    0
                     September-2015     1    1
                     October-2015      38    5
                     November-2015      2    0
                     December-2015      3    0
                     January-2016      10    1
                     February-2016      3    0
                     March-2016         7    3
                     April-2016         4    0
                     May-2016           3    1
                     June-2016          4    0
                     July-2016          2    0
                     August-2016        4    3
                     September-2016     5    4
                     October-2016       1    2
                     November-2016      0    1
                     December-2016      6    6
                     February-2017      3    1
                     March-2017         4    3
                     April-2017         4    0
                     June-2017          1    0
                     August-2017        1    4
                     September-2017    40    3
                     October-2017       2    0
                     December-2017      6    5
                     January-2018       1    0
                     February-2018      3    1
                     March-2018         3    0
                     April-2018         5    3
                     May-2018           3    0
                     June-2018          9    0
                     July-2018          5    0
                     September-2018     5    0
                     October-2018       4    0
                     November-2018      7    1
                     December-2018     17    0
                     January-2019       6    0
                     February-2019      4    6
                     March-2019         0    2
                     April-2019         5    1
                     May-2019           5    0
                     June-2019          1    1
                     August-2019        2    0
                     September-2019     9    0
                     October-2019       0    2
                     November-2019      3    4
                     December-2019      6    3
                     January-2020       2    1
                     February-2020     48    1
                     March-2020        11    0
                     April-2020         2    1
                     May-2020           3    0
                     June-2020         13    1
                     July-2020          5    0
                     August-2020        8    1
                     October-2020       5    0
                     November-2020      7   19
                     December-2020      3    0
                     February-2021      1    1
                     March-2021         0    1
                     April-2021         7    0
                     May-2021          10    1
                     June-2021         12    1
                     July-2021          8    0
                     August-2021       17    1
                     September-2021     9    1
                     October-2021       6    0
                     November-2021     18    7
                     December-2021      4    1
                     January-2022       2    0
                     February-2022      1    6
                     March-2022         6    0
                     April-2022         1   59
                     May-2022           1    5
                     June-2022          4    0
                     July-2022         15    9
                     August-2022        5    2
                     September-2022     8    0
                     October-2022       0    2
                     November-2022      2    0
                     December-2022      0    2
                     January-2023       1    0
                     February-2023      3    0
                     March-2023         1    0
                     April-2023         1    0
                     May-2023           2    3
                     July-2023          1    0
                     September-2023     3    2
                     October-2023       0    2
                     November-2023      2    0
```


