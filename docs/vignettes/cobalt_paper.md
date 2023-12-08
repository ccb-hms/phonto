---
layout: default
title: "A vignette that outlines a strategy to replicate a published analysis"
author: Laha Ale, Robert Gentleman
date: "Updated on : Fri Dec  8 11:15:23 2023"
output: html_document
---


## 0. Goal

The goal of this vignette is to provide some details that will help understand the analysis presented in ``Association of blood cobalt concentrations with dyslipidemia, hypertension, and diabetes in a US population
A cross-sectional study; Hongxin Wang, MD, Feng Li, MD, Jianghua Xue, MD, Yanshuang Li, MD, Jiyu Li, MD''.  For the remainder of this vignette we will refer to this as the "Cobalt paper", This vignette is incomplete and is not attempting to get identical results of the published paper. Our goal is to demonstrate how one might attempt a replication, but to leave some important details to the reader, who will be able to extend the analysis and if they want to make an attempt to obtain identical results.

 The authors report using data for the years 2015-2016 and 2017-2018 which cover two of the two-year reporting epochs in NHANES. The Questionnaires we want will have the suffixes _I and _J. 

## 1. Load libs


```r
# install EnWAS package via: devtools::install_github("ccb-hms/EnWAS")
library(splines)
library(ggplot2)
library(ggpubr)
#> Error in library(ggpubr): there is no package called 'ggpubr'
library(dplyr)
library(nhanesA)
library(phonto)
library(EnWAS)
#> Error in library(EnWAS): there is no package called 'EnWAS'
library(knitr)
```


## 2. Data and Preprocessiing
In the next few sections we attempt to load data from NHANES in a manner that is consistent with the description provided in Section 2 of the Cobalt paper.
#### 2.1 Loading the Demographic, Body Measures, and Cholesterol data into R

The authors state: 
Participants with cobalt and lipid data were included (n = 6866). Demographic characteristics of the participants, including age, gender, body mass index (BMI), education level, race, family poverty-income ratio and smoking status, were collected. Clinical data, such as blood pressure, total cholesterol (TC), low-density lipoprotein cholesterol (LDL-C), HDL-C, triglycerides (TGs), hypertension, diabetes and history of medication use, including antihypertensive drugs, hypoglycemic drugs, and lipid-lowering drugs, were extracted.

In the code below, we start with the variable names, which we had obtained by searching based on the variable descriptions (not shown) and restrict by the years that the authors had chosen.  We will avoid looking at the LDL measurements and triglycerides as they were done on a subset of the participants, and we want to make sure we are as inclusive as possible.


```r

##get the appropriate table names for the variables we will need
##BP
BPTabs = nhanesSearchVarName("BPQ050A", ystart="2015", ystop="2018")
LDLTabs = nhanesSearchVarName('LBDLDL',ystart="2015", ystop="2018")
##BPQ050A - currently taking meds for hypertension
##BPQ080 - told by Dr. you have high cholesterol
##BPQ100D - now taking meds for high cholesterol
##A1C
A1C = nhanesSearchVarName("LBXGH",ystart="2015", ystop="2018")
##been told by Dr. has diabetes
DrDiab = nhanesSearchVarName("DIQ010",ystart="2015", ystop="2018")
##DIQ050 - taking insulin now
##DIQ070 - taking pills for blood sugar

##HDLTabs
HDLTabs = nhanesSearchVarName("LBDHDD",ystart="2015", ystop="2018")
BMITabs = nhanesSearchVarName("BMXBMI", ystart="2015", ystop="2018")
BMXTabs = nhanesSearchVarName("BMXBMI",ystart="2015", ystop="2018")
DIQTabs = nhanesSearchVarName("DIQ010",ystart="2015", ystop="2018")
COBTabs = nhanesSearchVarName("LBXBCO",ystart="2015", ystop="2018" )
TotChol = nhanesSearchVarName("LBXTC",ystart="2015", ystop="2018" )

cols = list(DEMO_I=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"), 
            DEMO_J=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
            BPQ_I=c('BPQ050A','BPQ020','BPQ080','BPQ100D'),
            BPQ_J=c('BPQ050A','BPQ020','BPQ080','BPQ100D'), 
            HDL_I=c("LBDHDD"),HDL_J=c("LBDHDD"),
            GHB_I="LBXGH",GHB_J="LBXGH",
            DIQ_I=c("DIQ010","DIQ050","DIQ070","DIQ160"),
            DIQ_J=c("DIQ010","DIQ050","DIQ070","DIQ160"), 
            BMX_I="BMXBMI", BMX_J="BMXBMI",
            TCHOL_I="LBXTC", TCHOL_J="LBXTC"
            )
var2Table = cols[c(1,3,5,7,9,11,13)]
base_df <- jointQuery(cols)
dim(base_df)
#> [1] 19225    19
```
##FIXUP some vars

