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
'data.frame':	177220 obs. of  7 variables:
 $ Variable        : chr  "DMAETHN" "DMAETHN" "DMARACE" "DMARACE" ...
 $ TableName       : chr  "DEMO" "DEMO" "DEMO" "DEMO" ...
 $ CodeOrValue     : chr  "1" "." "1" "." ...
 $ ValueDescription: chr  "Value Imputed" "Missing" "Value Imputed" "Missing" ...
 $ Count           : int  2 9963 2 9963 8069 1146 737 1 1 11 ...
 $ Cumulative      : int  2 9965 2 9965 8069 9215 9952 9953 9954 9965 ...
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
68980   490 
```

We will focus on these variables for now.


```r
problem_vars <- unique(numeric_cb[maybe_numeric, ]$Variable)
str(problem_vars)
```

```
 chr [1:235] "AUXR1K2L" "AUXR1K2R" "AUXR3KR" "BAXFTC12" "WTSPH01" "WTSPH02" ...
```

```r
length(num_cb_byVar <- numeric_cb |>
           subset(Variable %in% problem_vars) |>
           split(~ Variable))
```

```
[1] 235
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
AUXR1K2R  AUXR2KR  AUXR3KR  AUXR8KR BAXFTC12 CVDR3TIM  DR2LANG DRD370JQ  DUQ350Q 
       1        1        1        1        1        1        1        1        1 
  DUQ390   DXXSPY  LBDBANO  LBDEONO   LBDRPI   LBXV2P   LBXVDX   LBXVTP  MCQ240D 
       1        1        1        1        1        1        1        1        1 
MCQ240dk MCQ240DK  MCQ240H  MCQ240K  MCQ240l  MCQ240L  MCQ240m  MCQ240q  MCQ240v 
       1        1        1        1        1        1        1        1        1 
 MCQ240y OSD030cc OSD030cd  OSD110h  PFD069L   SSDBZP   SXQ267   SXQ410   SXQ550 
       1        1        1        1        1        1        1        1        1 
  SXQ836   SXQ841   URX1DC   URXMTO   URXOMO   URXP09   URXPTU   URXTCV   URXUBE 
       1        1        1        1        1        1        1        1        1 
WTSAF2YR WTSAF4YR  WTSHM01  WTSHM02  WTSHM03  WTSHM04  WTSHM05  WTSHM06  WTSHM07 
       1        1        1        1        1        1        1        1        1 
 WTSHM08  WTSHM09  WTSHM10  WTSHM11  WTSHM12  WTSHM13  WTSHM14  WTSHM15  WTSHM16 
       1        1        1        1        1        1        1        1        1 
 WTSHM17  WTSHM18  WTSHM19  WTSHM20  WTSHM21  WTSHM22  WTSHM23  WTSHM24  WTSHM25 
       1        1        1        1        1        1        1        1        1 
 WTSHM26  WTSHM27  WTSHM28  WTSHM29  WTSHM30  WTSHM31  WTSHM32  WTSHM33  WTSHM34 
       1        1        1        1        1        1        1        1        1 
 WTSHM35  WTSHM36  WTSHM37  WTSHM38  WTSHM39  WTSHM40  WTSHM41  WTSHM42  WTSHM43 
       1        1        1        1        1        1        1        1        1 
 WTSHM44  WTSHM45  WTSHM46  WTSHM47  WTSHM48  WTSHM49  WTSHM50  WTSHM51  WTSHM52 
       1        1        1        1        1        1        1        1        1 
 WTSPH01  WTSPH02  WTSPH03  WTSPH04  WTSPH05  WTSPH06  WTSPH07  WTSPH08  WTSPH09 
       1        1        1        1        1        1        1        1        1 
 WTSPH10  WTSPH11  WTSPH12  WTSPH13  WTSPH14  WTSPH15  WTSPH16  WTSPH17  WTSPH18 
       1        1        1        1        1        1        1        1        1 
 WTSPH19  WTSPH20  WTSPH21  WTSPH22  WTSPH23  WTSPH24  WTSPH25  WTSPH26  WTSPH27 
       1        1        1        1        1        1        1        1        1 
 WTSPH28  WTSPH29  WTSPH30  WTSPH31  WTSPH32  WTSPH33  WTSPH34  WTSPH35  WTSPH36 
       1        1        1        1        1        1        1        1        1 
 WTSPH37  WTSPH38  WTSPH39  WTSPH40  WTSPH41  WTSPH42  WTSPH43  WTSPH44  WTSPH45 
       1        1        1        1        1        1        1        1        1 
 WTSPH46  WTSPH47  WTSPH48  WTSPH49  WTSPH50  WTSPH51  WTSPH52  WTSPO01  WTSPO02 
       1        1        1        1        1        1        1        1        1 
 WTSPO03  WTSPO04  WTSPO05  WTSPO06  WTSPO07  WTSPO08  WTSPO09  WTSPO10  WTSPO11 
       1        1        1        1        1        1        1        1        1 
 WTSPO12  WTSPO13  WTSPO14  WTSPO15  WTSPO16  WTSPO17  WTSPO18  WTSPO19  WTSPO20 
       1        1        1        1        1        1        1        1        1 
 WTSPO21  WTSPO22  WTSPO23  WTSPO24  WTSPO25  WTSPO26  WTSPO27  WTSPO28  WTSPO29 
       1        1        1        1        1        1        1        1        1 
 WTSPO30  WTSPO31  WTSPO32  WTSPO33  WTSPO34  WTSPO35  WTSPO36  WTSPO37  WTSPO38 
       1        1        1        1        1        1        1        1        1 
 WTSPO39  WTSPO40  WTSPO41  WTSPO42  WTSPO43  WTSPO44  WTSPO45  WTSPO46  WTSPO47 
       1        1        1        1        1        1        1        1        1 
 WTSPO48  WTSPO49  WTSPO50  WTSPO51  WTSPO52 AUXR1K2L DRD370PQ   DUQ340   DUQ360 
       1        1        1        1        1        2        2        2        2 
 DUQ400Q MCQ240AA  MCQ240b  MCQ240T OSD030bf OSD030bg  OSD110f   SMD415  SMD415A 
       2        2        2        2        2        2        2        2        2 
  URX2DC DMDHHSZA DMDHHSZE  MCQ240Y OSD030ce  OSQ020a  RHQ602Q DMDHHSZB  MCQ240B 
       2        3        3        3        3        3        3        4        4 
