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


## Version information


```r
Sys.getenv("EPICONDUCTOR_CONTAINER_VERSION")
```

```
[1] "v0.4.1"
```

```r
print(sessionInfo(), locale = FALSE)
```

```
R Under development (unstable) (2024-01-02 r85758)
Platform: x86_64-pc-linux-gnu
Running under: Debian GNU/Linux 12 (bookworm)

Matrix products: default
BLAS/LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.21.so;  LAPACK version 3.11.0

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] phonto_0.1.0 nhanesA_1.0  knitr_1.45  

loaded via a namespace (and not attached):
 [1] vctrs_0.6.5       svglite_2.1.3     httr_1.4.7        cli_3.6.2        
 [5] rlang_1.1.3       xfun_0.41         stringi_1.8.3     DBI_1.2.1        
 [9] glue_1.7.0        bit_4.0.5         plyr_1.8.9        hms_1.1.3        
[13] evaluate_0.23     lifecycle_1.0.4   odbc_1.4.1        stringr_1.5.1    
[17] compiler_4.4.0    rvest_1.0.3       blob_1.2.4        Rcpp_1.0.12      
[21] pkgconfig_2.0.3   systemfonts_1.0.5 digest_0.6.33     R6_2.5.1         
[25] foreign_0.8-86    magrittr_2.0.3    tools_4.4.0       bit64_4.0.5      
[29] xml2_1.3.6       
```


## Cross check tables with NHANES master list