```r
cholMeds = base_df$BPQ100D
cholMeds[base_df$BPQ080=="No"] = "No"
cholMeds[cholMeds=="Don't know"] = NA
cholMeds = factor(cholMeds)
table(cholMeds,useNA="always")
#> cholMeds
#>   No  Yes <NA> 
#> 9225 2013 7987
base_df$cholMeds=cholMeds

##now fixup the oral meds for diabetes
##not counting insulin right now...might need it
dontskip = base_df$DIQ010 == "Yes" | base_df$DIQ010 == "Borderline" | base_df$DIQ160 == "Yes"
hypoglycemicMeds = base_df$DIQ070
hypoglycemicMeds[!dontskip] = "No" 
hypoglycemicMeds = factor(hypoglycemicMeds,levels=c("Yes", "No", "Don't know","Refused"), labels=c("Yes", "No",NA,NA))
table(hypoglycemicMeds,useNA="always")
#> hypoglycemicMeds
#>   Yes    No  <NA> 
#>  1360 12454  5411
base_df$hypoglycemicMeds = hypoglycemicMeds
```
##Smoking
In the code chunk below we extract the smoking data, and then try to create the groupings
used in the paper.  They have three groups, non-smokers, current smokers and ex-smokers. We use the `SMQ_I` and `SMQ_J` tables. We will define non-smoker as someone who as never smoked more than 100 cigarettes (`SMQ020`), anyone who has smoked more will be either
a current smoker or an ex-smoker (`SMQ040`)

```r
cols = list(SMQ_I=c("SMQ020","SMQ040"), SMQ_J=c("SMQ020","SMQ040"))
smokingTab= unionQuery(cols)
tdf = merge(base_df, smokingTab, all.x=TRUE)  
tdf = tdf[tdf$RIDAGEYR>=40,]
##nn = nhanesTranslate("SMQ_J", colnames=c("SMQ020","SMQ040"))
##have a look at the coding for SMQ020
##nn[[1]]
##check to see what values are in the data
table(tdf$SMQ020, useNA="always")
#> 
#> Don't know         No    Refused        Yes       <NA> 
#>          7       4173          1       3467          0
##for SMQ040 too
table(tdf$SMQ040, useNA="always")
#> 
#>  Every day Not at all  Some days       <NA> 
#>       1053       2165        249       4181
smokingVar = ifelse(tdf$SMQ020=="No", "Non-smoker", 
                    ifelse(tdf$SMQ040=="Not at all", "Ex-smoker",
                    "Smoker"))
table(smokingVar, useNA="always")
#> smokingVar
#>  Ex-smoker Non-smoker     Smoker       <NA> 
#>       2165       4173       1302          8
##from the paper n=6866, Ex=1950,Non=3744,Current=1165
```
#Glucose

```r
##fasting glucose
Fastgluc = nhanesSearchVarName("LBXGLU", ystart="2015", ystop="2018")
glucTab = unionQuery(list(GLU_I="LBXGLU", GLU_J="LBXGLU"))
base_df = merge(base_df, glucTab, all.x=TRUE)
```
The two variables that require additional lab work are LDLs and cobalt levels. As a result they were done on a much smaller set of people.  So instead of loading them simultaneously we extract them below and then use the `merge`

```r
ldlTab = unionQuery(list(TRIGLY_I=c("LBXTR","LBDLDL"),TRIGLY_J=c("LBXTR","LBDLDL"))) 
dim(ldlTab)
#> [1] 6227    5
cobaltTab = unionQuery(list(CRCO_I="LBXBCO", CRCO_J="LBXBCO"))
dim(cobaltTab)
#> [1] 7286    4
var2Table = c(var2Table, list("TRIGLY_I"=c("LBXTR","LBDLDL"), CRCO_I="LBXBCO"))
##we merge keeping as many records as we can, the all.x argument is important
bdf = merge(base_df, ldlTab, all.x=TRUE)
base_df = merge(bdf, cobaltTab, all.x=TRUE)
dim(base_df)
#> [1] 19225    25
```
If we were to remove all records with missing values at this point we would be left with a very small number of cases.  So we will try to be careful not to loose too many data points.

