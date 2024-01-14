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
 [1] "AUXAR_I"  "P_AUXAR"  "CHLMDA_F" "CHLMDA_G" "CHLMDA_H" "CHLMDA_I" "LAB05"    "CHLMDA_D" "L05_C"    "L05_B"    "CHLMDA_E" "SSCT_H"   "SSCT_I"   "DR1IFF_F" "PAXRAW_D" "PAXRAW_C" "PAXLUX_G"
[18] "PAXLUX_H" "PAXHR_G"  "PAXHR_H"  "PAXMIN_G" "PAXMIN_H" "PAX80_G"  "PAX80_H"  "PAHS_G"   "PAHS_I"   "SPXRAW_E" "SPXRAW_F" "SPXRAW_G" "VID_B"    "VID_C"    "VID_D"    "VID_E"    "VID_F"   
[35] "VID_G"    "VID_H"    "VID_I"    "VID_J"   
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
 [1] "AUXAR_I"  "CHLMDA_F" "CHLMDA_G" "CHLMDA_H" "CHLMDA_I" "LAB05"   
 [7] "CHLMDA_D" "L05_C"    "L05_B"    "CHLMDA_E" "SSCT_H"   "SSCT_I"  
[13] "DR1IFF_F" "PAXRAW_D" "PAXRAW_C" "PAXLUX_G" "PAXLUX_H" "PAXHR_G" 
[19] "PAXHR_H"  "PAXMIN_G" "PAXMIN_H" "PAX80_G"  "PAX80_H"  "PAHS_G"  
[25] "PAHS_I"   "SPXRAW_E" "SPXRAW_F" "SPXRAW_G" "VID_B"    "VID_C"   
[31] "VID_D"    "VID_E"    "VID_F"    "VID_G"    "VID_H"    "VID_I"   
[37] "VID_J"   
```

Ideally, this should match the list of excluded tables given by.


```r
nhanesQuery("select * from Metadata.ExcludedTables")
```

```
     TableName         Reason