The NHANES website contains a [master
list](https://wwwn.cdc.gov/Nchs/Nhanes/search/DataPage.aspx) of
available tables. This can be downloaded and parsed via the
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
'data.frame':	1515 obs. of  5 variables:
 $ Table  : chr  "ACQ_D" "ACQ_E" "ACQ" "ACQ_C" ...
 $ Years  : chr  "2005-2006" "2007-2008" "1999-2000" "2003-2004" ...
 $ PubDate: chr  "March 2008" "September 2009" "June 2002" "April 2006" ...
 $ DocURL : chr  "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/ACQ_D.htm" "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/ACQ_E.htm" "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/ACQ.htm" "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/ACQ_C.htm" ...
 $ DataURL: chr  "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/ACQ_D.XPT" "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/ACQ_E.XPT" "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/ACQ.XPT" "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/ACQ_C.XPT" ...
```

```r
## Some redirect URLs to fix up
subset(manifest, grepl("cdc.gov../", DocURL, fixed = TRUE) |
                 grepl("cdc.gov../", DataURL, fixed = TRUE))
```

```
     Table     Years              PubDate
1449 VID_B 2001-2002 Updated October 2015
1450 VID_C 2003-2004 Updated October 2015
1451 VID_D 2005-2006 Updated October 2015
1452 VID_E 2007-2008         October 2015
1453 VID_F 2009-2010         October 2015
                                                                              DocURL
1449 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=htm
1450 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=htm
1451 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=htm
1452 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=htm
1453 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=htm
                                                                             DataURL
1449 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=XPT
1450 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=XPT
1451 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=XPT
1452 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=XPT
1453 https://wwwn.cdc.gov../vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=XPT
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
   5    2 1508 
```

```r
with(manifest, table(tools::file_ext(DataURL)))  # data file extensions
```

```

     aspx  xpt  XPT  ZIP 
   9    2    3 1496    5 
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
     Table     Years               PubDate
554    All 1999-2006 Updated December 2016
1054   All 2009-2012          October 2022
                                                DocURL
554      https://wwwn.cdc.gov/Nchs/Nhanes/Dxa/Dxa.aspx
1054 https://wwwn.cdc.gov/Nchs/Nhanes/Omp/Default.aspx
                                               DataURL
554      https://wwwn.cdc.gov/Nchs/Nhanes/Dxa/Dxa.aspx
1054 https://wwwn.cdc.gov/Nchs/Nhanes/Omp/Default.aspx
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
        Table     Years               PubDate
1158 PAXRAW_D 2005-2006             June 2008
1159 PAXRAW_C 2003-2004 Updated December 2007
1356 SPXRAW_E 2007-2008         December 2011
1357 SPXRAW_F 2009-2010         December 2011
1358 SPXRAW_G 2011-2012         December 2014
                                                      DocURL
1158 https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.htm
1159 https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.htm
1356 https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.htm
1357 https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.htm
1358 https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.htm
                                                     DataURL
1158 https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.ZIP
1159 https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.ZIP
1356 https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.ZIP
1357 https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.ZIP
1358 https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.ZIP
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
(mtabs <- setdiff(manifest$Table, dbTableDesc$TableName)) # missing from DB
```

```
 [1] "P_SSFR"   "OCQ_I"    "PAXRAW_D" "PAXRAW_C" "PAXLUX_G" "PAXLUX_H"
 [7] "PAXMIN_G" "PAXMIN_H" "PAX80_G"  "PAX80_H"  "PAHS_G"   "PAHS_I"  
[13] "SPXRAW_E" "SPXRAW_F" "SPXRAW_G"
```

```r
setdiff(dbTableDesc$TableName, manifest$Table) # and the other way
```

```
character(0)
```

Ideally, this should match the list of excluded tables given by.


```r
nhanesQuery("select * from Metadata.ExcludedTables where Reason != 'limited access'")
```

```
  TableName     Reason
1      PAHS Large File
2     PAX80   FTP Only
3    PAXMIN     Broken
4   DDX_2_B     Broken
```

The following links can be used to explore the documentation of these
missing tables in the NHANES website.


```r
paste0("- <", subset(manifest, Table %in% mtabs)$DocURL, ">") |>
    cat(sep = "\n")
```

- <https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_SSFR.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/OCQ_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXLUX_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXLUX_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXMIN_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXMIN_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAX80_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAX80_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAHS_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/PAHS_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.htm>

## Consistency check for limited access tables


```r
ltd <- nhanesQuery("select * from Metadata.ExcludedTables where Reason = 'limited access'")
```

Verify that these are excluded from the manifest, as well as from the database.



```r
table(ltd$TableName %in% manifest$Table)
```

```

FALSE 
  223 
```

```r
table(ltd$TableName %in% dbTableDesc$TableName)
```

```

FALSE 
  223 
```



## Missing documentation

We check here for tables in the current metadata that do not have a
URL.


```r
subset(dbTableDesc, !startsWith(DocFile, "https"),
       select = c(TableName, DocFile, DataFile))
```

```
[1] TableName DocFile   DataFile 
<0 rows> (or 0-length row.names)
```

The corresponding documentation links from the online manifest are
given below.


```r
mdoc <- subset(dbTableDesc, !startsWith(DocFile, "https"))$TableName
if (length(mdoc))
    paste0("- <", subset(manifest, Table %in% mdoc)$DocURL, ">") |>
        cat(sep = "\n")
```

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
doc_mismatch <- (metadata_doc_url != manifest_doc_url[names(metadata_doc_url)])
data_mismatch <- (metadata_data_url != manifest_data_url[names(metadata_data_url)])
if (any(doc_mismatch))
    cbind(metadata_doc_url, manifest_doc_url[names(metadata_doc_url)])[doc_mismatch, ]
```

```
         metadata_doc_url                                         
APOB_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/ApoB_F.htm"  
APOB_H   "https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/ApoB_H.htm"  
L11_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11_2_b.htm" 
PBCD_D   "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PbCd_D.htm"  
PBCD_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/PbCd_E.htm"  
PBCD_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/PbCd_F.htm"  
IHG_D    "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/IHg_D.htm"   
IHG_F    "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/IHg_F.htm"   
APOB_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/ApoB_G.htm"  
L34_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l34_b.htm"   
PBCD_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PbCd_G.htm"  
L13_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l13_b.htm"   
L39_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l39_2_b.htm" 
L02HPA_A "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/L02HPA_a.htm"
IHGEM_G  "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/IHgEM_G.htm" 
APOB_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/ApoB_E.htm"  
L13_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l13_2_b.htm" 
L25_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l25_2_b.htm" 
L09_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/l09_c.htm"   
LAB09    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/lab09.htm"   
L11P_2_B "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l11p_2_b.htm"
VID_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/VID_B.htm"   
VID_D    "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/VID_D.htm"   
L34_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/l34_c.htm"   
L13_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/l13_c.htm"   
LAB13    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/Lab13.htm"   
LAB02    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/Lab02.htm"   
L09_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l09_b.htm"   
IHG_E    "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/IHg_E.htm"   
L26PP_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l26PP_B.htm" 
VID_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/VID_C.htm"   
VID_F    "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/VID_F.htm"   
VID_E    "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/VID_E.htm"   
                                                                                                    
APOB_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/APOB_F.htm"                                    
APOB_H   "https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/APOB_H.htm"                                    
L11_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11_2_B.htm"                                   
PBCD_D   "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PBCD_D.htm"                                    
PBCD_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/PBCD_E.htm"                                    
PBCD_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/PBCD_F.htm"                                    
IHG_D    "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/IHG_D.htm"                                     
IHG_F    "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/IHG_F.htm"                                     
APOB_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/APOB_G.htm"                                    
L34_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L34_B.htm"                                     
PBCD_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PBCD_G.htm"                                    
L13_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L13_B.htm"                                     
L39_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L39_2_B.htm"                                   
L02HPA_A "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/L02HPA_A.htm"                                  
IHGEM_G  "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/IHGEM_G.htm"                                   
APOB_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/APOB_E.htm"                                    
L13_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L13_2_B.htm"                                   
L25_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L25_2_B.htm"                                   
L09_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L09_C.htm"                                     
LAB09    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB09.htm"                                     
L11P_2_B "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11P_2_B.htm"                                  
VID_B    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=htm"
VID_D    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=htm"
L34_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L34_C.htm"                                     
L13_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L13_C.htm"                                     
LAB13    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB13.htm"                                     
LAB02    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB02.htm"                                     
L09_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L09_B.htm"                                     
IHG_E    "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/IHG_E.htm"                                     
L26PP_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L26PP_B.htm"                                   
VID_C    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=htm"
VID_F    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=htm"
VID_E    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=htm"
```

```r
if (any(data_mismatch))
    cbind(metadata_data_url, manifest_data_url[names(metadata_data_url)])[data_mismatch, ]
```

```
         metadata_data_url                                        
APOB_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/ApoB_F.XPT"  
APOB_H   "https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/ApoB_H.XPT"  
L11_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11_2_b.XPT" 
PBCD_D   "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PbCd_D.XPT"  
PBCD_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/PbCd_E.XPT"  
PBCD_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/PbCd_F.XPT"  
IHG_D    "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/IHg_D.XPT"   
IHG_F    "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/IHg_F.XPT"   
APOB_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/ApoB_G.XPT"  
L34_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l34_b.XPT"   
PBCD_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PbCd_G.XPT"  
L13_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l13_b.XPT"   
L39_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l39_2_b.XPT" 
L02HPA_A "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/L02HPA_a.XPT"
IHGEM_G  "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/IHgEM_G.XPT" 
APOB_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/ApoB_E.XPT"  
L13_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l13_2_b.XPT" 
L25_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l25_2_b.XPT" 
L09_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/l09_c.XPT"   
LAB09    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/lab09.XPT"   
L11P_2_B "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l11p_2_b.XPT"
VID_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/VID_B.XPT"   
VID_D    "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/VID_D.XPT"   
L34_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/l34_c.XPT"   
L13_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/l13_c.XPT"   
LAB13    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/Lab13.XPT"   
LAB02    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/Lab02.XPT"   
L09_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l09_b.XPT"   
IHG_E    "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/IHg_E.XPT"   
L26PP_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/l26PP_B.XPT" 
VID_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/VID_C.XPT"   
VID_F    "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/VID_F.XPT"   
VID_E    "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/VID_E.XPT"   
                                                                                                    
APOB_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/APOB_F.XPT"                                    
APOB_H   "https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/APOB_H.XPT"                                    
L11_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11_2_B.XPT"                                   
PBCD_D   "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PBCD_D.XPT"                                    
PBCD_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/PBCD_E.XPT"                                    
PBCD_F   "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/PBCD_F.XPT"                                    
IHG_D    "https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/IHG_D.XPT"                                     
IHG_F    "https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/IHG_F.XPT"                                     
APOB_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/APOB_G.XPT"                                    
L34_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L34_B.XPT"                                     
PBCD_G   "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PBCD_G.XPT"                                    
L13_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L13_B.XPT"                                     
L39_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L39_2_B.XPT"                                   
L02HPA_A "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/L02HPA_A.XPT"                                  
IHGEM_G  "https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/IHGEM_G.XPT"                                   
APOB_E   "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/APOB_E.XPT"                                    
L13_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L13_2_B.XPT"                                   
L25_2_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L25_2_B.XPT"                                   
L09_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L09_C.XPT"                                     
LAB09    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB09.XPT"                                     
L11P_2_B "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L11P_2_B.XPT"                                  
VID_B    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2001&e=2002&d=VID_B&x=XPT"
VID_D    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2005&e=2006&d=VID_D&x=XPT"
L34_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L34_C.XPT"                                     
L13_C    "https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/L13_C.XPT"                                     
LAB13    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB13.XPT"                                     
LAB02    "https://wwwn.cdc.gov/Nchs/Nhanes/1999-2000/LAB02.XPT"                                     
L09_B    "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L09_B.XPT"                                     
IHG_E    "https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/IHG_E.XPT"                                     
L26PP_B  "https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/L26PP_B.XPT"                                   
VID_C    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2003&e=2004&d=VID_C&x=XPT"
VID_F    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2009&e=2010&d=VID_F&x=XPT"
VID_E    "https://wwwn.cdc.gov/Nchs/Nhanes/vitamind/analyticalnote.aspx?b=2007&e=2008&d=VID_E&x=XPT"
```