#### 2.2) Blood Pressure Data

 In the next code segment we show how to obtain blood pressure measurements from NHANES tables.  We have already ascertained that these measurements are contained in Questionnaires that are named BPX_I and BPX_J and that there were replicate measurements taken.  Both systolic (BPXS) and diastolic (BPXD) measurements were taken
on each of two occassions.  We will use the average of these two measurements for individuals with two measurements, and in the case where only one measurement is available we will use it. The authors of the Cobalt paper don't specify which values they used, so this is one of the places where our analysis may differ from theirs.

```r
bptablenames = nhanesSearchTableNames('BPX[_]')
bptablenames |> kable()
```



|x     |
|:-----|
|BPX_B |
|BPX_C |
|BPX_D |
|BPX_E |
|BPX_F |
|BPX_G |
|BPX_H |
|BPX_I |
|BPX_J |


We can see that blood pressure data was collected for other years as well, but for now we will just extract the data for the 2015-2016 and 2017-2018 years. We combine these into a single dataframe.


```r
blood_df <- unionQuery(list(BPX_I=c("BPXDI1","BPXDI2","BPXSY1","BPXSY2"), 
                            BPX_J=c("BPXDI1","BPXDI2","BPXSY1","BPXSY2")))
dim(blood_df)
#> [1] 18248     7
# Average the the first and second reads
# taking some care to keep one measurement if the other is missing
blood_df$DIASTOLIC <- rowMeans(blood_df[, c("BPXDI1", "BPXDI2")], na.rm=TRUE)
blood_df$DIASTOLIC[is.na(blood_df$BPXDI1) & is.na(blood_df$BPXDI2)] = NA
blood_df$SYSTOLIC <- rowMeans(blood_df[, c("BPXSY1", "BPXSY2")], na.rm=TRUE)
blood_df$SYSTOLIC[is.na(blood_df$BPXSY1) & is.na(blood_df$BPXSY2)] = NA
dim(blood_df)
#> [1] 18248     9
blood_df[1:10,] |> kable()
```



|   SEQN| BPXDI1| BPXDI2| BPXSY1| BPXSY2| Begin.Year| EndYear| DIASTOLIC| SYSTOLIC|
|------:|------:|------:|------:|------:|----------:|-------:|---------:|--------:|
|  85432|     70|     70|    112|    120|       2015|    2016|        70|      116|
|  98018|     48|      0|    120|    128|       2017|    2018|        24|      124|
|  90883|     56|     52|    108|    118|       2015|    2016|        54|      113|
|  92397|     60|     58|    116|    114|       2015|    2016|        59|      115|
| 101919|     66|     64|    112|    116|       2017|    2018|        65|      114|
| 102725|     78|     74|    110|    114|       2017|    2018|        76|      112|
| 102910|     60|     66|    136|    134|       2017|    2018|        63|      135|
| 100360|     74|     70|    104|    104|       2017|    2018|        72|      104|
| 101817|     74|     70|    122|    118|       2017|    2018|        72|      120|
|  94417|     NA|     NA|     NA|     NA|       2017|    2018|        NA|       NA|


  In our analysis we can then look at the average of the measurements across the two different time points as a way to estimate the actual blood pressure for each participant.


### 2.3)  merge and PHESANT-like process

Now you have a dataframe with the data, but you will need to better understand the variables, exposures and responses.  To help with that we have created some tools, based on related work in the UK Biobank called PHESANT  (cite PHESANT)).  The process takes each variable (column)
and reports what type of data it is, continuous or multi-level (ie factors). We report the number of levels, you can use the `nhanesTranslate` function to learn more about the levels of the factor. Some numeric quantities are reported such as the ratio of unique values to the length of vector, the proportion of zeros, and the proportion of missing values. NHANES has chosen to store categorical data types (ordered or unordered) as integers. For example, education level, `DMDEDUC2` is identified as `Multilevel-8 `.  You can learn more about the details of the NHANES data in the Quick Start Vignette (cite quick start).


```r

data <- merge(base_df, blood_df, all.x=TRUE,by=c("SEQN", "Begin.Year", "EndYear"))
data$years = as.factor(paste0(data$Begin.Year,"-", data$EndYear))
##fix up our list linking variable names to the table they came from
var2Table = c(var2Table, list("BPX_I"=c("BPXDI1","BPXDI2","BPXSY1","BPXSY2")))
phs_dat = phesant(data)
data = phs_dat$data
DT::datatable(phs_dat$phs_res)
#> Error in path.expand(path): invalid 'path' argument
```