1         PAHS     Large File
2        PAX80       FTP Only
3       PAXLUX         Broken
4       ALQYTH         Broken
5          OMP         Broken
6          VID         Broken
7         SSCT         Broken
8       SPXRAW Limited Access
9       PAXRAW Limited Access
10      CHLMDA Limited Access
11        CHLA Limited Access
12        CHLM Limited Access
13       LAB05 Limited Access
14         L05 Limited Access
15      PAXMIN Limited Access
16     UR1_H_R Limited Access
17     UR2_H_R Limited Access
18    ALCR_G_R Limited Access
19    ALQYTH_E Limited Access
20    ALQYTH_D Limited Access
21      ALQYTH Limited Access
22    ALQY_F_R Limited Access
23    ALQY_G_R Limited Access
24    ALQY_H_R Limited Access
25    ALQY_I_R Limited Access
26    ALQY_J_R Limited Access
27    P_ALQY_R Limited Access
28    SSH7N9_R Limited Access
29     L34_B_R Limited Access
30     L34_C_R Limited Access
31    L06_2_00 Limited Access
32    U1CF_H_R Limited Access
33    U2CF_H_R Limited Access
34    CDEMO_EH Limited Access
35    CDEMO_AD Limited Access
36    CHLA_J_R Limited Access
37    P_CHLA_R Limited Access
38    CHLM_G_R Limited Access
39    CHLM_H_R Limited Access
40    CHLM_I_R Limited Access
41    CHLM_J_R Limited Access
42    P_CHLM_R Limited Access
43    CHLM_E_R Limited Access
44    L05RDC_A Limited Access
45    CHLM_F_R Limited Access
46    CHLMD_DR Limited Access
47    L05RDC_C Limited Access
48    L05RDC_B Limited Access
49    SSCT_H_R Limited Access
50    SSCT_I_R Limited Access
51     L13_2_R Limited Access
52     CFQ_K_R Limited Access
53     L25_2_R Limited Access
54     P_CBQ_R Limited Access
55     L11_2_R Limited Access
56     L16_2_R Limited Access
57    DEMO_K_R Limited Access
58     DEQ_E_R Limited Access
59    DB24_K_R Limited Access
60     P_DUQ_R Limited Access
61    DUQYTH_E Limited Access
62    DUQY_F_R Limited Access
63    DUQY_G_R Limited Access
64    DUQY_H_R Limited Access
65    DUQY_I_R Limited Access
66    DUQY_J_R Limited Access
67    P_DUQY_R Limited Access
68    DXXV_H_R Limited Access
69    DXX_2_00 Limited Access
70    EC24_K_R Limited Access
71    U1LT_H_R Limited Access
72    U2LT_H_R Limited Access
73    HULT_H_R Limited Access
74    SSLT_H_R Limited Access
75    SSUECD_R Limited Access
76     FAR_K_R Limited Access
77    FLDW_K_R Limited Access
78    U1FL_H_R Limited Access
79    U2FL_H_R Limited Access
80    FLXC_H_R Limited Access
81    SSFA_B_R Limited Access
82    FFMR_K_R Limited Access
83     SSFOL_B Limited Access
84     FSQ_E_R Limited Access
85     FSQ_F_R Limited Access
86     FSQ_G_R Limited Access
87     FSQ_H_R Limited Access
88     FSQ_I_R Limited Access
89     FSQ_J_R Limited Access
90     P_FSQ_R Limited Access
91    FNQA_K_R Limited Access
92    FNQC_K_R Limited Access
93    GEO_2000 Limited Access
94    GEO_2010 Limited Access
95    L10_2_00 Limited Access
96     HP_01_R Limited Access
97    HP2_01_R Limited Access
98    SSH1N1_E Limited Access
99    SSHN10_R Limited Access
100   SSHC_I_R Limited Access
101   HEPC_I_R Limited Access
102   HSVA_J_R Limited Access
103   P_HSVA_R Limited Access
104    HSV_I_R Limited Access
105    P_HSV_R Limited Access
106    HSV_E_R Limited Access
107     HSV_DR Limited Access
108   L09RDC_C Limited Access
109   L09RDC_A Limited Access
110   L09RDC_B Limited Access
111    HSV_F_R Limited Access
112    HSV_G_R Limited Access
113    HSV_H_R Limited Access
114    HSV_J_R Limited Access
115    P_HIV_R Limited Access
116    P_HOQ_R Limited Access
117    B27_F_R Limited Access
118   HPVS_D_R Limited Access
119    SER_E_R Limited Access
120    SER_F_R Limited Access
121   HPVN_D_R Limited Access
122   HPVM_D_R Limited Access
123   OHPV_F_R Limited Access
124   OHPV_G_R Limited Access
125   OHPV_H_R Limited Access
126   OHPV_I_R Limited Access
127   HPVP_I_R Limited Access
128    SWA_C_R Limited Access
129   HPVS_F_R Limited Access
130   HPVS_G_R Limited Access
131    SWR_E_R Limited Access
132    SWR_D_R Limited Access
133   HPVS_H_R Limited Access
134   HPWC_J_R Limited Access
135   HPVC_I_R Limited Access
136   HPVC_J_R Limited Access
137   HPVW_J_R Limited Access
138    SWR_C_R Limited Access
139   HPVS_I_R Limited Access
140   HPVS_J_R Limited Access
141   HPVP_H_R Limited Access
142   SSHP_F_R Limited Access
143   IFII_K_R Limited Access
144   IFLD_K_R Limited Access
145   IFNI_K_R Limited Access
146   IFPI_K_R Limited Access
147   IFQF_K_R Limited Access
148   SSIF_F_R Limited Access
149   U1IO_H_R Limited Access
150   U2IO_H_R Limited Access
151   IODS_K_R Limited Access
152   SSUIFG_R Limited Access
153   U1KM_H_R Limited Access
154   U2KM_H_R Limited Access
155   HUKM_H_R Limited Access
156    PBY_J_R Limited Access
157    P_PBY_R Limited Access
158     UM_J_R Limited Access
159     P_UM_R Limited Access
160    LA_DEMO Limited Access
161   LDEMO_AD Limited Access
162   LDEMO_EH Limited Access
163    L19_2_R Limited Access
164       YDQA Limited Access
165        YCQ Limited Access
166      YCQ_B Limited Access
167      YCQ_C Limited Access
168       YDQC Limited Access
169   DPQYTH_E Limited Access
170   DPQY_F_R Limited Access
171   DPQYTH_D Limited Access
172   DPQY_G_R Limited Access
173   DPQY_H_R Limited Access
174   DPQY_I_R Limited Access
175   DPQY_J_R Limited Access
176   P_DPQY_R Limited Access
177       YDQE Limited Access
178       YDQL Limited Access
179       YDQG Limited Access
180       YDQD Limited Access
181       YDQP Limited Access
182        YDQ Limited Access
183   MGEA_J_R Limited Access
184   MGEN_J_R Limited Access
185   P_MGEA_R Limited Access
186   P_MGEN_R Limited Access
187    OCQ_H_R Limited Access
188    OCQ_E_R Limited Access
189    OCQ_D_R Limited Access
190    OCQ_F_R Limited Access
191    OCQ_G_R Limited Access
192   U1PN_H_R Limited Access
193   U2PN_H_R Limited Access
194 PAXLUX_G_R Limited Access
195   PAXD_G_R Limited Access
196   PAXA_G_R Limited Access
197   PAXH_G_R Limited Access
198   PAXM_G_R Limited Access
199  PAX80_G_R Limited Access
200   U1PT_H_R Limited Access
201   U2PT_H_R Limited Access
202    RHQ_E_R Limited Access
203    RHQ_F_R Limited Access
204    RHQ_G_R Limited Access
205    RHQ_H_R Limited Access
206    RHQ_I_R Limited Access
207    RHQ_J_R Limited Access
208    P_RHQ_R Limited Access
209    SUQ_K_R Limited Access
210   DOC_2000 Limited Access
211    TST_K_R Limited Access
212    SXQ_J_R Limited Access
213    P_SXQ_R Limited Access
214   SXQYTH_D Limited Access
215   SXQYTH_E Limited Access
216   SXQY_F_R Limited Access
217   SXQY_G_R Limited Access
218     SXQYTH Limited Access
219   SXQY_H_R Limited Access
220   SXQY_I_R Limited Access
221   SXQYTH_B Limited Access
222   SXQYTH_C Limited Access
223   SXQY_J_R Limited Access
224   P_SXQY_R Limited Access
225   SSUE10_R Limited Access
226   L18_2_00 Limited Access
227    BAQ_K_R Limited Access
228    CSX_G_R Limited Access
229   THYD_K_R Limited Access
230   TRIA_J_R Limited Access
231   P_TRIA_R Limited Access
232   TRIC_I_R Limited Access
233   TRIC_J_R Limited Access
234   P_TRIC_R Limited Access
235   TRIC_H_R Limited Access
236     TB_K_R Limited Access
237    VIT_2_R Limited Access
238   VCWB_K_R Limited Access
```

The following links can be used to explore the documentation of these
missing tables in the NHANES website.


```r
paste0("- <", subset(manifest, Table %in% mtabs)$DocURL, ">") |>
    cat(sep = "\n")
```

- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/AUXAR_I.htm>
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
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/DR1IFF_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2005-2006/PAXRAW_D.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2003-2004/PAXRAW_C.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXLUX_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXLUX_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXHR_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXHR_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAXMIN_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAXMIN_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAX80_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2013-2014/PAX80_H.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/PAHS_G.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/PAHS_I.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2007-2008/SPXRAW_E.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2009-2010/SPXRAW_F.htm>
- <https://wwwn.cdc.gov/Nchs/Nhanes/2011-2012/SPXRAW_G.htm>
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
[1] TableName DocFile   DataFile 
<0 rows> (or 0-length row.names)
```

The corresponding documentation links from the online manifest are
given below.


```r
mdoc <- subset(dbTableDesc, !startsWith(DocFile, "https"))$TableName
paste0("- <", subset(manifest, Table %in% mdoc)$DocURL, ">") |>
    cat(sep = "\n")
```

- <>

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
[1] FALSE
```

```r
all(metadata_data_url == manifest_data_url[names(metadata_data_url)])
```

```
[1] FALSE
```





