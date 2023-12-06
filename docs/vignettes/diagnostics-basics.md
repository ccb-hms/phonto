---
layout: default
title: "Diagnostics: Part 1"
editor_options: 
  chunk_output_type: console
---





NHANES is a large project, and while the data distribution strategy
employed by CDC works quite well overall, inconsistencies do creep
in. This document describes a series of diagnostic checks, enabled by
the local SQL database, to identify possible issues.


## Cross check tables with NHANES master list

The NHANES website contains a [master
list](https://wwwn.cdc.gov/Nchs/Nhanes/search/DataPage.aspx) of
available. This can be downloaded and parsed via the
`nhanesManifest()` function in the __nhanesA__ package.  Here we use
an alternative Python approach that does essentially the same thing.

First, we download and save this table as a CSV file using Python...


```python
from bs4 import BeautifulSoup
import requests

## extraction functions for td elements
def etext(obj): return obj.get_text().strip()
def eurl(obj): return obj.find('a').get_attribute_list('href')[0]

url = 'https://wwwn.cdc.gov/Nchs/Nhanes/search/DataPage.aspx'

source_html = requests.get(url).content.decode('utf-8')
soup = BeautifulSoup(source_html, 'html.parser')

_table = soup.find('table', {'id' : 'GridView1'}) 

f = open('table_manifest.csv', 'w')
f.write("Table,Years,PubDate,DocURL,DataURL\n")
```

```python
for row in _table.tbody.find_all('tr'):
    [year, docfile, datafile, pubdate] = row.find_all('td')
    if etext(pubdate) != 'Withdrawn':
        f.write("%s,%s,%s,https://wwwn.cdc.gov%s,https://wwwn.cdc.gov%s\n" % 
                    (etext(docfile).split()[0], 
                     etext(year), 
                     etext(pubdate),
                     eurl(docfile),
                     eurl(datafile)))
```

```python
f.close()
```

...and then read this file in using R.


```r
manifest <- read.csv("table_manifest.csv")
str(manifest)
```

```
'data.frame':	1514 obs. of  5 variables:
 $ Table  : chr  "ACQ_D" "ACQ_E" "ACQ" "ACQ_C" ...
 $ Years  : chr  "2005-2006" "2007-2008" "1999-2000" "2003-2004" ...
 $ PubDate: chr  "March 2008" "September 2009" "June 2002" "April 2006" ...
 $ DocURL : chr  "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/ACQ_D.htm" "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/ACQ_E.htm" "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/ACQ.htm" "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/ACQ_C.htm" ...
 $ DataURL: chr  "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/ACQ_D.XPT" "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/ACQ_E.XPT" "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/ACQ.XPT" "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/ACQ_C.XPT" ...
```

```r
## Some weird URLs to fix up
subset(manifest, grepl("cdc.gov../", DocURL, fixed = TRUE) |
                 grepl("cdc.gov../", DataURL, fixed = TRUE))
```

```
     Table     Years              PubDate                                                                          DocURL
1448 VID_B 2001-2002 Updated October 2015 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=htm
1449 VID_C 2003-2004 Updated October 2015 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=htm
1450 VID_D 2005-2006 Updated October 2015 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=htm
1451 VID_E 2007-2008         October 2015 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=htm
1452 VID_F 2009-2010         October 2015 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=htm
                                                                             DataURL
1448 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=XPT
1449 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=XPT
1450 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=XPT
1451 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=XPT
1452 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=XPT
```

```r
manifest <- within(manifest, {
  DocURL <- gsub("cdc.gov../", "cdc.gov/Nchs/Nhanes/", DocURL, fixed = TRUE)
  DataURL <- gsub("cdc.gov../", "cdc.gov/Nchs/Nhanes/", DataURL, fixed = TRUE)
})
```

We start by looking at the file extensions of the URLs.


```r
with(manifest, table(tools::file_ext(DocURL)))   # doc file extensions
```

```

     aspx  htm 
   5    2 1507 
```

```r
with(manifest, table(tools::file_ext(DataURL)))  # data file extensions
```

```

     aspx  xpt  XPT  ZIP 
   9    2    3 1495    5 
```

and whether there are any duplicated table names.


```r
with(manifest, Table[duplicated(Table)])         # uniqueness of table names
```

```
[1] "All"
```

The `aspx` files and duplicated table name comes from additional
details specific to missingness in DXA and OMB tables (see links
below). Note that __nhanesA__ handles "DXA" specially, e.g., via
`nhanesA::nhanesDXA()`, but not OMB, and the database version has
neither.



```r
subset(manifest, Table == "All")
```

```
     Table     Years               PubDate                                            DocURL                                           DataURL
554    All 1999-2006 Updated December 2016     https://wwwn.cdc.gov/Nchs/Nhanes/Dxa/Dxa.aspx     https://wwwn.cdc.gov/Nchs/Nhanes/Dxa/Dxa.aspx
1053   All 2009-2012          October 2022 https://wwwn.cdc.gov/Nchs/Nhanes/Omp/Default.aspx https://wwwn.cdc.gov/Nchs/Nhanes/Omp/Default.aspx
```

We will simply skip these two entries.


```r
manifest <- subset(manifest, Table != "All")
```

The ZIP extensions are from


```r
subset(manifest, tolower(tools::file_ext(DataURL)) == "zip")
```

```
        Table     Years               PubDate                                                  DocURL                                                 DataURL
1157 PAXRAW_D 2005-2006             June 2008 https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.htm https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.ZIP
1158 PAXRAW_C 2003-2004 Updated December 2007 https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.htm https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.ZIP
1355 SPXRAW_E 2007-2008         December 2011 https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.htm https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.ZIP
1356 SPXRAW_F 2009-2010         December 2011 https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.htm https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.ZIP
1357 SPXRAW_G 2011-2012         December 2014 https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.htm https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.ZIP
```

These are very large files, with multiple entries per subject storing 
minute-by-minute results recorded in a physical activity monitoring device. 
These data are not included in the database (and probably should not be), but 
we will retain these rows to remind us that the tables exist.



Next, we check if any of these tables are missing from the table
metadata in the database.



```r
library(nhanesA)
library(phonto)
dbTableDesc <- nhanesQuery("select * from Metadata.QuestionnaireDescriptions")
setdiff(manifest$Table, dbTableDesc$TableName) # missing from DB
```

```
  [1] "P_ACQ"    "P_ALB_CR" "P_ALQ"    "SSAGP_I"  "SSAGP_J"  "P_UTAS"   "P_UAS"    "P_AUQ"    "P_AUX"    "AUXAR_I"  "P_AUXAR"  "P_AUXTYM" "P_AUXWBR" "SSDFS_A"  "SSANA_A"  "SSANA2_A" "P_BPXO"  
 [18] "P_BPQ"    "P_BMX"    "P_CDQ"    "CHLMDA_F" "CHLMDA_G" "CHLMDA_H" "CHLMDA_I" "LAB05"    "CHLMDA_D" "L05_C"    "L05_B"    "CHLMDA_E" "SSCT_H"   "SSCT_I"   "P_HDL"    "P_TRIGLY" "P_TCHOL" 
 [35] "P_UCM"    "P_CRCO"   "P_CBC"    "P_CBQPFA" "P_CBQPFC" "P_COT"    "P_HSQ"    "SSCMVG_A" "P_CMV"    "SSUCSH_A" "P_DEMO"   "P_DEQ"    "P_DIQ"    "P_DBQ"    "P_DR1IFF" "P_DR2IFF" "P_DR1TOT"
 [52] "P_DR2TOT" "DRXFMT"   "DRXFMT_B" "DRXFCD_I" "DRXFCD_J" "P_DRXFCD" "DSBI"     "DSII"     "DSPI"     "P_DS1IDS" "P_DS2IDS" "P_DS1TOT" "P_DS2TOT" "P_DSQIDS" "P_DSQTOT" "P_DXXFEM" "P_DXXSPN"
 [69] "P_ECQ"    "P_ETHOX"  "P_FASTQX" "P_FERTIN" "P_FR"     "P_FOLATE" "P_FOLFMS" "FOODLK_C" "FOODLK_D" "VARLK_C"  "VARLK_D"  "P_FSQ"    "SSCARD_A" "P_GHB"    "SSGLYP_J" "P_HIQ"    "P_HEQ"   
 [86] "P_HEPA"   "P_HEPB_S" "P_HEPBD"  "SSHCV_E"  "P_HEPC"   "P_HEPE"   "SSTROP_A" "P_HSCRP"  "P_HUQ"    "P_IMQ"    "P_INQ"    "P_IHGEM"  "P_INS"    "P_UIO"    "P_FETIB"  "P_KIQ_U"  "P_PBCD"  
[103] "P_LUX"    "P_MCQ"    "P_DPQ"    "P_UHG"    "P_UM"     "P_UNI"    "SSBNP_A"  "P_OCQ"    "P_OHQ"    "P_OHXDEN" "P_OHXREF" "P_OPD"    "P_OSQ"    "P_PERNT"  "P_PUQMEC" "P_PAQ"    "P_PAQY"  
[120] "PAXRAW_D" "PAXRAW_C" "PAXLUX_G" "PAXLUX_H" "PAXHR_H"  "PAXMIN_G" "PAXMIN_H" "PAX80_G"  "PAX80_H"  "P_GLU"    "PAHS_G"   "PAHS_I"   "PFC_POOL" "POOLTF_D" "POOLTF_E" "P_RXQ_RX" "RXQ_DRUG"
[137] "P_RXQASA" "P_RHQ"    "P_SLQ"    "P_SMQ"    "P_SMQFAM" "P_SMQRTU" "P_SMQSHS" "SPXRAW_E" "SPXRAW_F" "SPXRAW_G" "P_BIOPRO" "SSNH4THY" "P_TFR"    "P_UCFLOW" "P_UCPREG" "VID_B"    "VID_C"   
[154] "VID_D"    "VID_E"    "VID_F"    "VID_G"    "VID_H"    "VID_I"    "VID_J"    "P_UVOC"   "P_UVOC2"  "P_VOCWB"  "P_VTQ"    "P_WHQ"    "P_WHQMEC"
```

```r
setdiff(dbTableDesc$TableName, manifest$Table) # and the other way
```

```
character(0)
```

If we exclude the pre-pandemic tables, we are left with 


```r
options(width = 80)
mtabs <- setdiff(manifest$Table, dbTableDesc$TableName) |>
             grep(pattern = "^P_", invert = TRUE, value = TRUE)
mtabs
```

```
 [1] "SSAGP_I"  "SSAGP_J"  "AUXAR_I"  "SSDFS_A"  "SSANA_A"  "SSANA2_A"
 [7] "CHLMDA_F" "CHLMDA_G" "CHLMDA_H" "CHLMDA_I" "LAB05"    "CHLMDA_D"
[13] "L05_C"    "L05_B"    "CHLMDA_E" "SSCT_H"   "SSCT_I"   "SSCMVG_A"
[19] "SSUCSH_A" "DRXFMT"   "DRXFMT_B" "DRXFCD_I" "DRXFCD_J" "DSBI"    
[25] "DSII"     "DSPI"     "FOODLK_C" "FOODLK_D" "VARLK_C"  "VARLK_D" 
[31] "SSCARD_A" "SSGLYP_J" "SSHCV_E"  "SSTROP_A" "SSBNP_A"  "PAXRAW_D"
[37] "PAXRAW_C" "PAXLUX_G" "PAXLUX_H" "PAXHR_H"  "PAXMIN_G" "PAXMIN_H"
[43] "PAX80_G"  "PAX80_H"  "PAHS_G"   "PAHS_I"   "PFC_POOL" "POOLTF_D"
[49] "POOLTF_E" "RXQ_DRUG" "SPXRAW_E" "SPXRAW_F" "SPXRAW_G" "SSNH4THY"
[55] "VID_B"    "VID_C"    "VID_D"    "VID_E"    "VID_F"    "VID_G"   
[61] "VID_H"    "VID_I"    "VID_J"   
```

Ideally, this should match the list of excluded tables given by.


```r
nhanesQuery("select * from Metadata.ExcludedTables")
```

```
   TableName         Reason
1  All Years     Large File
2       PAHS     Large File
3      PAX80       FTP Only
4     PAXLUX         Broken
5     ALQYTH         Broken
6        OMP         Broken
7        VID         Broken
8       SSCT         Broken
9     SPXRAW Limited Access
10    PAXRAW Limited Access
11    CHLMDA Limited Access
12      CHLA Limited Access
13      CHLM Limited Access
14     LAB05 Limited Access
15       L05 Limited Access
16    PAXMIN Limited Access
```

The following links can be used to explore the documentation of these
missing tables in the NHANES website.


```r
paste0("- <", subset(manifest, Table %in% mtabs)$DocURL, ">") |>
    cat(sep = "\n")
```

- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/SSAGP_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/SSAGP_J.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/AUXAR_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSDFS_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSANA_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSANA2_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/CHLMDA_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/CHLMDA_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/CHLMDA_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/CHLMDA_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB05.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/CHLMDA_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L05_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L05_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/CHLMDA_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/SSCT_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/SSCT_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSCMVG_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSUCSH_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/DRXFMT.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/DRXFMT_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DRXFCD_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/DRXFCD_J.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/DSBI.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/DSII.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/DSPI.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/FOODLK_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/FOODLK_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/VARLK_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/VARLK_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSCARD_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/SSGLYP_J.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SSHCV_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSTROP_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/SSBNP_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXLUX_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXLUX_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXHR_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXMIN_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXMIN_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAX80_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAX80_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAHS_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/PAHS_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/PFC_POOL.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/POOLTF_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/POOLTF_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/RXQ_DRUG.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/SSNH4THY.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/VID_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/VID_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/VID_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/VID_J.htm>




## Missing documentation

We check here for tables in the current metadata that do not have a
URL.


```r
subset(dbTableDesc, !startsWith(DocFile, "https"),
       select = c(TableName, DocFile, DataFile))
```

```
     TableName DocFile DataFile
37     L11_2_B                 
39      PBCD_D                 
40      PBCD_E                 
41      PBCD_F                 
56       L13_C                 
149      LAB02                 
162      L09_C                 
204      IHG_D                 
286   L11P_2_B                 
354     APOB_F                 
372      L34_B                 
373      L34_C                 
387     PBCD_G                 
396      LAB13                 
404    L25_2_B                 
563      IHG_E                 
564      IHG_F                 
699     APOB_E                 
700     APOB_G                 
742      L13_B                 
814    L39_2_B                 
841   L02HPA_A                 
853      L09_B                 
1050    APOB_H                 
1097   L13_2_B                 
1192     LAB09                 
1226   IHGEM_G                 
1265   L26PP_B                 
```

The corresponding documentation links from the online manifest are
given below.


```r
mdoc <- subset(dbTableDesc, !startsWith(DocFile, "https"))$TableName
paste0("- <", subset(manifest, Table %in% mdoc)$DocURL, ">") |>
    cat(sep = "\n")
```

- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/APOB_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/APOB_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/APOB_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/APOB_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L34_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L34_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PBCD_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/PBCD_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/PBCD_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PBCD_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB13.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L13_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L13_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L13_2_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L25_2_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11_2_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L39_2_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/L02HPA_A.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB02.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB09.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L09_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L09_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/IHG_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/IHG_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/IHG_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/IHGEM_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L26PP_B.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11P_2_B.htm>

We end with a couple of sanity checks for the URLs that are _not_ missing.


```r
manifest_doc_url <- with(manifest, structure(DocURL, names = Table))
manifest_data_url <- with(manifest, structure(DataURL, names = Table))
metadata_doc_url <- with(subset(dbTableDesc, DocFile != ""),
                         structure(DocFile, names = TableName))
metadata_data_url <- with(subset(dbTableDesc, DataFile != ""),
                          structure(DataFile, names = TableName))
```

If not missing, doc / data URLs in the metadata should match those in the manifest.


```r
all(metadata_doc_url == manifest_doc_url[names(metadata_doc_url)])
```

```
[1] TRUE
```

```r
all(metadata_data_url == manifest_data_url[names(metadata_data_url)])
```

```
[1] TRUE
```