In the next code chunk we will convert the multilevel variables into R factors. To do this we make use of the nhanesTranslate function. While that function does most of the work, there are some variables we need to deal with manually to replicate the analysis. First, the years variable is something we added, so we need to deal with it manually.  Then we use `nhanesTranslate` to transform all of the internal values.  Then we need to do a little more work on modifying levels of the education variable.  The authors decided to group education into three levels, less than high school (<HS), high school (HS), and more than school-school(>HS).  We also need to address some issues around the hypertension variables.
Particpants were asked (BPQ020) whether they had ever been told by a doctor or health care professional that they had high blood pressure.  The survey was designed to then skip over a number of questions about their hypertension if they said they did not have hypertension. However this then introduces missing values in the question BPQ050A, which was whether or not they were currently taking a prescription for hypertension. Presumably only people who had been told by their doctor they have hypertension would be taking a perscription and we will need to manually adjust the data so that these are answered No, rather than missing.



```r

data$DMDEDUC2 = factor(data$DMDEDUC2)

levels(data$DMDEDUC2) <- c("<HS",">HS",NA,"HS","<HS",NA,">HS")

##
## fixup the data for a skipped question
hypertensiveMeds = data$BPQ050A
hypertensiveMeds[data$BPQ020=="No"] = "No"
hypertensiveMeds[data$BPQ040A=="No"] = "No"

data$BPQ050A = hypertensiveMeds
##remove any record with at least one NA and then subset to those over 40
##data <- na.omit(data)
data <- data[data$RIDAGEYR>=40,]
dim(data)
#> [1] 7648   32
```
At this point we have 7648 individuals left. 

## Replication of Table 1
Table 1 provides some basic summaries of the demographic data. We will create a 
temporary subset of the data that uses only the complete cases.


```r
pcobalt = ifelse(data$LBXBCO <= 0.12, "<=0.12", 
                ifelse(data$LBXBCO >= 0.13 & data$LBXBCO <= 0.14, "0.13-0.14",
                  ifelse(data$LBXBCO >= 0.15 & data$LBXBCO <= 0.18, "0.15-0.18",
                         ifelse(data$LBXBCO >= 0.19, ">=1.9",
                         NA)  )))
##make it an ordered factor 
pcob = factor(pcobalt, levels=c("<=0.12","0.13-0.14", "0.15-0.18",">=1.9"), ordered=TRUE)
data$pcobalt = pcob
table(pcob, useNA="always")
#> pcob
#>    <=0.12 0.13-0.14 0.15-0.18     >=1.9      <NA> 
#>      1943      1433      1820      1778       674
AgeGp = data |> group_by(pcobalt) |> summarise(mean=mean(RIDAGEYR,na.rm=TRUE),SD=sd(RIDAGEYR,na.rm=TRUE))
```

## 2.4 Definitions
Here we implement the definitions from Section 3.1 of the Cobalt paper. For hypertension they described using reported systolic and diastolic blood pressure measurements as well as self-reported statements regarding whether a physician had ever told them that they have high blood pressure.  

Note that it is unclear whether the authors used averaged over 2 measurements for the systolic and diastolic blood pressure measurements. Still, we use average them because it would give us more accurate blood pressure measurements.

One might also look at the use of prescribed hypertensives, as these will modulate the systolic and diastolic measures.  Data on self-report come from the BPQ tables in NHANES.
https://wwwn.cdc.gov/nchs/nhanes/2011-2012/BPQ_G.htm


```r
# "Hypertension was defined as systolic blood pressure (SBP) ≥140 mm Hg, diastolic blood pressure ≥90mm Hg, or the use of antihypertensive medication. "
data$hypertension <- data$DIASTOLIC >= 90 | data$SYSTOLIC >= 140 |  data$BPQ050A=="Yes"
barplot(table(data$hypertension))
```

![plot of chunk RiskFactors](figure/RiskFactors-1.png)

```r
data$diabetes = data$DIQ010 == "Yes" | data$LBXGLU > 110 | data$LBXGH > 6.5
barplot(table(data$diabetes))
```

![plot of chunk Diabetes](figure/Diabetes-1.png)

```r

data$HighLDL = data$LBDLDL > 130
barplot(table(data$HighLDL))
```

![plot of chunk Diabetes](figure/Diabetes-2.png)

```r
 
data$LowHDL = (data$RIAGENDR=="Male" & data$LBDHDD < 40) |    (data$RIAGENDR=="Female" & data$LBDHDD < 50) 
barplot(table(data$LowHDL))
```

![plot of chunk Diabetes](figure/Diabetes-3.png)
Now lets define the elevated total cholesterol variable.


