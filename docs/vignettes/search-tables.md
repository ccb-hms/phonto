---
layout: default
title: "Searching NHANES Variables and Tables"
editor_options: 
  chunk_output_type: console
---



A broad overview of data collected as part of continuous NHANES is
described in the [survey content
brochure](https://wwwn.cdc.gov/nchs/data/nhanes/survey_contents.pdf),
and the NHANES website has a [variable search
interface](https://wwwn.cdc.gov/nchs/nhanes/search/default.aspx) as
well. This document describes how local interactive searches can be
performed using downloaded and processed variable metadata
information.


# Manifest of available variables

The NHANES data consist of multiple tables over multiple cycles, each
with a set of recorded variables. The variable names themselves are
cryptic, and not useful as search terms. Fortunately, the NHANES
website provides comprehensive details about these variables in the
form of tables, grouped by components such as
[Demographics](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Demographics),
[Laboratory](https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Laboratory),
etc.

The __nhanesA__ package can download these tables and make the information
contained in them available as a data frame using the
`nhanesManifest()` function.


```r
library(nhanesA)
library(phonto)
varmf <- nhanesManifest("variables")
```

This downloads and combines several large web pages, so it may take a
little time to run. Add `verbose = TRUE` to see some indication of
what is happening.

While useful, this table has limited information. The most useful
component, the variable description, sometimes (but not always)
records instructions and can be quite long. 



```r
sum(nchar(varmf$VarDesc) == 0)
```

```
[1] 181
```

After reordering the remaining rows by the length of the descriptions,
the first few rows are given by


```r
varmf <- subset(varmf, nzchar(varmf$VarDesc))
varmf <- varmf[ order(nchar(varmf$VarDesc)), ]
head(varmf)
```

```
      VarName VarDesc    Table                                                                  TableDesc BeginYear EndYear   Component UseConstraints
30996  PFCAGE     Age PFC_Pool                       Polyfluoroalkyl Chemicals - Pooled Samples (Surplus)      2001    2002  Laboratory           None
34173   SSHCB     HCB  SSPST_B Pesticides - Organochlorine Metabolites - Serum - Pooled Samples (Surplus)      2001    2002  Laboratory           None
9926   LEAARM    Arm:  LEXABPI              Lower Extremity Disease - Ankle Brachial Blood Pressure Index      1999    2000 Examination           None
31002 PFCRACE    Race PFC_Pool                       Polyfluoroalkyl Chemicals - Pooled Samples (Surplus)      2001    2002  Laboratory           None
32851  SSBETA    Beta  SSNH3OL        Monoclonal gammopathy of undetermined significance (MGUS) (Surplus)      1988    1994  Laboratory           None
32875  SSBETA    Beta   SSOL_A        Monoclonal gammopathy of undetermined significance (MGUS) (Surplus)      1999    2000  Laboratory           None
```

The last few rows have considerably longer descriptions.


```r
unique(tail(varmf, 30)$VarDesc)
```

```
 [1] "The following questions ask about use of drugs not prescribed by a doctor. Please remember that your answers to these questions are strictly confidential. The first questions are about marijuana and hashish. Marijuana is also called pot or grass. Marijuana is usually smoked, either in cigarettes, called joints, or in a pipe. It is sometimes cooked in food. Hashish is a form of marijuana that is also called 'hash.' It is usually smoked in a pipe. Another form of hashish is hash oil. Have you ever, even once, used marijuana or hashish?"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
 [2] "Next I am going to ask you about the time {you spend/SP spends} doing different types of physical activity in a typical week. Think first about the time {you spend/he spends/she spends} doing work.  Think of work as the things that {you have/he has/she has} to do such as paid or unpaid work,  household chores, and yard work.  Does {your/SP's} work involve vigorous-intensity activity that causes large increases in breathing or heart rate like carrying or lifting heavy loads, digging or construction work for at least 10 minutes continuously?"                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
 [3] "The next questions are about the food eaten by {you/you and your household}.  {When answering these questions, think about all the people who eat here, even if they are not related to you.}  Which of these statements best describes the food eaten {by you/ in your household} in the last 12 months, that is since {DISPLAY CURRENT MONTH} of last year.  1.  {I/We} always have enough to eat and the kinds of food {I/we} want; 2.  {I/We} have enough to eat but not always the kinds of food {I/we} want; 3.  Sometimes  or often {I/we} don't have enough to eat."                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
 [4] "There are three ways in which attacks of the sort we have been discussing can affect a person's life and activities. First, the attacks themselves can be incapacitating. Second, worry about having additional attacks can get in the way of daily activities. And, third, avoiding certain situations for fear of having additional attacks can interfere with daily activities. Think about all three of these ways in which your life and activities were affected in the past 12 months. Did these things interfere with your life or activities -- a lot, some, a little, or not at all?"                                                                                                                                                                                                                                                                                                                                                                                                                                                
 [5] "Attacks of this sort can occur in three different situations. The first are when they occur \"out of the blue\" for no reason. The second are when they occur in situations where a person has an unreasonably strong fear. For example, some people have a terrible fear of bugs or heights or being in a crowd. The third are situations where a person is in real danger, like a car accident or a bank robbery. The next question is about how many of your (# FROM CIQP14) attacks occurred in each of these three kinds of situations. First, in your lifetime, about how many attacks have you had \"out of the blue\" for no reason?"                                                                                                                                                                                                                                                                                                                                                                                                  
 [6] "The purpose of this next set of questions is to find out if {you generally have/SP generally has} difficulty carrying out certain activities because {you are/s/he is} too sleepy or tired.  When the words 'sleepy' or 'tired' are used, it means the feeling that {you/s/he} can't keep {your/his/her} eyes open, {your/his/her} head is droopy, that {you/s/he} want to 'nod off' or that {you feel/s/he feels} the urge to take a nap.  The words do not refer to the tired or fatigued feeling {you/she} may have after {you have/s/he has} exercised.   {Do you/Does SP} have difficulty concentrating on the things {you do/s/he does} because {you feel/s/he feels} sleepy or tired?"                                                                                                                                                                                                                                                                                                                                                  
 [7] "Now I want to ask you some questions about other things ________ may have done that can get people into trouble.<p>\r\n\r\nFor this set of questions I will start off by asking if [he/she] has done something at any time in [his/her] life, and then I'll ask whether [he/she] did it in the last year   that is, since [[NAME EVENT]/[NAME CURRENT MONTH] of last year].<p>\r\n\r\nSome of the questions are very personal, but all of your answers are confidential and won't be repeated to anyone else.<p>\r\n\r\nThinking about [his/her] whole life, has ________ ever secretly stolen money or other  things from [you (or [his/her] family)/[his/her] family] or from other people [he/she] lives  with?"                                                                                                                                                                                                                                                                                                                            
 [8] "These next questions are about noise at work. First we are going to ask about loud noise. Loud means so loud that {you/s/he} must speak in a raised voice to be heard by someone three feet away when not using hearing protection. After that we will ask about very loud noise. Very loud noise is noise that is so loud {you have/he has/she has} to shout to be heard by someone three feet away when not using hearing protection.\r\nHow many days per month {are you/is SP} usually exposed to loud noise at {your/his/her} job as a(n) {OCCUPATION} for {EMPLOYER}? (Loud means so loud that {you/s/he} must speak in a raised voice to be heard by someone three feet away when not using hearing protection.)"                                                                                                                                                                                                                                                                                                                       
 [9] "The next questions are about physical activities including exercise, sports, and physically active hobbies that {you/SP} may have done in {your/his/her} leisure time or at school over the past 30 days.  First I will ask you about vigorous activities that cause heavy sweating or large increases in breathing or heart rate.  Then I will ask you about moderate activities that cause only light sweating or a slight to moderate increase in breathing or heart rate.  Over the past 30 days, did {you/SP} do any vigorous activities for at least 10 minutes that caused heavy sweating, or large increases in breathing or heart rate?  Some examples are running, lap swimming, aerobics classes or fast bicycling."                                                                                                                                                                                                                                                                                                                
[10] "These next questions are about noise exposure at work. First we are going to ask about loud noise. Loud means so loud that {you/s/he} must speak in a raised voice to be heard by someone three feet away when not using hearing protection. After that we will ask about very loud noise. Very loud noise is noise that is so loud {you have/he has/she has} to shout in order to be understood by someone standing 3 feet away from {you/him/her} when not using hearing protection. {Have you/Has SP} ever had a job, or combination of jobs where {you were/s/he was} exposed to loud sounds or noise for 4 or more hours a day, several days a week? (Loud means so loud that {you/s/he} must speak in a raised voice to be heard.)"                                                                                                                                                                                                                                                                                                      
[11] "Next I am going to ask you about the time {you spend/SP spends} doing different types of physical activity in a typical week.  Please answer these questions even if {you do not consider yourself/SP does not consider himself/herself} to be a physically active person.  Think first about the time {you spend/SP spends} doing work.  Think of work as the things that {you have/SP has} to do such as paid or unpaid work, studying or training, household chores, and yard work.  In answering the following questions, 'vigorous-intensity activities' are activities that require hard physical effort and cause large increases in breathing or heart rate, and 'moderate-intensity activities' are activities that require moderate physical effort and cause small increases in breathing or heart rate.  Does {your/SP's} work involve vigorous-intensity activity that causes large increases in breathing or heart rate like carrying or lifting heavy loads, digging or construction work for at least 10 minutes continuously?"
```

More useful and concise descriptions are available in the per-table
documentation, which can be accessed using the `nhanesCodebook()`
function and summarized using the `nhanesTableSummary()` function. For
example, a summary of the `DEMO_C` table if given by the following.


```r
nhanesTableSummary("DEMO_C", use = "both")
```

```
    table  varname                                   label nobs_cb na_cb has_range nlevels  skip nobs_data na_data  size   num   cat unique
1  DEMO_C     SEQN              Respondent sequence number      NA    NA        NA      NA    NA     10122       0 40536  TRUE FALSE   TRUE
2  DEMO_C SDDSRVYR                     Data Release Number   10122     0     FALSE       2 FALSE     10122       0 81104 FALSE  TRUE  FALSE
3  DEMO_C RIDSTATR            Interview/Examination Status   10122     0     FALSE       3 FALSE     10122       0 81200 FALSE  TRUE  FALSE
4  DEMO_C RIDEXMON                   Six month time period   10122   479     FALSE       3 FALSE     10122     479 81184 FALSE  TRUE  FALSE
5  DEMO_C RIAGENDR                                  Gender   10122     0     FALSE       3 FALSE     10122       0 81136 FALSE  TRUE  FALSE
6  DEMO_C RIDAGEYR   Age at Screening Adjudicated - Recode   10122     0      TRUE       3 FALSE     10122       0 81024  TRUE FALSE  FALSE
7  DEMO_C RIDAGEMN                  Age in Months - Recode   10122   223      TRUE       2 FALSE     10122     223 81024  TRUE FALSE  FALSE
8  DEMO_C RIDAGEEX             Exam Age in Months - Recode   10122   692      TRUE       2 FALSE     10122     692 81024  TRUE FALSE  FALSE
9  DEMO_C RIDRETH1                 Race/Ethnicity - Recode   10122     0     FALSE       6 FALSE     10122       0 81424 FALSE  TRUE  FALSE
10 DEMO_C RIDRETH2      Linked NH3 Race/Ethnicity - Recode   10122     0     FALSE       6 FALSE     10122       0 81424 FALSE  TRUE  FALSE
11 DEMO_C DMQMILIT                 Veteran/Military Status   10122  4196     FALSE       5 FALSE     10122    4196 81192 FALSE  TRUE  FALSE
12 DEMO_C  DMDBORN               Country of Birth - Recode   10122     0     FALSE       6 FALSE     10122       0 81304 FALSE  TRUE  FALSE
13 DEMO_C DMDCITZN                      Citizenship Status   10122     0     FALSE       5 FALSE     10122       0 81256 FALSE  TRUE  FALSE
14 DEMO_C DMDYRSUS                    Length of time in US   10122  8678     FALSE      13 FALSE     10122    8678 81944 FALSE  TRUE  FALSE
15 DEMO_C DMDEDUC3   Education Level - Children/Youth 6-19   10122  6785     FALSE      21 FALSE     10122    6785 82368 FALSE  TRUE  FALSE
16 DEMO_C DMDEDUC2            Education Level - Adults 20+   10122  5081     FALSE       8 FALSE     10122    5081 81592 FALSE  TRUE  FALSE
17 DEMO_C  DMDEDUC        Education - Recode (old version)   10122  1744     FALSE       6 FALSE     10122    1744 81400 FALSE  TRUE  FALSE
18 DEMO_C DMDSCHOL                   Now attending school?   10122  6995     FALSE       6 FALSE     10122    6995 81296 FALSE  TRUE  FALSE
19 DEMO_C DMDMARTL                          Marital Status   10122  3356     FALSE       9 FALSE     10122    3356 81408 FALSE  TRUE  FALSE
20 DEMO_C DMDHHSIZ Total number of people in the Household   10122     0      TRUE       3 FALSE     10122       0 81024  TRUE FALSE  FALSE
21 DEMO_C INDHHINC                 Annual Household Income   10122   629     FALSE      16 FALSE     10122     629 82136 FALSE  TRUE  FALSE
22 DEMO_C INDFMINC                    Annual Family Income   10122   158     FALSE      16 FALSE     10122     158 82136 FALSE  TRUE  FALSE
23 DEMO_C INDFMPIR                              Family PIR   10122   587      TRUE       3 FALSE     10122     587 81024  TRUE FALSE  FALSE
24 DEMO_C RIDEXPRG       Pregnancy Status at Exam - Recode   10122  6992     FALSE       4 FALSE     10122    6992 81376 FALSE  TRUE  FALSE
25 DEMO_C DMDHRGND                    HH Ref Person Gender   10122     1     FALSE       3 FALSE     10122       1 81136 FALSE  TRUE  FALSE
26 DEMO_C DMDHRAGE                       HH Ref Person Age   10122     1      TRUE       3 FALSE     10122       1 81024  TRUE FALSE  FALSE
27 DEMO_C DMDHRBRN          HH Ref Person Country of Birth   10122   354     FALSE       6 FALSE     10122     354 81248 FALSE  TRUE  FALSE
28 DEMO_C DMDHREDU           HH Ref Person Education Level   10122   354     FALSE       8 FALSE     10122     354 81592 FALSE  TRUE  FALSE
29 DEMO_C DMDHRMAR            HH Ref Person Marital Status   10122   289     FALSE       9 FALSE     10122     289 81528 FALSE  TRUE  FALSE
30 DEMO_C DMDHSEDU  HH Ref Person's Spouse Education Level   10122  4741     FALSE       8 FALSE     10122    4741 81592 FALSE  TRUE  FALSE
31 DEMO_C  SIALANG                Language of SP Interview   10122     0     FALSE       3 FALSE     10122       0 81136 FALSE  TRUE  FALSE
32 DEMO_C SIAPROXY             Proxy used in SP Interview?   10122     0     FALSE       3 FALSE     10122       0 81136 FALSE  TRUE  FALSE
33 DEMO_C SIAINTRP       Interpreter used in SP Interview?   10122     0     FALSE       3 FALSE     10122       0 81136 FALSE  TRUE  FALSE
34 DEMO_C  FIALANG            Language of Family Interview   10122   139     FALSE       3 FALSE     10122     139 81136 FALSE  TRUE  FALSE
35 DEMO_C FIAPROXY         Proxy used in Family Interview?   10122   139     FALSE       3 FALSE     10122     139 81136 FALSE  TRUE  FALSE
36 DEMO_C FIAINTRP   Interpreter used in Family Interview?   10122   139     FALSE       3 FALSE     10122     139 81136 FALSE  TRUE  FALSE
37 DEMO_C  MIALANG               Language of MEC Interview   10122  3689     FALSE       3 FALSE     10122    3689 81136 FALSE  TRUE  FALSE
38 DEMO_C MIAPROXY            Proxy used in MEC Interview?   10122  3689     FALSE       3 FALSE     10122    3689 81136 FALSE  TRUE  FALSE
39 DEMO_C MIAINTRP      Interpreter used in MEC Interview?   10122  3689     FALSE       3 FALSE     10122    3689 81136 FALSE  TRUE  FALSE
40 DEMO_C  AIALANG             Language of ACASI Interview   10122  5413     FALSE       3 FALSE     10122    5413 81136 FALSE  TRUE  FALSE
41 DEMO_C WTINT2YR     Full Sample 2 Year Interview Weight   10122     0      TRUE       2 FALSE     10122       0 81024  TRUE FALSE  FALSE
42 DEMO_C WTMEC2YR      Full Sample 2 Year MEC Exam Weight   10122     0      TRUE       2 FALSE     10122       0 81024  TRUE FALSE  FALSE
43 DEMO_C  SDMVPSU              Masked Variance Pseudo-PSU   10122     0      TRUE       2 FALSE     10122       0 81024  TRUE FALSE  FALSE
44 DEMO_C SDMVSTRA          Masked Variance Pseudo-Stratum   10122     0      TRUE       2 FALSE     10122       0 81024  TRUE FALSE  FALSE
```

This collects information from the codebook and supplements it with
information from the actual data, such as the number of non-missing
observations. Combining such information across all available tables
is generally time-consuming, but is considerably easier when the data
are available in the form of a database. 

# Summarizing variables using the SQL database

<!-- 

These are useful: should we have a R function to get these in phonto?

phonto::nhanesQuery("select * from Metadata.QuestionnaireDescriptions") |> str()
phonto::nhanesQuery("select * from Metadata.QuestionnaireVariables") |> str()
phonto::nhanesQuery("select * from Metadata.VariableCodebook") |> str()

-->

Basic information about all tables can be obtained using
`nhanesManifest("public")`, but also from the database using a SQL
query as follows.


```r
tableDesc <- nhanesQuery("select * from Metadata.QuestionnaireDescriptions")
subset(tableDesc, BeginYear == 1999, select = -c(DocFile, DataFile)) |> head(10)
```

```
                                                  Description TableName BeginYear EndYear     DataGroup UseConstraints      DatePublished
1                                               Acculturation       ACQ      1999    2000 Questionnaire           None          June 2002
11                                   Analgesic Pain Relievers   RXQ_ANA      1999    2000 Questionnaire           None          June 2002
12         Anti-Mullerian Hormone (AMH) & Inhibin-B (Surplus)   SSAMH_A      1999    2000    Laboratory           None Updated April 2022
26                                                    Balance       BAQ      1999    2000 Questionnaire           None          June 2002
44                                     Cardiovascular Fitness       CVX      1999    2000   Examination           None          June 2004
49                          Cholesterol - LDL & Triglycerides   LAB13AM      1999    2000    Laboratory           None Updated March 2007
69                                      Current Health Status       HSQ      1999    2000 Questionnaire           None          June 2002
74               Cytomegalovirus Antibodies - Serum (Surplus)   SSCMV_A      1999    2000    Laboratory           None Updated April 2022
78                                                Dermatology       DEQ      1999    2000 Questionnaire           None          June 2002
104 Dietary Supplement Use 30-Day - File 1, Supplement Counts  DSQFILE1      1999    2000       Dietary           None  Updated July 2009
```

Having a searchable list of these table descriptions can by itself be
useful. Such a table is available
[here](../tables/table-summary.html), and is created using [this R
script](../scripts/generate-table-summary.R). Instead of having one
row per table, this list combines multiple cycles for the same _base_
table name and description, and includes the dimensions of each
dataset.

We can now apply the `nhanesTableSummary()` function on each of these
tables. The essential code for this, accounting for the possibility of
errors, is


```r
table_summary <- function(x) {
    try(nhanesTableSummary(x, use = "both"), silent = TRUE)
}
table_details <- sapply(sort(tablemf$TableName), table_summary, simplify = FALSE)
nhanesVarSummary <-
    table_details[!sapply(table_details, inherits, "try-error")] |>
        do.call(what = rbind)
```



This results in a fairly large data frame.


```r
str(nhanesVarSummary)
```

```
'data.frame':	46194 obs. of  14 variables:
 $ table    : chr  "AA_H" "AA_H" "AA_H" "AA_H" ...
 $ varname  : chr  "SEQN" "WTSA2YR" "URX1NP" "URD1NPLC" ...
 $ label    : chr  "Respondent sequence number" "Subsample A Weights" "1-Aminonaphthalene urine (pg/mL)" "1-Aminonaphthalene urine Comment Code" ...
 $ nobs_cb  : int  NA 2755 2755 2755 2755 2755 2755 2755 2755 2755 ...
 $ na_cb    : num  NA 0 277 277 267 267 263 263 423 423 ...
 $ has_range: logi  NA TRUE TRUE FALSE TRUE FALSE ...
 $ nlevels  : int  NA 3 2 4 2 4 2 4 2 4 ...
 $ skip     : logi  NA FALSE FALSE FALSE FALSE FALSE ...
 $ nobs_data: int  2755 2755 2755 2755 2755 2755 2755 2755 2755 2755 ...
 $ na_data  : int  0 0 277 277 267 267 263 263 423 423 ...
 $ size     : num  11072 22088 22088 22248 22088 ...
 $ num      : logi  TRUE TRUE TRUE FALSE TRUE FALSE ...
 $ cat      : logi  FALSE FALSE FALSE TRUE FALSE TRUE ...
 $ unique   : logi  TRUE FALSE FALSE FALSE FALSE FALSE ...
```

However, as variables are repeated for each cycle, the number of
_unique_ variables is considerably smaller, especially if we split
them according to the component or data group.


```r
rownames(tableDesc) <- tableDesc$TableName
nhanesVarSummary$DataGroup <- tableDesc[nhanesVarSummary$table, "DataGroup"]
unique(nhanesVarSummary[c("varname", "DataGroup")]) |>
    xtabs(~ DataGroup, data = _)
```

```
DataGroup
 Demographics       Dietary   Examination    Laboratory Questionnaire 
          175          1182          4791          2766          3373 
```

Having variable-level information in a data frame like this allows us
to perform interactive searches in R quite easily. For example, we
could search for variables related to blood pressure or hypertension recorded in the 
third cycle as follows.


```r
nhanesVarSummary <- within(nhanesVarSummary, label <- tolower(label))
subset(nhanesVarSummary, endsWith(table, "_C") &
                         (grepl("hypertension", label) |
                          grepl("blood pressure", label)))
```

```
      table  varname                                    label nobs_cb na_cb has_range nlevels  skip nobs_data na_data  size   num   cat unique     DataGroup
8550  BPQ_C   BPQ010    last blood pressure reading by doctor    6213     0     FALSE       8  TRUE      6213       0 50192 FALSE  TRUE  FALSE Questionnaire
8551  BPQ_C   BPQ020    ever told you had high blood pressure    6213    75     FALSE       5  TRUE      6213      75 49928 FALSE  TRUE  FALSE Questionnaire
8552  BPQ_C   BPQ030  told had high blood pressure - 2+ times    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8553  BPQ_C  BPQ040A     taking prescription for hypertension    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8554  BPQ_C  BPQ040B  told to control weight for hypertension    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8555  BPQ_C  BPQ040C   told to reduce sodium for hypertension    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8556  BPQ_C  BPQ040D   told to exercise more for hypertension    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8557  BPQ_C  BPQ040E  told to reduce alcohol for hypertension    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8558  BPQ_C  BPQ040F told to do other things for hypertension    6213  4412     FALSE       5 FALSE      6213    4412 49928 FALSE  TRUE  FALSE Questionnaire
8559  BPQ_C  BPQ043A    told to stop smoking for hypertension    6213  6146     FALSE       4 FALSE      6213    6146 49816 FALSE  TRUE  FALSE Questionnaire
8753  BPX_C PEASCST1                    blood pressure status    9643     0     FALSE       4 FALSE      9643       0 77376 FALSE  TRUE  FALSE   Examination
8754  BPX_C PEASCTM1           blood pressure time in seconds    9643   306      TRUE       2 FALSE      9643     306 77192  TRUE FALSE  FALSE   Examination
8755  BPX_C PEASCCT1                   blood pressure comment    9643  9194     FALSE      10 FALSE      9643    9194 77856 FALSE  TRUE  FALSE   Examination
11522 CVX_C   CVAARM  arm selected for blood pressure monitor    4663  1451     FALSE       4 FALSE      4663    1451 37464 FALSE  TRUE  FALSE   Examination
11523 CVX_C  CVACUFF     cuff size for blood pressure monitor    4663  1451     FALSE       4 FALSE      4663    1451 37528 FALSE  TRUE  FALSE   Examination
29806 MCQ_C  MCQ250F    blood relatives w/hypertension/stroke    9645  4605     FALSE       5  TRUE      9645    4605 77384 FALSE  TRUE  FALSE Questionnaire
29844 MCQ_C MCQ260FA       blood relative-hypertension-mother    9645  8974     FALSE       4  TRUE      9645    8974 77328 FALSE  TRUE  FALSE Questionnaire
29845 MCQ_C MCQ260FB       blood relative-hypertension-father    9645  9160     FALSE       2  TRUE      9645    9160 77264 FALSE  TRUE  FALSE Questionnaire
29846 MCQ_C MCQ260FC blood relative-hypertension-mom's mother    9645  9468     FALSE       2  TRUE      9645    9468 77272 FALSE  TRUE  FALSE Questionnaire
29847 MCQ_C MCQ260FD blood relative-hypertension-mom's father    9645  9543     FALSE       2  TRUE      9645    9543 77272 FALSE  TRUE  FALSE Questionnaire
29848 MCQ_C MCQ260FE blood relative-hypertension-dad's mother    9645  9566     FALSE       2  TRUE      9645    9566 77272 FALSE  TRUE  FALSE Questionnaire
29849 MCQ_C MCQ260FF blood relative-hypertension-dad's father    9645  9582     FALSE       2  TRUE      9645    9582 77272 FALSE  TRUE  FALSE Questionnaire
29850 MCQ_C MCQ260FG      blood relative-hypertension-brother    9645  9445     FALSE       2  TRUE      9645    9445 77264 FALSE  TRUE  FALSE Questionnaire
29851 MCQ_C MCQ260FH       blood relative-hypertension-sister    9645  9445     FALSE       2  TRUE      9645    9445 77264 FALSE  TRUE  FALSE Questionnaire
29852 MCQ_C MCQ260FI        blood relative-hypertension-other    9645  9475     FALSE       2  TRUE      9645    9475 77264 FALSE  TRUE  FALSE Questionnaire
38091 PFQ_C  PFD069J  hypertension or high blood pressuredays    9645  9475      TRUE       5 FALSE      9645    9475 77208  TRUE FALSE  FALSE Questionnaire
```

As with the table descriptions, information about these variables can
also be summarized and presented as searchable HTML tables. Sample
code for doing this is available
[here](../scripts/generate-variable-summary.R), producing the
following tables, grouped by data group to keep the table sizes
moderate.

- [Demographics](../tables/variable-summary-demographics.html)

- [Questionnaire](../tables/variable-summary-questionnaire.html)

- [Examination](../tables/variable-summary-examination.html)

- [Laboratory](../tables/variable-summary-laboratory.html)

- [Dietary](../tables/variable-summary-dietary.html)

