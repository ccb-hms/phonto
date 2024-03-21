---
layout: default
title: "Diagnostics: Codebook Inconsistencies"
editor_options: 
  chunk_output_type: console
---





NHANES tables themselves have cryptic variable names, and must be used
in conjunction with corresponding documentation files to be
interpreted. Both standard and database versions of the `nhanes()` and
`nhanesFromURL()` functions in the __nhanesA__ package return a
"translated" data frame, which modify the raw data columns in the SAS
transport files using per-variable translation tables, referred to as
_codebooks_, obtained from the NHANES online documentation.

This document describes a series of diagnostic checks to identify
possible issues with these codebooks.

# Variable codebooks

Variable codebooks are obtained by downloading and parsing online
documentation files. These codebooks are stored in the database,
making it relatively easy to work with them.


```r
library(nhanesA)
library(phonto)
all_cb <- nhanesQuery("select * from Metadata.VariableCodebook")
str(all_cb)
```

```
'data.frame':	202018 obs. of  7 variables:
 $ Variable        : chr  "WTSA2YR" "WTSA2YR" "WTSA2YR" "URX1NP" ...
 $ TableName       : chr  "AA_H" "AA_H" "AA_H" "AA_H" ...
 $ CodeOrValue     : chr  "16284.37488 to 530325.34726" "0" "." "0.91 to 441" ...
 $ ValueDescription: chr  "Range of Values" "No Lab Result" "Missing" "Range of Values" ...
 $ Count           : int  2724 31 0 2478 277 1776 702 0 277 2488 ...
 $ Cumulative      : int  2724 2755 2755 2478 2755 1776 2478 2478 2755 2488 ...
 $ SkipToItem      : chr  NA NA NA NA ...
```


# Ambiguous variable types

NHANES has both numeric and categorical variables. There is no
indication in the data or documentation itself of what type a certain
variable is supposed to be. However, for most numeric variables, the
`ValueDescription` column will have an entry called `"Range of
Values"`. The presence of this value is used by the __nhanesA__
package to infer the type of a variable.

Unfortunately, with this rule, some variables are flagged as numeric
in some cycles but categorical in others. Such variables can be
identified in the searchable variable tables available [here](../)
with a `Type` value of `ambiguous`. Below, we try to take a closer
look at such variables.

We first restrict our attention to variables that are 'numeric' in at
least one table. There may be others that are mistakenly classified as
numeric, but those may be difficult to flag.


```r
numeric_vars <- with(all_cb, unique(Variable[ValueDescription == "Range of Values"]))
numeric_cb <- subset(all_cb, Variable %in% numeric_vars, select = 1:5)
```

Ideally, all the 'numeric' values in these codebooks should be
identified as `"Range of Values"`. If they are not, however, they are
usually just the numeric value, or some indicator of thresholding such
as `"more than 80"`. Let us look at the 'ValueDescription'-s that
represent numeric values, in the sense that they can be coerced to a
finite numeric value.



```r
maybe_numeric <- is.finite(as.numeric(numeric_cb$ValueDescription))
```

```
Warning: NAs introduced by coercion
```

```r
table(maybe_numeric)
```

```
maybe_numeric
FALSE  TRUE 
76764   480 
```

We will focus on these variables for now.


```r
problem_vars <- unique(numeric_cb[maybe_numeric, ]$Variable)
str(problem_vars)
```

```
 chr [1:183] "AUXR1K2L" "AUXR8KR" "AUXR2KR" "AUXR1K2R" "AUXR3KR" "BAXFTC12" ...
```

```r
length(num_cb_byVar <- numeric_cb |>
           subset(Variable %in% problem_vars) |>
           split(~ Variable))
```

```
[1] 183
```

Let's start by summarizing these to keep only the unique
`CodeOrValue` + `ValueDescription` combinations, and then prioritize
them by the number of numeric-like values that remain.