```r
elevatedTC = data$LBXTC>200
data$elevatedTC = elevatedTC
```

Note that some of our groupings are very similar to those reported in the Cobalt paper, but some, notably Elevated LDLs are quite different. This discrepency should be explored (it may have to do with incorrect subsetting by age).
## 2.5 Compare with Table-2

```r

DBP = data |> group_by(pcobalt) |> summarise(mean=mean(DIASTOLIC, na.rm=TRUE),SD=sd(DIASTOLIC,na.rm=TRUE))
DBP$stat = paste(round(DBP$mean,1),"±",round(DBP$SD,1))
DBPmn = mean(data$DIASTOLIC, na.rm=TRUE)
DBPsd = sd(data$DIASTOLIC, na.rm=TRUE)

SBP = data |> group_by(pcobalt) |> summarise(mean=mean(SYSTOLIC,na.rm=TRUE),SD=sd(SYSTOLIC, na.rm=TRUE))
SBP$stat = paste(round(SBP$mean,1),"±",round(SBP$SD,1))
SBPmn = mean(data$SYSTOLIC, na.rm=TRUE)
SBPsd = sd(data$SYSTOLIC, na.rm=TRUE)

dbp_t = t(DBP)
colnames(dbp_t) = DBP$pcobalt

sbp_t = t(SBP)
colnames(sbp_t) = SBP$pcobalt

table2 = rbind(sbp_t["stat",],dbp_t["stat",])
table2 = table2[,c("<=0.12","0.13-0.14","0.15-0.18",">=1.9")]
table2 = cbind("Blood Pressures"=c("SBP (mm Hg), mean±SD","DBP (mm Hg), mean±SD"),table2)
```
It shows the number we have is not exactly the same as the one in the table-2 in the paper. The authors did not use the average of two reads of the blood pressure measurements.


```r
library(kableExtra)
kbl(table2) |>
  kable_classic() |>
  add_header_above(c(" " = 1, "Cobalt Quartiles (ug/L)" = 4))
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; margin-left: auto; margin-right: auto;'>
 <thead>
<tr>
<th style="empty-cells: hide;" colspan="1"></th>
<th style="padding-bottom:0; padding-left:3px;padding-right:3px;text-align: center; " colspan="4"><div style="border-bottom: 1px solid #111111; margin-bottom: -1px; ">Cobalt Quartiles (ug/L)</div></th>
</tr>
  <tr>
   <th style="text-align:left;"> Blood Pressures </th>
   <th style="text-align:left;"> &lt;=0.12 </th>
   <th style="text-align:left;"> 0.13-0.14 </th>
   <th style="text-align:left;"> 0.15-0.18 </th>
   <th style="text-align:left;"> &gt;=1.9 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> SBP (mm Hg), mean±SD </td>
   <td style="text-align:left;"> 129.7 ± 18.3 </td>
   <td style="text-align:left;"> 131.3 ± 19.1 </td>
   <td style="text-align:left;"> 132.6 ± 20.5 </td>
   <td style="text-align:left;"> 131.6 ± 21.4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DBP (mm Hg), mean±SD </td>
   <td style="text-align:left;"> 72.5 ± 13.4 </td>
   <td style="text-align:left;"> 73 ± 12.9 </td>
   <td style="text-align:left;"> 71.9 ± 13.4 </td>
   <td style="text-align:left;"> 70.2 ± 14.1 </td>
  </tr>
</tbody>
</table>




The authors don't seem to explore the relationship between taking medications (eg. insulin and oral hypoglycemic drugs) and disease (eg diabetes, or fasting glucose rate).  For hypertension, hypoglycemia and dislipemia it seems like these would be interesting relationships to explore.


## 3.Regression Models

In Section 3.2 of the Cobalt paper the authors describe their use of binary logistic regression models.  They use dyslipidemia as the outcome and adjust for age, sex and BMI (their model 1).  They split cobalt levels into the groupings described above and then fit logistic models that were linear in the covariates.  Here we provide the tools to replicate that analysis and also explore the use of regression splines to fit the continuous variables in the model, namely age, BMI and cobalt levels.

In the following section, we run the logistic regression models as generalized linear models (GLMs). In the models, the outcome of the hypertension indicator and the adjusted variables are age (RIDAGEYR), gender (RIAGENDR), BMI (BMXBMI), education (DMDEDUC2), and ethnicity (RIDRETH1). The first GLM is with linear terms, and the second GLM also adds terms linearly together but applies a natural spline to the continuous variables.      


```r
subSet = data[, c("hypertension","RIDAGEYR", "RIAGENDR", "BMXBMI","DMDEDUC2", "RIDRETH1")]
subSet = na.omit(subSet)