OSD030ac  OSQ020c DMDFMSIZ DMDHHSIZ   HUD080  OSQ020b  ECD070A   HOD050   HSQ580 
       4        5        6        6        6        7       12       12       12 
  KID221 
      24 
```

To get a sense of the problem cases, we look at the variables with 10
or more numeric variables.


```r
num_cb_byVar[ names(which(nnum >= 10)) ]
```

```
$ECD070A
       Variable TableName CodeOrValue  ValueDescription Count
11426   ECD070A       ECQ           1                 1    36
11427   ECD070A       ECQ           2                 2    19
11428   ECD070A       ECQ           3                 3    39
11429   ECD070A       ECQ           4                 4    89
11430   ECD070A       ECQ           5                 5   264
11431   ECD070A       ECQ           6                 6   869
11432   ECD070A       ECQ           7                 7  1317
11433   ECD070A       ECQ           8                 8   805
11434   ECD070A       ECQ           9                 9   237
11435   ECD070A       ECQ          10                10    87
11436   ECD070A       ECQ          11                11    15
11437   ECD070A       ECQ          12                12     1
11438   ECD070A       ECQ          13 13 pounds or more     3
11439   ECD070A       ECQ          77           Refused     2
11440   ECD070A       ECQ          99        Don't know   133
11441   ECD070A       ECQ           .           Missing     5
24935   ECD070A     ECQ_B     1 to 12   Range of Values  4257
24936   ECD070A     ECQ_B          13 13 pounds or more     6
24937   ECD070A     ECQ_B        7777           Refused     0
24938   ECD070A     ECQ_B        9999        Don't know   141
24939   ECD070A     ECQ_B           .           Missing     1
44406   ECD070A     ECQ_C     1 to 12   Range of Values  3791
44407   ECD070A     ECQ_C          13 13 pounds or more     2
44408   ECD070A     ECQ_C        7777           Refused     1
44409   ECD070A     ECQ_C        9999        Don't know   113
44410   ECD070A     ECQ_C           .           Missing     2
62850   ECD070A     ECQ_D     1 to 12   Range of Values  4071
62851   ECD070A     ECQ_D          13 13 pounds or more     4
62852   ECD070A     ECQ_D        7777           Refused     1
62853   ECD070A     ECQ_D        9999        Don't know   131
62854   ECD070A     ECQ_D           .           Missing     2
76836   ECD070A     ECQ_E     1 to 12   Range of Values  3538
76837   ECD070A     ECQ_E          13 13 pounds or more     4
76838   ECD070A     ECQ_E        7777           Refused     0
76839   ECD070A     ECQ_E        9999        Don't know    60
76840   ECD070A     ECQ_E           .           Missing     1
96383   ECD070A     ECQ_F     1 to 12   Range of Values  3578
96384   ECD070A     ECQ_F          13 13 pounds or more     8
96385   ECD070A     ECQ_F        7777           Refused     0
96386   ECD070A     ECQ_F        9999        Don't know    62
96387   ECD070A     ECQ_F           .           Missing     0
112807  ECD070A     ECQ_G     1 to 12   Range of Values  3505
112808  ECD070A     ECQ_G          13 13 pounds or more     3
112809  ECD070A     ECQ_G        7777           Refused     1
112810  ECD070A     ECQ_G        9999        Don't know    72
112811  ECD070A     ECQ_G           .           Missing     0
140370  ECD070A     ECQ_H     1 to 12   Range of Values  3622
140371  ECD070A     ECQ_H          13 13 pounds or more     0
140372  ECD070A     ECQ_H        7777           Refused     0
140373  ECD070A     ECQ_H        9999        Don't know    88
140374  ECD070A     ECQ_H           .           Missing     1
158622  ECD070A     ECQ_I     4 to 10   Range of Values  3436
158623  ECD070A     ECQ_I           3  3 pounds or less    80
158624  ECD070A     ECQ_I          11 11 pounds or more    10
158625  ECD070A     ECQ_I        7777           Refused     2
158626  ECD070A     ECQ_I        9999        Don't know   116
158627  ECD070A     ECQ_I           .           Missing     0
173893  ECD070A     ECQ_J     4 to 10   Range of Values  2926
173894  ECD070A     ECQ_J           3  3 pounds or less    66
173895  ECD070A     ECQ_J          11 11 pounds or more    15
173896  ECD070A     ECQ_J        7777           Refused     0
173897  ECD070A     ECQ_J        9999        Don't know    85
173898  ECD070A     ECQ_J           .           Missing     1