```r
summary_byVar <-
    lapply(num_cb_byVar,
           function(d) unique(d[c("Variable", "CodeOrValue",
                                  "ValueDescription")]))
numNumeric <- function(d) {
    suppressWarnings(sum(is.finite(as.numeric(d$ValueDescription))))
}
(nnum <- sapply(summary_byVar, numNumeric) |> sort())
```

```
AUXR1K2R  AUXR2KR  AUXR3KR  AUXR8KR BAXFTC12 CVDR3TIM  DR2LANG DRD370JQ  DUQ310Q 
       1        1        1        1        1        1        1        1        1 
 DUQ350Q   DUQ390   DXXSPY  LBDBANO  LBDEONO   LBDRPI   LBXV2P   LBXVDX   LBXVTP 
       1        1        1        1        1        1        1        1        1 
 MCQ240D  MCQ240H  MCQ240K  MCQ240M  MCQ240Q  MCQ240V OSD030CC OSD030CD  OSD110H 
       1        1        1        1        1        1        1        1        1 
 PFD069L   SSDBZP SSMTBRPS SSMTBRSG SSWT0306   SXQ267   SXQ410   SXQ550   SXQ836 
       1        1        1        1        1        1        1        1        1 
  SXQ841   URX1DC   URXMTO   URXOMO   URXP09   URXPTU   URXTCV   URXUBE WTSAF2YR 
       1        1        1        1        1        1        1        1        1 
WTSAF4YR  WTSPH01  WTSPH02  WTSPH03  WTSPH04  WTSPH05  WTSPH06  WTSPH07  WTSPH08 
       1        1        1        1        1        1        1        1        1 
 WTSPH09  WTSPH10  WTSPH11  WTSPH12  WTSPH13  WTSPH14  WTSPH15  WTSPH16  WTSPH17 
       1        1        1        1        1        1        1        1        1 
 WTSPH18  WTSPH19  WTSPH20  WTSPH21  WTSPH22  WTSPH23  WTSPH24  WTSPH25  WTSPH26 
       1        1        1        1        1        1        1        1        1 
 WTSPH27  WTSPH28  WTSPH29  WTSPH30  WTSPH31  WTSPH32  WTSPH33  WTSPH34  WTSPH35 
       1        1        1        1        1        1        1        1        1 
 WTSPH36  WTSPH37  WTSPH38  WTSPH39  WTSPH40  WTSPH41  WTSPH42  WTSPH43  WTSPH44 
       1        1        1        1        1        1        1        1        1 
 WTSPH45  WTSPH46  WTSPH47  WTSPH48  WTSPH49  WTSPH50  WTSPH51  WTSPH52  WTSPO01 
       1        1        1        1        1        1        1        1        1 
 WTSPO02  WTSPO03  WTSPO04  WTSPO05  WTSPO06  WTSPO07  WTSPO08  WTSPO09  WTSPO10 
       1        1        1        1        1        1        1        1        1 
 WTSPO11  WTSPO12  WTSPO13  WTSPO14  WTSPO15  WTSPO16  WTSPO17  WTSPO18  WTSPO19 
       1        1        1        1        1        1        1        1        1 
 WTSPO20  WTSPO21  WTSPO22  WTSPO23  WTSPO24  WTSPO25  WTSPO26  WTSPO27  WTSPO28 
       1        1        1        1        1        1        1        1        1 
 WTSPO29  WTSPO30  WTSPO31  WTSPO32  WTSPO33  WTSPO34  WTSPO35  WTSPO36  WTSPO37 
       1        1        1        1        1        1        1        1        1 
 WTSPO38  WTSPO39  WTSPO40  WTSPO41  WTSPO42  WTSPO43  WTSPO44  WTSPO45  WTSPO46 
       1        1        1        1        1        1        1        1        1 
 WTSPO47  WTSPO48  WTSPO49  WTSPO50  WTSPO51  WTSPO52 AUXR1K2L DRD370PQ   DUQ340 
       1        1        1        1        1        1        2        2        2 
  DUQ360  DUQ400Q MCQ240AA MCQ240DK  MCQ240L  MCQ240T OSD030BG  OSD110F   SMD415 
       2        2        2        2        2        2        2        2        2 
 SMD415A   URX2DC DMDHHSZA DMDHHSZE OSD030BF OSD030CE  OSQ020A  RHQ602Q DMDHHSZB 
       2        2        3        3        3        3        3        3        4 
 MCQ240Y OSD030AC DMDFMSIZ DMDHHSIZ   HUD080  MCQ240B  OSQ020C  OSQ020B  ECD070A 
       4        4        6        6        6        6        6        7       12 
  HOD050   HSQ580   KID221 
      12       12       24 
```