lm_logit <- glm(hypertension ~ RIDAGEYR + RIAGENDR + BMXBMI+DMDEDUC2+RIDRETH1, data = subSet, family = "binomial",na.action=na.omit)

##spline covariates
ns_logit <- glm(hypertension ~ ns(RIDAGEYR,df=7)+RIAGENDR + ns(BMXBMI,df=7) + DMDEDUC2 + RIDRETH1, 
                   data = subSet, family = "binomial",na.action=na.omit)
```
###Model 2
In the code below we fit model two.

```r
## glm linear in the covariates
##we first want to reduce to those that have values for these covariates
subSet = data[, c("hypertension","RIDAGEYR", "RIAGENDR", "BMXBMI","DMDEDUC2", "RIDRETH1")]
subSet = na.omit(subSet)

lm_logit <- glm(hypertension ~ RIDAGEYR + RIAGENDR + BMXBMI+DMDEDUC2+RIDRETH1, data = subSet, family = "binomial",na.action=na.omit)

##spline covariates
ns_logit <- glm(hypertension ~ ns(RIDAGEYR,df=7)+RIAGENDR + ns(BMXBMI,df=7) + DMDEDUC2 + RIDRETH1, 
                   data = subSet, family = "binomial",na.action=na.omit)
```
### 3.1) QA/QC

```r
# library(pROC)
library(plotROC)
test = data_frame(hypertension=subSet$hypertension,lm=lm_logit$fitted.values,   ns=ns_logit$fitted.values)
#> Warning: `data_frame()` was deprecated in tibble 1.1.0.
#> ℹ Please use `tibble()` instead.
#> This warning is displayed once every 8 hours.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was generated.
longtest <- reshape2::melt(test,id.vars="hypertension")
colnames(longtest) = c('hypertension','model','value')
ggplot(longtest, aes(d = as.numeric(hypertension), m = value, color = model))+ geom_abline()+ geom_roc(size = 1.25) + style_roc()
```

![plot of chunk unnamed-chunk-7](figure/unnamed-chunk-7-1.png)

```r

# plot(roc(data$hypertension,
#                    fitted(lm_logit)),
#                print.auc = T, 
#                col = "red")
# 
# plot(roc(data$hypertension,
#                    fitted(ns_logit)),
#                print.auc = T, 
#                col = "blue", 
#                add = T)
```


```r
# Age
df_age_fitt = list("Binned Data"=make_bins(x=subSet$RIDAGEYR,y=as.numeric(subSet$hypertension),nbin=600),
                  "Linear"=make_bins(x=subSet$RIDAGEYR,y=lm_logit$fitted.values,nbin=600),
                  "Spline"=make_bins(x=subSet$RIDAGEYR,y=ns_logit$fitted.values,nbin=600)
                )
#> Error in make_bins(x = subSet$RIDAGEYR, y = as.numeric(subSet$hypertension), : could not find function "make_bins"
age_fitt = plot_bins2(df_age_fitt,xlab="Age (year)",ylab="Hypertension",is_facet=F) 
#> Error in plot_bins2(df_age_fitt, xlab = "Age (year)", ylab = "Hypertension", : could not find function "plot_bins2"

#BMI
df_bmi_fit =list("Linear"=make_bins(x=subSet$BMXBMI,y=lm_logit$fitted.values,nbin=600),
                "Spline"=make_bins(x=subSet$BMXBMI,y=ns_logit$fitted.values,nbin=600),
                "Binned Data"=make_bins(x=subSet$BMXBMI,y=as.numeric(subSet$hypertension),nbin=600)
                )
#> Error in make_bins(x = subSet$BMXBMI, y = lm_logit$fitted.values, nbin = 600): could not find function "make_bins"

bmi_fit <- plot_bins2(df_bmi_fit,xlab="BMI",ylab="Hypertension",is_facet=F) 
#> Error in plot_bins2(df_bmi_fit, xlab = "BMI", ylab = "Hypertension", is_facet = F): could not find function "plot_bins2"
```
The following plots show binned Hypertension data; each bin contains about 600 data points and we compute the proportion of the participants who reported hypertension. 
Linear and Spline present the fitted values (probabilities) from the GLM with linear terms and apply the natural spline function on continuous terms of the participants who have 
hypertension. For both age, panel a), and BMI, panel b),  the GLM model using splines agrees with the estimates obtained by binning, while when these terms are modeled using
a simple linear term there are more substantial discrepancies. 

To compute the model estimates for each bin we simply average the computed fitted values (which are defined to be back-transformed to probabilities for logistic regression) over the 
same individuals in each bin. One might want to examine the relationship on the logit scale, which is easily done.


```r