$HOD050
       Variable TableName CodeOrValue ValueDescription Count
11725    HOD050       HOQ     1 to 12  Range of Values  9709
11726    HOD050       HOQ          13       13 or More    70
11727    HOD050       HOQ         777          Refused    12
11728    HOD050       HOQ         999       Don't know    13
11729    HOD050       HOQ           .          Missing   161
25473    HOD050     HOQ_B     1 to 12  Range of Values 10725
25474    HOD050     HOQ_B          13       13 or More    93
25475    HOD050     HOQ_B         777          Refused    19
25476    HOD050     HOQ_B         999       Don't know    28
25477    HOD050     HOQ_B           .          Missing   174
44820    HOD050     HOQ_C     1 to 12  Range of Values  9944
44821    HOD050     HOQ_C          13       13 or more    27
44822    HOD050     HOQ_C         777          Refused    10
44823    HOD050     HOQ_C         999       Don't know     8
44824    HOD050     HOQ_C           .          Missing   133
63427    HOD050     HOQ_D     1 to 12  Range of Values 10150
63428    HOD050     HOQ_D          13       13 or more    69
63429    HOD050     HOQ_D         777          Refused     5
63430    HOD050     HOQ_D         999       Don't know    15
63431    HOD050     HOQ_D           .          Missing   109
80551    HOD050     HOQ_E     1 to 12  Range of Values  9977
80552    HOD050     HOQ_E          13       13 or more    62
80553    HOD050     HOQ_E         777          Refused     4
80554    HOD050     HOQ_E         999       Don't know    12
80555    HOD050     HOQ_E           .          Missing    94
98759    HOD050     HOQ_F     1 to 12  Range of Values 10348
98760    HOD050     HOQ_F          13       13 or more    97
98761    HOD050     HOQ_F         777          Refused    13
98762    HOD050     HOQ_F         999       Don't know    11
98763    HOD050     HOQ_F           .          Missing    68
113746   HOD050     HOQ_G           1                1    63
113747   HOD050     HOQ_G           2                2   241
113748   HOD050     HOQ_G           3                3   924
113749   HOD050     HOQ_G           4                4  1863
113750   HOD050     HOQ_G           5                5  1972
113751   HOD050     HOQ_G           6                6  1709
113752   HOD050     HOQ_G           7                7  1117
113753   HOD050     HOQ_G           8                8   776
113754   HOD050     HOQ_G           9                9   410
113755   HOD050     HOQ_G          10               10   309
113756   HOD050     HOQ_G          11               11   162
113757   HOD050     HOQ_G          12               12    67
113758   HOD050     HOQ_G          13       13 or more    90
113759   HOD050     HOQ_G         777          Refused     4
113760   HOD050     HOQ_G         999       Don't know     0
113761   HOD050     HOQ_G           .          Missing    49
140914   HOD050     HOQ_H           1                1    88
140915   HOD050     HOQ_H           2                2   202
140916   HOD050     HOQ_H           3                3   683
140917   HOD050     HOQ_H           4                4  1613
140918   HOD050     HOQ_H           5                5  2093
140919   HOD050     HOQ_H           6                6  1922
140920   HOD050     HOQ_H           7                7  1272
140921   HOD050     HOQ_H           8                8   853
140922   HOD050     HOQ_H           9                9   574
140923   HOD050     HOQ_H          10               10   343
140924   HOD050     HOQ_H          11               11   197
140925   HOD050     HOQ_H          12               12   108
140926   HOD050     HOQ_H          13       13 or more    85
140927   HOD050     HOQ_H         777          Refused    16
140928   HOD050     HOQ_H         999       Don't know     5
140929   HOD050     HOQ_H           .          Missing   121
157813   HOD050     HOQ_I           1                1    49
157814   HOD050     HOQ_I           2                2   204
157815   HOD050     HOQ_I           3                3   831
157816   HOD050     HOQ_I           4                4  1810
157817   HOD050     HOQ_I           5                5  2071
157818   HOD050     HOQ_I           6                6  1728
157819   HOD050     HOQ_I           7                7  1130
157820   HOD050     HOQ_I           8                8   773
157821   HOD050     HOQ_I           9                9   434
157822   HOD050     HOQ_I          10               10   323
157823   HOD050     HOQ_I          11               11   133
157824   HOD050     HOQ_I          12               12    71
157825   HOD050     HOQ_I          13       13 or more    51
157826   HOD050     HOQ_I         777          Refused    34
157827   HOD050     HOQ_I         999       Don't know     0
157828   HOD050     HOQ_I           .          Missing   329
172577   HOD050     HOQ_J           1                1    78
172578   HOD050     HOQ_J           2                2   198
172579   HOD050     HOQ_J           3                3   713
172580   HOD050     HOQ_J           4                4  1693
172581   HOD050     HOQ_J           5                5  1848
172582   HOD050     HOQ_J           6                6  1562
172583   HOD050     HOQ_J           7                7  1115
172584   HOD050     HOQ_J           8                8   670
172585   HOD050     HOQ_J           9                9   415
172586   HOD050     HOQ_J          10               10   276
172587   HOD050     HOQ_J          11               11    79
172588   HOD050     HOQ_J          12               12    51
172589   HOD050     HOQ_J          13       13 or more    47
172590   HOD050     HOQ_J         777          Refused     8
172591   HOD050     HOQ_J         999       Don't know    27
172592   HOD050     HOQ_J           .          Missing   474