To get a sense of the problem cases, we look at the variables with 10
or more numeric variables.


```r
num_cb_byVar[ names(which(nnum >= 10)) ]
```

```
$ECD070A
       Variable TableName CodeOrValue  ValueDescription Count
72819   ECD070A  EC24_K_R     4 to 10   Range of Values   375
72820   ECD070A  EC24_K_R           3  3 pounds or less    10
72821   ECD070A  EC24_K_R          11 11 pounds or more     0
72822   ECD070A  EC24_K_R        7777           Refused     0
72823   ECD070A  EC24_K_R        9999        Don't know     4
72824   ECD070A  EC24_K_R           .           Missing     0
72870   ECD070A       ECQ           1                 1    36
72871   ECD070A       ECQ           2                 2    19
72872   ECD070A       ECQ           3                 3    39
72873   ECD070A       ECQ           4                 4    89
72874   ECD070A       ECQ           5                 5   264
72875   ECD070A       ECQ           6                 6   869
72876   ECD070A       ECQ           7                 7  1317
72877   ECD070A       ECQ           8                 8   805
72878   ECD070A       ECQ           9                 9   237
72879   ECD070A       ECQ          10                10    87
72880   ECD070A       ECQ          11                11    15
72881   ECD070A       ECQ          12                12     1
72882   ECD070A       ECQ          13 13 pounds or more     3
72883   ECD070A       ECQ          77           Refused     2
72884   ECD070A       ECQ          99        Don't know   133
72885   ECD070A       ECQ           .           Missing     5
72956   ECD070A     ECQ_B     1 to 12   Range of Values  4257
72957   ECD070A     ECQ_B          13 13 pounds or more     6
72958   ECD070A     ECQ_B        7777           Refused     0
72959   ECD070A     ECQ_B        9999        Don't know   141
72960   ECD070A     ECQ_B           .           Missing     1
73023   ECD070A     ECQ_C     1 to 12   Range of Values  3791
73024   ECD070A     ECQ_C          13 13 pounds or more     2
73025   ECD070A     ECQ_C        7777           Refused     1
73026   ECD070A     ECQ_C        9999        Don't know   113
73027   ECD070A     ECQ_C           .           Missing     2
73089   ECD070A     ECQ_D     1 to 12   Range of Values  4071
73090   ECD070A     ECQ_D          13 13 pounds or more     4
73091   ECD070A     ECQ_D        7777           Refused     1
73092   ECD070A     ECQ_D        9999        Don't know   131
73093   ECD070A     ECQ_D           .           Missing     2
73162   ECD070A     ECQ_E     1 to 12   Range of Values  3538
73163   ECD070A     ECQ_E          13 13 pounds or more     4
73164   ECD070A     ECQ_E        7777           Refused     0
73165   ECD070A     ECQ_E        9999        Don't know    60
73166   ECD070A     ECQ_E           .           Missing     1
73213   ECD070A     ECQ_F     1 to 12   Range of Values  3578
73214   ECD070A     ECQ_F          13 13 pounds or more     8
73215   ECD070A     ECQ_F        7777           Refused     0
73216   ECD070A     ECQ_F        9999        Don't know    62
73217   ECD070A     ECQ_F           .           Missing     0
73259   ECD070A     ECQ_G     1 to 12   Range of Values  3505
73260   ECD070A     ECQ_G          13 13 pounds or more     3
73261   ECD070A     ECQ_G        7777           Refused     1
73262   ECD070A     ECQ_G        9999        Don't know    72
73263   ECD070A     ECQ_G           .           Missing     0
73305   ECD070A     ECQ_H     1 to 12   Range of Values  3622
73306   ECD070A     ECQ_H          13 13 pounds or more     0
73307   ECD070A     ECQ_H        7777           Refused     0
73308   ECD070A     ECQ_H        9999        Don't know    88
73309   ECD070A     ECQ_H           .           Missing     1
73351   ECD070A     ECQ_I     4 to 10   Range of Values  3436
73352   ECD070A     ECQ_I           3  3 pounds or less    80
73353   ECD070A     ECQ_I          11 11 pounds or more    10
73354   ECD070A     ECQ_I        7777           Refused     2
73355   ECD070A     ECQ_I        9999        Don't know   116
73356   ECD070A     ECQ_I           .           Missing     0
73398   ECD070A     ECQ_J     4 to 10   Range of Values  2926
73399   ECD070A     ECQ_J           3  3 pounds or less    66
73400   ECD070A     ECQ_J          11 11 pounds or more    15
73401   ECD070A     ECQ_J        7777           Refused     0
73402   ECD070A     ECQ_J        9999        Don't know    85
73403   ECD070A     ECQ_J           .           Missing     1
146578  ECD070A     P_ECQ     4 to 10   Range of Values  5056
146579  ECD070A     P_ECQ           3  3 pounds or less   129
146580  ECD070A     P_ECQ          11 11 pounds or more    23
146581  ECD070A     P_ECQ        7777           Refused     0
146582  ECD070A     P_ECQ        9999        Don't know   155
146583  ECD070A     P_ECQ           .           Missing     2

$HOD050
      Variable TableName CodeOrValue ValueDescription Count
86830   HOD050       HOQ     1 to 12  Range of Values  9709
86831   HOD050       HOQ          13       13 or More    70
86832   HOD050       HOQ         777          Refused    12
86833   HOD050       HOQ         999       Don't know    13
86834   HOD050       HOQ           .          Missing   161
86927   HOD050     HOQ_B     1 to 12  Range of Values 10725
86928   HOD050     HOQ_B          13       13 or More    93
86929   HOD050     HOQ_B         777          Refused    19
86930   HOD050     HOQ_B         999       Don't know    28
86931   HOD050     HOQ_B           .          Missing   174
87024   HOD050     HOQ_C     1 to 12  Range of Values  9944
87025   HOD050     HOQ_C          13       13 or more    27
87026   HOD050     HOQ_C         777          Refused    10
87027   HOD050     HOQ_C         999       Don't know     8
87028   HOD050     HOQ_C           .          Missing   133
87120   HOD050     HOQ_D     1 to 12  Range of Values 10150
87121   HOD050     HOQ_D          13       13 or more    69
87122   HOD050     HOQ_D         777          Refused     5
87123   HOD050     HOQ_D         999       Don't know    15
87124   HOD050     HOQ_D           .          Missing   109
87195   HOD050     HOQ_E     1 to 12  Range of Values  9977
87196   HOD050     HOQ_E          13       13 or more    62
87197   HOD050     HOQ_E         777          Refused     4
87198   HOD050     HOQ_E         999       Don't know    12
87199   HOD050     HOQ_E           .          Missing    94
87234   HOD050     HOQ_F     1 to 12  Range of Values 10348
87235   HOD050     HOQ_F          13       13 or more    97
87236   HOD050     HOQ_F         777          Refused    13
87237   HOD050     HOQ_F         999       Don't know    11
87238   HOD050     HOQ_F           .          Missing    68
87264   HOD050     HOQ_G           1                1    63
87265   HOD050     HOQ_G           2                2   241
87266   HOD050     HOQ_G           3                3   924
87267   HOD050     HOQ_G           4                4  1863
87268   HOD050     HOQ_G           5                5  1972
87269   HOD050     HOQ_G           6                6  1709
87270   HOD050     HOQ_G           7                7  1117
87271   HOD050     HOQ_G           8                8   776
87272   HOD050     HOQ_G           9                9   410
87273   HOD050     HOQ_G          10               10   309
87274   HOD050     HOQ_G          11               11   162
87275   HOD050     HOQ_G          12               12    67
87276   HOD050     HOQ_G          13       13 or more    90
87277   HOD050     HOQ_G         777          Refused     4
87278   HOD050     HOQ_G         999       Don't know     0
87279   HOD050     HOQ_G           .          Missing    49
87286   HOD050     HOQ_H           1                1    88
87287   HOD050     HOQ_H           2                2   202
87288   HOD050     HOQ_H           3                3   683
87289   HOD050     HOQ_H           4                4  1613
87290   HOD050     HOQ_H           5                5  2093
87291   HOD050     HOQ_H           6                6  1922
87292   HOD050     HOQ_H           7                7  1272
87293   HOD050     HOQ_H           8                8   853
87294   HOD050     HOQ_H           9                9   574
87295   HOD050     HOQ_H          10               10   343
87296   HOD050     HOQ_H          11               11   197
87297   HOD050     HOQ_H          12               12   108
87298   HOD050     HOQ_H          13       13 or more    85
87299   HOD050     HOQ_H         777          Refused    16
87300   HOD050     HOQ_H         999       Don't know     5
87301   HOD050     HOQ_H           .          Missing   121
87308   HOD050     HOQ_I           1                1    49
87309   HOD050     HOQ_I           2                2   204
87310   HOD050     HOQ_I           3                3   831
87311   HOD050     HOQ_I           4                4  1810
87312   HOD050     HOQ_I           5                5  2071
87313   HOD050     HOQ_I           6                6  1728
87314   HOD050     HOQ_I           7                7  1130
87315   HOD050     HOQ_I           8                8   773
87316   HOD050     HOQ_I           9                9   434
87317   HOD050     HOQ_I          10               10   323
87318   HOD050     HOQ_I          11               11   133
87319   HOD050     HOQ_I          12               12    71
87320   HOD050     HOQ_I          13       13 or more    51
87321   HOD050     HOQ_I         777          Refused    34
87322   HOD050     HOQ_I         999       Don't know     0
87323   HOD050     HOQ_I           .          Missing   329
87330   HOD050     HOQ_J           1                1    78
87331   HOD050     HOQ_J           2                2   198
87332   HOD050     HOQ_J           3                3   713
87333   HOD050     HOQ_J           4                4  1693
87334   HOD050     HOQ_J           5                5  1848
87335   HOD050     HOQ_J           6                6  1562
87336   HOD050     HOQ_J           7                7  1115
87337   HOD050     HOQ_J           8                8   670
87338   HOD050     HOQ_J           9                9   415
87339   HOD050     HOQ_J          10               10   276
87340   HOD050     HOQ_J          11               11    79
87341   HOD050     HOQ_J          12               12    51
87342   HOD050     HOQ_J          13       13 or more    47
87343   HOD050     HOQ_J         777          Refused     8
87344   HOD050     HOQ_J         999       Don't know    27
87345   HOD050     HOQ_J           .          Missing   474

$HSQ580
      Variable TableName CodeOrValue ValueDescription Count
90108   HSQ580       HSQ     1 to 12  Range of Values   238
90109   HSQ580       HSQ          77          Refused     0
90110   HSQ580       HSQ          99       Don't know     8
90111   HSQ580       HSQ           .          Missing  8586
90160   HSQ580     HSQ_B     1 to 12  Range of Values   272
90161   HSQ580     HSQ_B          77          Refused     0
90162   HSQ580     HSQ_B          99       Don't know     2
90163   HSQ580     HSQ_B           .          Missing 10108
90212   HSQ580     HSQ_C     1 to 12  Range of Values   233
90213   HSQ580     HSQ_C          77          Refused     0
90214   HSQ580     HSQ_C          99       Don't know     3
90215   HSQ580     HSQ_C           .          Missing  9299
90264   HSQ580     HSQ_D     1 to 12  Range of Values   235
90265   HSQ580     HSQ_D          77          Refused     0
90266   HSQ580     HSQ_D          99       Don't know     4
90267   HSQ580     HSQ_D           .          Missing  9201
90324   HSQ580     HSQ_E     1 to 12  Range of Values   242
90325   HSQ580     HSQ_E          77          Refused     0
90326   HSQ580     HSQ_E          99       Don't know     5
90327   HSQ580     HSQ_E           .          Missing  9060
90384   HSQ580     HSQ_F     1 to 12  Range of Values   338
90385   HSQ580     HSQ_F          77          Refused     0
90386   HSQ580     HSQ_F          99       Don't know     3
90387   HSQ580     HSQ_F           .          Missing  9494
90444   HSQ580     HSQ_G     1 to 12  Range of Values   261
90445   HSQ580     HSQ_G          77          Refused     0
90446   HSQ580     HSQ_G          99       Don't know     0
90447   HSQ580     HSQ_G           .          Missing  8695
90484   HSQ580     HSQ_H           1                1    39
90485   HSQ580     HSQ_H           2                2    38
90486   HSQ580     HSQ_H           3                3    28
90487   HSQ580     HSQ_H           4                4    20
90488   HSQ580     HSQ_H           5                5    13
90489   HSQ580     HSQ_H           6                6    29
90490   HSQ580     HSQ_H           7                7    19
90491   HSQ580     HSQ_H           8                8    11
90492   HSQ580     HSQ_H           9                9    11
90493   HSQ580     HSQ_H          10               10    13
90494   HSQ580     HSQ_H          11               11    17
90495   HSQ580     HSQ_H          12               12    18
90496   HSQ580     HSQ_H          77          Refused     0
90497   HSQ580     HSQ_H          99       Don't know     4
90498   HSQ580     HSQ_H           .          Missing  9162
90535   HSQ580     HSQ_I           1                1    42
90536   HSQ580     HSQ_I           2                2    34
90537   HSQ580     HSQ_I           3                3    22
90538   HSQ580     HSQ_I           4                4    29
90539   HSQ580     HSQ_I           5                5    15
90540   HSQ580     HSQ_I           6                6    29
90541   HSQ580     HSQ_I           7                7    13
90542   HSQ580     HSQ_I           8                8    12
90543   HSQ580     HSQ_I           9                9     7
90544   HSQ580     HSQ_I          10               10    10
90545   HSQ580     HSQ_I          11               11     5
90546   HSQ580     HSQ_I          12               12    10
90547   HSQ580     HSQ_I          77          Refused     0
90548   HSQ580     HSQ_I          99       Don't know     2
90549   HSQ580     HSQ_I           .          Missing  8935
90586   HSQ580     HSQ_J           1                1    53
90587   HSQ580     HSQ_J           2                2    35
90588   HSQ580     HSQ_J           3                3    23
90589   HSQ580     HSQ_J           4                4    33
90590   HSQ580     HSQ_J           5                5    11
90591   HSQ580     HSQ_J           6                6    40
90592   HSQ580     HSQ_J           7                7    15
90593   HSQ580     HSQ_J           8                8    16
90594   HSQ580     HSQ_J           9                9     7
90595   HSQ580     HSQ_J          10               10    12
90596   HSQ580     HSQ_J          11               11    18
90597   HSQ580     HSQ_J          12               12     6
90598   HSQ580     HSQ_J          77          Refused     0
90599   HSQ580     HSQ_J          99       Don't know     5
90600   HSQ580     HSQ_J           .          Missing  8092

$KID221
       Variable TableName                         CodeOrValue   ValueDescription
95207    KID221  L11PSA_C Age at diagnosis of prostate cancer Value was recorded
95208    KID221  L11PSA_C                                 777            Refused
95209    KID221  L11PSA_C                                 999         Don't know
95210    KID221  L11PSA_C                           < blank >            Missing
162578   KID221     PSA_D                                   .                  .
162579   KID221     PSA_D                                  54                 54
162580   KID221     PSA_D                                  58                 58
162581   KID221     PSA_D                                  59                 59
162582   KID221     PSA_D                                  60                 60
162583   KID221     PSA_D                                  61                 61
162584   KID221     PSA_D                                  62                 62
162585   KID221     PSA_D                                  63                 63
162586   KID221     PSA_D                                  64                 64
162587   KID221     PSA_D                                  65                 65
162588   KID221     PSA_D                                  66                 66
162589   KID221     PSA_D                                  67                 67
162590   KID221     PSA_D                                  68                 68
162591   KID221     PSA_D                                  69                 69
162592   KID221     PSA_D                                  70                 70
162593   KID221     PSA_D                                  71                 71
162594   KID221     PSA_D                                  72                 72
162595   KID221     PSA_D                                  73                 73
162596   KID221     PSA_D                                  75                 75
162597   KID221     PSA_D                                  76                 76
162598   KID221     PSA_D                                  77                 77
162599   KID221     PSA_D                                  78                 78
162600   KID221     PSA_D                                  79                 79
162601   KID221     PSA_D                                  80                 80
162602   KID221     PSA_D                                  81                 81
162603   KID221     PSA_D                       85 or greater      85 or greater
162604   KID221     PSA_D                           < blank >            Missing
162725   KID221     PSA_F                             8 to 85    Range of Values
162726   KID221     PSA_F                                 777            Refused
162727   KID221     PSA_F                                 999         Don't know
162728   KID221     PSA_F                                   .            Missing
       Count
95207     56
95208      0
95209      0
95210   1451
162578     0
162579     0
162580     0
162581     0
162582     0
162583     0
162584     0
162585     0
162586     0
162587     0
162588     0
162589     0
162590     0
162591     0
162592     0
162593     0
162594     0
162595     0
162596     0
162597     0
162598     0
162599     0
162600     0
162601     0
162602     0
162603     3
162604     0
162725    95
162726     0
162727     0
162728  1881
```