ggpubr::ggarrange(age_fitt,bmi_fit,nrow = 1,ncol = 2,labels = c('a)','b)'))
#> Error in loadNamespace(x): there is no package called 'ggpubr'
```


## 4. Their findings
As the authors pointed out, the blood cobalt concentrations are not associated with the risk of hypertension based on the following summary table. The cobalt concentration does not significantly impact hypertension.
FIXME: but they have a bunch of other features in their table 2 - and it would be good if we can start to look at them.


```r
subSet2 = data[, c("hypertension","RIDAGEYR", "RIAGENDR", "BMXBMI","DMDEDUC2", "RIDRETH1", "LBXBCO")]
subSet2 = na.omit(subSet2)

lm_logit <- glm(hypertension ~ RIDAGEYR + RIAGENDR + BMXBMI+DMDEDUC2+RIDRETH1+LBXBCO, data = subSet2, family = "binomial")
ns_logit <- glm(hypertension ~ ns(RIDAGEYR,df=7)+RIAGENDR + ns(BMXBMI,df=7) + DMDEDUC2 + RIDRETH1+LBXBCO, 
                   data = subSet2, family = "binomial",na.action=na.omit)

sjPlot::tab_model(lm_logit,ns_logit,
                  dv.labels = c("lm", "spline"),
                  show.ci = FALSE,show.stat = TRUE,show.se = TRUE,p.style = "scientific", digits.p = 2)