$HSQ580
       Variable TableName CodeOrValue ValueDescription Count
11007    HSQ580       HSQ     1 to 12  Range of Values   238
11008    HSQ580       HSQ          77          Refused     0
11009    HSQ580       HSQ          99       Don't know     8
11010    HSQ580       HSQ           .          Missing  8586
24589    HSQ580     HSQ_B     1 to 12  Range of Values   272
24590    HSQ580     HSQ_B          77          Refused     0
24591    HSQ580     HSQ_B          99       Don't know     2
24592    HSQ580     HSQ_B           .          Missing 10108
44001    HSQ580     HSQ_C     1 to 12  Range of Values   233
44002    HSQ580     HSQ_C          77          Refused     0
44003    HSQ580     HSQ_C          99       Don't know     3
44004    HSQ580     HSQ_C           .          Missing  9299
61746    HSQ580     HSQ_D     1 to 12  Range of Values   235
61747    HSQ580     HSQ_D          77          Refused     0
61748    HSQ580     HSQ_D          99       Don't know     4
61749    HSQ580     HSQ_D           .          Missing  9201
76954    HSQ580     HSQ_E     1 to 12  Range of Values   242
76955    HSQ580     HSQ_E          77          Refused     0
76956    HSQ580     HSQ_E          99       Don't know     5
76957    HSQ580     HSQ_E           .          Missing  9060
98461    HSQ580     HSQ_F     1 to 12  Range of Values   338
98462    HSQ580     HSQ_F          77          Refused     0
98463    HSQ580     HSQ_F          99       Don't know     3
98464    HSQ580     HSQ_F           .          Missing  9494
114444   HSQ580     HSQ_G     1 to 12  Range of Values   261
114445   HSQ580     HSQ_G          77          Refused     0
114446   HSQ580     HSQ_G          99       Don't know     0
114447   HSQ580     HSQ_G           .          Missing  8695
141559   HSQ580     HSQ_H           1                1    39
141560   HSQ580     HSQ_H           2                2    38
141561   HSQ580     HSQ_H           3                3    28
141562   HSQ580     HSQ_H           4                4    20
141563   HSQ580     HSQ_H           5                5    13
141564   HSQ580     HSQ_H           6                6    29
141565   HSQ580     HSQ_H           7                7    19
141566   HSQ580     HSQ_H           8                8    11
141567   HSQ580     HSQ_H           9                9    11
141568   HSQ580     HSQ_H          10               10    13
141569   HSQ580     HSQ_H          11               11    17
141570   HSQ580     HSQ_H          12               12    18
141571   HSQ580     HSQ_H          77          Refused     0
141572   HSQ580     HSQ_H          99       Don't know     4
141573   HSQ580     HSQ_H           .          Missing  9162
158006   HSQ580     HSQ_I           1                1    42
158007   HSQ580     HSQ_I           2                2    34
158008   HSQ580     HSQ_I           3                3    22
158009   HSQ580     HSQ_I           4                4    29
158010   HSQ580     HSQ_I           5                5    15
158011   HSQ580     HSQ_I           6                6    29
158012   HSQ580     HSQ_I           7                7    13
158013   HSQ580     HSQ_I           8                8    12
158014   HSQ580     HSQ_I           9                9     7
158015   HSQ580     HSQ_I          10               10    10
158016   HSQ580     HSQ_I          11               11     5
158017   HSQ580     HSQ_I          12               12    10
158018   HSQ580     HSQ_I          77          Refused     0
158019   HSQ580     HSQ_I          99       Don't know     2
158020   HSQ580     HSQ_I           .          Missing  8935
172557   HSQ580     HSQ_J           1                1    53
172558   HSQ580     HSQ_J           2                2    35
172559   HSQ580     HSQ_J           3                3    23
172560   HSQ580     HSQ_J           4                4    33
172561   HSQ580     HSQ_J           5                5    11
172562   HSQ580     HSQ_J           6                6    40
172563   HSQ580     HSQ_J           7                7    15
172564   HSQ580     HSQ_J           8                8    16
172565   HSQ580     HSQ_J           9                9     7
172566   HSQ580     HSQ_J          10               10    12
172567   HSQ580     HSQ_J          11               11    18
172568   HSQ580     HSQ_J          12               12     6
172569   HSQ580     HSQ_J          77          Refused     0
172570   HSQ580     HSQ_J          99       Don't know     5
172571   HSQ580     HSQ_J           .          Missing  8092