## What to do about these?

The last example is of particular concern, because the `KID221`
variable clearly means different things in different
tables. Otherwise, these all look like legitimate issues, and there
are not many of them, so a possible workaround is to maintain an
explicit list of such variables and handle them while creating the
codebook. The least intrusive way would be to just insert a row with
value description `"Range of Values"`, and perhaps drop the value
descriptions which can be coerced to numeric.





# Codebook conversion problems

Ideally, each codebook (as returned by `nhanesCodebook()` should
contain one element for each variable in the table, where each element
is a list containing information about that variable. This information
currently consists of the 'SAS Label', 'English Text', and 'Target',
as recorded in the documentation files, along with a translation table
with descriptions of the codes used in the data.

The following functions checks to see if a given codebook satisfies
these expectations. In addition to checking for the presence of a
translation table, it flags cases where a potentially numeric variable
has unusual codes, accounting for some common non-response codes and
thresholding codes.


```r
acceptable <-
    c("Range of Values", "Missing", "No response", "Refused", "Refuse",
      "SP refused", "Could not obtain", "No Lab Result", "No lab specimen", 
      "Don't know", "Don't  Know", "Cannot be assessed",
      "Calculation cannot be determined", "Since birth",
      "Fill Value of Limit of Detection", "Below Limit of Detection",
      "None", "Never")
agelimits <-
    c("80 years or older", "85 years or older",
      ">= 80 years of age", ">= 85 years of age", "80 years of age and over",
      "9 or younger", "9 years or younger",
      "12 years or younger ", "14 years or younger",
      "45 years or older", "14 years or under",
      "60 years or older")
var_status <- function(v, cb) {
    x <- cb[[v]][[v]]
    if (is.null(x)) return(NA) # no info, usually for SEQN
    probablyNumeric <- "Range of Values" %in% x$Value.Description
    if (!probablyNumeric) return(TRUE) # OK - at least for now
    ok <- all(tolower(x$Value.Description) %in% tolower(c(acceptable, agelimits)))
    ok
}
find_conversion_problems <- function(nh_table)
{
    cb <- nhanesCodebook(nh_table)
    cb_status <- vapply(names(cb), var_status, logical(1), cb = cb)
    if (all(is.na(cb_status))) "INVALID CODEBOOK" # the whole table is problematic ?
    else lapply(cb[ !is.na(cb_status) & !cb_status ],
                function(x) x[[length(x)]][1:3])
}
```

These are used below to find potential problems in importing codebooks.


```r
tables <- nhanesQuery("select TableName from Metadata.QuestionnaireDescriptions")$TableName
status <- lapply(tables, find_conversion_problems)
```

```
Error in cb[[v]][[v]]: subscript out of bounds
```

```r
names(status) <- tables
```

```
Error: object 'status' not found
```

```r
keep <- sapply(status, length) > 0 # tables with some issues
```

```
Error in eval(expr, envir, enclos): object 'status' not found
```

```r
status <- status[keep]
```

```
Error in eval(expr, envir, enclos): object 'status' not found
```

```r
tables <- tables[keep]
```

```
Error in eval(expr, envir, enclos): object 'keep' not found
```

## Tables with no useful codebook in the database


```r
no_codebook <- sapply(status, identical, "INVALID CODEBOOK")
```

```
Error in eval(expr, envir, enclos): object 'status' not found
```

```r
cat(format(tables[no_codebook]), fill = TRUE)
```

```
Error in eval(expr, envir, enclos): object 'no_codebook' not found
```

`ALB_CR_G` is a known example where there are no translation tables;
this is not a problem because all variables are numeric and do not
require translation. Other instances should be investigated.


## Tables with unexpected value descriptions

Most of the remaining 'problems' arise from special numeric codes,
which are perhaps too many to deal with systematically, but do need to
be accounted for during analysis. They are listed below for reference.


```r
labels_df <- status[!no_codebook] |>
    do.call(what = c) |> do.call(what = rbind)
```

```
Error in eval(expr, envir, enclos): object 'status' not found
```

```r
## keep only value and description
labels_df <- labels_df[1:2]
```

```
Error in eval(expr, envir, enclos): object 'labels_df' not found
```

Next, we count the number of variables each description occurs in, and
sort by frequency.


```r
labels_df <- subset(labels_df, Value.Description != "Range of Values")
```

```
Error in eval(expr, envir, enclos): object 'labels_df' not found
```

```r
labels_split <- split(labels_df, ~ Value.Description)
```

```
Error in eval(expr, envir, enclos): object 'labels_df' not found
```

```r
labels_summary <-
    lapply(labels_split,
           function(d) with(d,
                            data.frame(Desc = substring(as.character(Value.Description)[[1]],
                                                        1, 45),
                                       Count = length(Value.Description),
                                       Codes = sort(unique(Code.or.Value))
                                                 |> paste(collapse = "/")
                                                 |> substring(1, 30)))) |>
    do.call(what = rbind)
```

```
Error in eval(expr, envir, enclos): object 'labels_split' not found
```


```r
options(width = 200)
rownames(labels_summary) <- NULL
```

```
Error: object 'labels_summary' not found
```

```r
labels_summary[order(labels_summary$Count, decreasing = TRUE), ]
```

```
Error in eval(expr, envir, enclos): object 'labels_summary' not found
```