```

<table style="border-collapse:collapse; border:none;">
<tr>
<th style="border-top: double; text-align:center; font-style:normal; font-weight:bold; padding:0.2cm;  text-align:left; ">&nbsp;</th>
<th colspan="4" style="border-top: double; text-align:center; font-style:normal; font-weight:bold; padding:0.2cm; ">lm</th>
<th colspan="4" style="border-top: double; text-align:center; font-style:normal; font-weight:bold; padding:0.2cm; ">spline</th>
</tr>
<tr>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  text-align:left; ">Predictors</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  ">Odds Ratios</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  ">std. Error</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  ">Statistic</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  ">p</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  ">Odds Ratios</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  col7">std. Error</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  col8">Statistic</td>
<td style=" text-align:center; border-bottom:1px solid; font-style:italic; font-weight:normal;  col9">p</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">(Intercept)</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.00</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.00</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">&#45;27.56</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>3.18e&#45;167</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.09</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.04</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">&#45;5.08</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>3.78e&#45;07</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.08</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.00</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">28.96</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>1.90e&#45;184</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7"></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8"></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIAGENDR [Male]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.03</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.58</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">5.59e&#45;01</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.01</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">0.26</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">7.95e&#45;01</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.08</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.00</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">16.55</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>1.59e&#45;61</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7"></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8"></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">DMDEDUC2 [>HS]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.79</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">&#45;3.15</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>1.61e&#45;03</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.78</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">&#45;3.29</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>1.00e&#45;03</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">DMDEDUC2 [HS]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.02</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.09</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.26</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">7.97e&#45;01</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.00</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.09</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">0.05</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">9.58e&#45;01</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDRETH1 [Non-Hispanic<br>Black]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">2.77</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.27</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">10.40</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>2.45e&#45;25</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">2.86</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.28</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">10.57</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>4.25e&#45;26</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDRETH1 [Non-Hispanic<br>White]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.08</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.10</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.83</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">4.04e&#45;01</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.14</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.11</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">1.42</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">1.57e&#45;01</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDRETH1 [Other Hispanic]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.43</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.15</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">3.36</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>7.81e&#45;04</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.42</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.15</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">3.24</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>1.21e&#45;03</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDRETH1 [Other Race -<br>Including Multi-Racial]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.69</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.18</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">5.02</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "><strong>5.28e&#45;07</strong></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.77</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.19</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">5.38</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>7.51e&#45;08</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">LBXBCO</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.02</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">0.42</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">6.73e&#45;01</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.03</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">0.52</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">6.06e&#45;01</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [1st degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">3.09</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.57</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">6.06</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>1.37e&#45;09</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [2nd degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">4.87</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">1.08</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">7.11</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>1.13e&#45;12</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [3rd degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">7.02</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">1.37</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">10.02</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>1.21e&#45;23</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [4th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">11.37</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">2.78</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">9.95</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>2.62e&#45;23</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [5th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">10.21</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">2.22</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">10.67</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>1.37e&#45;26</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [6th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">23.64</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">8.39</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">8.92</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>4.87e&#45;19</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">RIDAGEYR [7th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">17.19</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">2.31</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">21.20</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>9.08e&#45;100</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [1st degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.95</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.81</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">1.60</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">1.09e&#45;01</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [2nd degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">1.88</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">0.93</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">1.28</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">2.00e&#45;01</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [3rd degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">2.34</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">1.07</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">1.86</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9">6.27e&#45;02</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [4th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">2.83</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">1.32</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">2.23</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>2.55e&#45;02</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [5th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">14.85</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">6.47</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">6.20</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>5.74e&#45;10</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [6th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">12.11</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">14.56</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">2.07</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>3.81e&#45;02</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; ">BMXBMI [7th degree]</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  "></td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  ">21.08</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col7">32.35</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col8">1.99</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:center;  col9"><strong>4.70e&#45;02</strong></td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; padding-top:0.1cm; padding-bottom:0.1cm; border-top:1px solid;">Observations</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; padding-top:0.1cm; padding-bottom:0.1cm; text-align:left; border-top:1px solid;" colspan="4">6576</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; padding-top:0.1cm; padding-bottom:0.1cm; text-align:left; border-top:1px solid;" colspan="4">6576</td>
</tr>
<tr>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; text-align:left; padding-top:0.1cm; padding-bottom:0.1cm;">R<sup>2</sup> Tjur</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; padding-top:0.1cm; padding-bottom:0.1cm; text-align:left;" colspan="4">0.194</td>
<td style=" padding:0.2cm; text-align:left; vertical-align:top; padding-top:0.1cm; padding-bottom:0.1cm; text-align:left;" colspan="4">0.198</td>
</tr>

</table>

  FIXME:  This likely belongs in the QA/QC section.  The point of this code is to show the reader how they can estimate the functional form of the spline that they are fitting
to the data.  To do that, we pick a covariate, say Age, where we want to compute the spline.  Then we pick a set of Age values that cover the range of ages in the model.  
To get predictions from the model for a specific age we also need to specify values for all the other covariates in the model.  
Our suggestion is that for categorical variables choose the most common category and for continuous variables use the median value.

*** Robert, you only keep one base model in the end, do you want to me plot or compare somethings***
FIXME: yes the point here is to develop a better summary of the comparison of models with spline terms. I really don't like the R output that shows each term individually, as you can't really interpret them and they take up a lot of room.  I think we should instead, create one line for each spline term, and in it only put the value of the LRT comparing the model with the spline to the model without it.  From that comparison you can get the chi-squared statistic, the p-value and the df and those could be put into the table.  I think that would be a better thing.



```r
   # base_logit <- glm(hypertension ~ RIDAGEYR + RIAGENDR + BMXBMI+DMDEDUC2+RIDRETH1 + sqrt(LBXBCO), data = data, family = "binomial")
   # base_logit <- glm(hypertension ~ ns(RIDAGEYR,df=7) + RIAGENDR + ns(BMXBMI,df=7) + DMDEDUC2 + RIDRETH1 + ns(sqrt(LBXBCO), df=7) + years, data = data, family = "binomial")
   base_logit <- glm(hypertension ~ ns(RIDAGEYR,df=7) + RIAGENDR + ns(BMXBMI,df=7) + DMDEDUC2 + RIDRETH1, data = data, family = "binomial")

   ## try to do some prediction - and then get a plot of the age spline
  ##46 of these
  yvals = seq(40,85,by=1)
  dfimpute = data.frame(RIDAGEYR=yvals, RIAGENDR=rep("Male", 46), BMXBMI=rep(28.9, 46), DMDEDUC2=rep("HS", 46), RIDRETH1=rep("Non-Hispanic White", 46))

  predV = predict(base_logit, newdata=dfimpute)
  # lines(40:85, predV)
  qplot(40:85,predV,geom = "line") + theme_bw()
```

![plot of chunk model2](figure/model2-1.png)

```r

 ##now look at BMI
  yBMI = 14:80
  dfBMIimpute = data.frame(RIDAGEYR=rep(60,67) , RIAGENDR=rep("Male", 67), BMXBMI=yBMI, DMDEDUC2=rep("HS", 67), RIDRETH1=rep("Non-Hispanic White", 67))
  predBMI = predict(base_logit, newdata=dfBMIimpute)
  qplot(14:80,predBMI,geom = "line") + theme_bw()
```

![plot of chunk model2](figure/model2-2.png)