$KID221
      Variable TableName                         CodeOrValue   ValueDescription
40971   KID221  L11PSA_C Age at diagnosis of prostate cancer Value was recorded
40972   KID221  L11PSA_C                                 777            Refused
40973   KID221  L11PSA_C                                 999         Don't know
40974   KID221  L11PSA_C                           < blank >            Missing
59151   KID221     PSA_D                                   .                  .
59152   KID221     PSA_D                                  54                 54
59153   KID221     PSA_D                                  58                 58
59154   KID221     PSA_D                                  59                 59
59155   KID221     PSA_D                                  60                 60
59156   KID221     PSA_D                                  61                 61
59157   KID221     PSA_D                                  62                 62
59158   KID221     PSA_D                                  63                 63
59159   KID221     PSA_D                                  64                 64
59160   KID221     PSA_D                                  65                 65
59161   KID221     PSA_D                                  66                 66
59162   KID221     PSA_D                                  67                 67
59163   KID221     PSA_D                                  68                 68
59164   KID221     PSA_D                                  69                 69
59165   KID221     PSA_D                                  70                 70
59166   KID221     PSA_D                                  71                 71
59167   KID221     PSA_D                                  72                 72
59168   KID221     PSA_D                                  73                 73
59169   KID221     PSA_D                                  75                 75
59170   KID221     PSA_D                                  76                 76
59171   KID221     PSA_D                                  77                 77
59172   KID221     PSA_D                                  78                 78
59173   KID221     PSA_D                                  79                 79
59174   KID221     PSA_D                                  80                 80
59175   KID221     PSA_D                                  81                 81
59176   KID221     PSA_D                       85 or greater      85 or greater
59177   KID221     PSA_D                           < blank >            Missing
90484   KID221     PSA_F                             8 to 85    Range of Values
90485   KID221     PSA_F                                 777            Refused
90486   KID221     PSA_F                                 999         Don't know
90487   KID221     PSA_F                                   .            Missing
      Count
40971    56
40972     0
40973     0
40974  1451
59151     0
59152     0
59153     0
59154     0
59155     0
59156     0
59157     0
59158     0
59159     0
59160     0
59161     0
59162     0
59163     0
59164     0
59165     0
59166     0
59167     0
59168     0
59169     0
59170     0
59171     0
59172     0
59173     0
59174     0
59175     0
59176     3
59177     0
90484    95
90485     0
90486     0
90487  1881
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
names(status) <- tables
keep <- sapply(status, length) > 0 # tables with some issues
status <- status[keep]
tables <- tables[keep]
```

## Tables with no useful codebook in the database


```r
no_codebook <- sapply(status, identical, "INVALID CODEBOOK")
cat(format(tables[no_codebook]), fill = TRUE)
```

```
ALB_CR_G TELO_A   TELO_B   SSSAL_D 
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
## keep only value and description
labels_df <- labels_df[1:2]
```

Next, we count the number of variables each description occurs in, and
sort by frequency.


```r
labels_df <- subset(labels_df, Value.Description != "Range of Values")
labels_split <- split(labels_df, ~ Value.Description)
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


```r
options(width = 200)
rownames(labels_summary) <- NULL
labels_summary[order(labels_summary$Count, decreasing = TRUE), ]
```

```
                                             Desc Count                          Codes
92                                        Missing   816                              .
136                                       Refused   443 77/777/7777/77777/777777/77777
73                                     Don't know   394 99/999/9999/99999/999999/99999
1                                               0   162                              0
67                              Compliance <= 0.2    32                            555
68                               Could not obtain    32                            888
59                                          900 +    27                            900
83                              Less than 1 month    26                          0/666
70       Day 1 dietary recall not done/incomplete    24                              0
71       Day 2 dietary recall not done/incomplete    24                              0
104                                         Never    22                              0
60                          95 cigarettes or more    21                             95
122                                          None    18                              0
134                 Provider did not specify goal    18                           6666
27                                   2000 or more    17                           2000
3                             1 cigarette or less    15                              1
108                        Never on a daily basis    15                              0
131    Participants 6+ years with no lab specimen    13                              0
29                                      3 or More    12                              3
146           Value greater than or equal to 5.00    12                              5
45                                      7 or more    11                              7
53                              80 years or older    11                             80
6                                    1-14 minutes    10                             14
49                                     70 or more    10                             70
54                                  8400 and over    10                           8400
74                                     Don't Know    10                           9999
80         First Below Detection Limit Fill Value    10             0.01/0.18/0.25/1.4
111             Never smoked cigarettes regularly    10                              0
118                               No modification    10                              0
119                        No time spent outdoors    10                              0
121                                Non-Respondent    10                              0
137       Second Below Detection Limit Fill Value    10           0.009/0.21/0.28/1.25
141                           Still breastfeeding    10                              0
142                        Still drinking formula    10                              0
9                                     100 or more     9                            100
64               Below Detection Limit Fill Value     9                  0.14/1.25/2/4
98                    More than 21 meals per week     9                           5555
28                                      3 or more     8                              3
84                               Less than 1 year     8                            666
88                             Less than one hour     8                              0
4                                 1 month or less     7                              1
18                              13 pounds or more     7                             13
24                               20 or more times     7                             20
39                                6 years or less     7                              6
47              7 or more people in the Household     7                              7
57                              85 years or older     7                             85
76                            Don't know/not sure     7                           9999
81         First Fill Value of Limit of Detection     7 -0.001/-0.01/-0.02/-0.03/-0.07
138       Second Fill Value of Limit of Detection     7 -0.004/-0.02/-0.04/-0.05/-0.23
8                                           100 +     6                            100
10                                     11 or more     6                             11
13                              11 years or under     6                             11
21                              19 years or under     6                             19
43                              60 years or older     6                             60
62         At or below detection limit fill value     6       0.01/0.04/0.07/0.21/6.36
77                                      Dont Know     6                           9999
95               More than 1095 days (3-year) old     6                         666666
105                    Never had cholesterol test     6                           6666
107                            Never heard of LDL     6                           5555
110                Never smoked a whole cigarette     6                             55
126   Participants 12+ years with no lab specimen     6                              0
135                                        Refuse     6                            777
14                               12 hours or more     5                             12
23                                     20 or more     5                             20
38                                6 times or more     5                              6
40                               6 years or under     5                              6
63  At work or at school 9 to 5 seven days a week     5                           3333
72                  Does not work or go to school     5                           3333
82                             Hasn't started yet     5                              0
15                            12 years or younger     4                             12
16                                     13 or more     4                             13
32                                     40 or more     4                             40
46                 7 or more people in the Family     4                              7
69  Current HH FS benefits recipient last receive     4                          55555
90                               Less than weekly     4                           6666
103                 More than 90 times in 30 days     4                           6666
120 Non-current HH FS benefits recipient last rec     4                          66666
133       PIR value greater than or equal to 5.00     4                              5
145                                    Ungradable     4                              2
11                                     11 or More     3                             11
33                                     40 or More     3                             40
36                               50 years or more     3                          66666
56                                    85 or older     3                             85
61                                     95 or more     3                             95
78                                        English     3                              1
79                            English and Spanish     3                              3
89                             Less than one year     3                            666
94                   More than 1 year unspecified     3                            555
109                 Never smoked a pipe regularly     3                              0
112                 Never smoked cigars regularly     3                              0
113          Never used chewing tobacco regularly     3                              0
114                    Never used snuff regularly     3                              0
115 No Lab Result or Not Fasting for 8 to <24 hou     3                              0
116                                No lab samples     3                              0
123                              Not MEC Examined     3                              0
125                                         Other     3                              4
140                                       Spanish     3                              2
144                 Unable to do activity (blind)     3                            666
12                              11 pounds or more     2                             11
17                                     13 or More     2                             13
19                               14 hours or more     2                             14
20                              15 drinks or more     2                             15
26                              20 years or older     2                             20
30                               3 pounds or less     2                              3
35                             480 Months or more     2                            480
37                               500 mg or higher     2                            500
41                             60 minutes or more     2                             60
44                             600 Months or more     2                            600
50                                      70 to 150     2                             70
51                               80 Hours or more     2                             80
55                            85 or greater years     2                             85
65                 Below First Limit of Detection     2                        0.1/0.5
66                Below Second Limit of Detection     2                       0.14/0.7
75               Don't know what is 'whole grain'     2                       66666666
86                              Less than monthly     2                          66666
91                              Less then 3 hours     2                              2
93                                More than $1000     2                          55555
97                                   More than 21     2                           5555
100                            More than 300 days     2                          55555
101               More than 365 days (1-year) old     2                         666666
102               More than 730 days (2-year) old     2                         666666
106                       Never heard of A1C test     2                            666
117                                No Lab samples     2                              0
124                  Not tested in last 12 months     2                              0
128    Participants 3+ years with no lab specimen     2                              0
139                          Single person family     2                            666
2                                      0-5 Months     1                              5
5                                  1 year or less     1                              1
7                                       1-5 Hours     1                              5
22                                20 days or more     1                             20
25                                      20 to 150     1                             20
31                                      4 or more     1                              4
34                                   400 and over     1                            400
42                              60 or more months     1                            666
48                                7 years or less     1                              7
52                            80 or greater years     1                             80
58                                     9 or fewer     1                              9
85                      Less than 10 years of age     1                              1
87                              Less than one day     1                              0
96                     More than 20 times a month     1                             30
99                    More than 21 times per week     1                           5555
127      Participants 3+ years with no Lab Result     1                              0
129 Participants 3+ years with no surplus lab spe     1                              0
130      Participants 6+ years with no Lab Result     1                              0
132   Participants 6+ years with no lab specimen.     1                              0
143        Third Fill Value of Limit of Detection     1                          -0.03
```

