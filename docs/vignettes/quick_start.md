---
layout: default
title: "Quick Start"
output: rmarkdown::html_vignette
author: Laha Ale, Robert Gentleman, Teresa Filshtein Sonmez
vignette: >
  %\VignetteIndexEntry{Quick Start}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---





### Introduction



  The NHANES data set provides a large diverse set of data to study health and other sociological and epidemiological topics on the US population.  It is used very widely and the bulk of the data are publicly available.  Our goal with the Epiconductor project is to enable users access to the data using a container that contains an SQL database and R together with other software to support different analyses of the data.  We believe that this will increase access and provide a platform for reproducibility.  This document outlines some of the ways you can interact with the NHANES data while using the container and R packages [phonto](https://github.com/ccb-hms/phonto/tree/main/vignettes) and [nhanesA](https://cran.r-project.org/web/packages/nhanesA/index.html).

### NHANES 

The [National Health and Nutrition Examination Survey (NHANES)](https://www.cdc.gov/nchs/nhanes/index.htm) datasets are collected from the Centers for Disease Control and Prevention in the USA, including demographics, dietary, laboratory, examination, and questionnaire data. The five publicly available data categories are:  

  - Demographics (DEMO)
  - Dietary (DIET)
  - Examination (EXAM)
  - Laboratory (LAB)
  - Questionnaire (Q)

The abbreviated forms in parentheses may be substituted for the long form in [phonto](https://github.com/ccb-hms/phonto/tree/main/vignettes) and [nhanesA](https://cran.r-project.org/web/packages/nhanesA/index.html) commands. There is also limited access data, eg. genetics, that requires written justification and prior approval before users are granted access. We restrict our tools to the publicly available data.

The survey is carried out in two year *cycles* starting from the first cycle in 1999-2000. Within each cycle, a set of people are surveyed, however not all of the participants are surveyed across all of the components. Within each of the data categories NHANES has organized the data into Questionnaires and provides web interfaces for descriptions of the contents of each questionnaire.  We do not replicate the web interface as users can browse that information using standard tools, but we have constructed an integrated SQL database representation of much of the publicly available NHANES data.  Placing all of the data into a single database facilitates searching and extraction of relevant values, and this provides many advantages to the individual researcher, as well as to the research world at large.

Each NHANES participant is assigned a unique ID that is stored in the database as <tt>SEQN</tt>. This is used as the primary key and merging of data extracted from different tables should be based on this variable (<tt>SEQN</tt>). 
For each two-year cycle, NHANES provides a set of data, documentation and code books, organized by each of the five publicly available categories mentioned above.  Users can explore the available data at a high level by searching within cycle, category, and measure. One example is the [Body Measures](https://wwwn.cdc.gov/nchs/nhanes/2001-2002/BMX_B.htm) table which provides data from the 2001-2002 examination data. The web page provides details on the measurements and how they are recorded.
Here are two examples:  

![SEQN](images/seqn.png){width=80%}
![weight](images/weight.png){width=80%}


There are many ways to access and utilize the NHANES data. Users familiar with SQL can connect and explore the data with database client tools such as HeidiSQL and DataGrip, or other programming languages such as R or Python either through tools that support database connections, or as we do in the [phonto package](https://github.com/ccb-hms/phonto/tree/main/vignettes), through custom built wrappers.

Others may use [web-based tools](https://www.cdc.gov/nchs/nhanes/index.htm) provided by the CDC for investigating the data and metadata. In addition there are two existing R packages called [nhanesA](https://cran.r-project.org/web/packages/nhanesA/index.html) (Endres) and [RNHANES](https://cran.r-project.org/web/packages/RNHANES/index.html) (Susman). While most of the data collected can easily be downloaded from the CDC website, accessing the data in that way can be problematic and error prone and makes sharing and reproducibility more challenging due to the lack of versioning and the potential for changes in either the data or the infrastructure over time.  By capturing all components into containers we can aid reproducibility by versioning the containers and by keeping copies of each version for subsequent use.

The [nhanesA](https://cran.r-project.org/web/packages/nhanesA/index.html) package provides a set of tools to search and download the NHANES data and metadata, making the data more accessible to user. However, one drawback is that the tool must access the NHANES website every time the user calls the R function, which leads slow getting of the data and raises errors occasionally due to network issues.  

In the spirit of producing more easily reproduced and shared analyses we have created a SQL database in a Docker (cite Docker) container that contains most of the currently available NHANES data. For our Dockerized container only public data is included.  There are some tables what were not included due to size, or availability when we downloaded the tables to create the database. 

Around that SQL database we have constructed a number of R packages and other tools that help scientists analyze the data. Since all of the code and data are under version control, anyone can obtain the same version of the data and code and produce identical results.  We have worked with the author of that package to adapt the functions in that package to work on the NHANES Docker container. But, since having the data locally provides a number of opportunities to simplify some data integration steps we also provide a suite of tools in the `phonto` package (cite phonto).


### 1. Quick check NHANES data

We can efficiently access NHANES data using `phonto` and `nhanesA` together. By simply knowing the name of the data file or table, one can very quickly and efficiently obtain basic information, e.g. column names, dimensions, etc. 

First we load up the packages we will use for this vignette.

```r
library(nhanesA)
library(phonto)
library(DT)
```

Let's take a body measure table as an example, (<tt>BMX_I</tt>).

- show column names of an NHANES table. 


```r
nhanesColnames("BMX_I")
#>  [1] "SEQN"     "BMDSTATS" "BMXWT"    "BMIWT"    "BMXRECUM" "BMIRECUM" "BMXHEAD"  "BMIHEAD"  "BMXHT"    "BMIHT"   
#> [11] "BMXBMI"   "BMDBMIC"  "BMXLEG"   "BMILEG"   "BMXARML"  "BMIARML"  "BMXARMC"  "BMIARMC"  "BMXWAIST" "BMIWAIST"
#> [21] "BMXSAD1"  "BMXSAD2"  "BMXSAD3"  "BMXSAD4"  "BMDAVSAD" "BMDSADCM" "SEQN"     "BMDSTATS" "BMIWT"    "BMIRECUM"
#> [31] "BMIHEAD"  "BMIHT"    "BMDBMIC"  "BMILEG"   "BMIARML"  "BMIARMC"  "BMIWAIST" "BMDSADCM" "BMXWT"    "BMXRECUM"
#> [41] "BMXHEAD"  "BMXHT"    "BMXBMI"   "BMXLEG"   "BMXARML"  "BMXARMC"  "BMXWAIST" "BMXSAD1"  "BMXSAD2"  "BMXSAD3" 
#> [51] "BMXSAD4"  "BMDAVSAD"
```

- show number of rows/columns and dimension of an NHANES table

```r
nhanesNrow("BMX_I")
#> [1] 9544
nhanesNcol("BMX_I")
#> [1] 52
nhanesDim("BMX_I")
#> [1] 9544   52
```

- First/Last records of an NHANES table


```r
nhanesHead("BMX_I")
#>    SEQN                    BMDSTATS BMIWT BMIRECUM BMIHEAD BMIHT BMDBMIC BMILEG BMIARML BMIARMC BMIWAIST BMDSADCM
#> 1 83926 Complete data for age group  <NA>     <NA>    <NA>  <NA>    <NA>   <NA>    <NA>    <NA>     <NA>     <NA>
#> 2 84498 Complete data for age group  <NA>     <NA>    <NA>  <NA>    <NA>   <NA>    <NA>    <NA>     <NA>     <NA>
#> 3 84545 Complete data for age group  <NA>     <NA>    <NA>  <NA>    <NA>   <NA>    <NA>    <NA>     <NA>     <NA>
#> 4 83999 Complete data for age group  <NA>     <NA>    <NA>  <NA>    <NA>   <NA>    <NA>    <NA>     <NA>     <NA>
#> 5 84065 Complete data for age group  <NA>     <NA>    <NA>  <NA>    <NA>   <NA>    <NA>    <NA>     <NA>     <NA>
#>   BMXWT BMXRECUM BMXHEAD BMXHT BMXBMI BMXLEG BMXARML BMXARMC BMXWAIST BMXSAD1 BMXSAD2 BMXSAD3 BMXSAD4 BMDAVSAD
#> 1  77.8       NA      NA 170.5   26.8   39.2      37    31.5     93.5    22.9    23.0      NA      NA     23.0
#> 2  82.1       NA      NA 164.0   30.5   36.0      37    33.1     99.0    23.2    23.3      NA      NA     23.3
#> 3  92.2       NA      NA 175.3   30.0   38.0      37    34.1    107.0    24.4    24.3      NA      NA     24.4
#> 4  73.4       NA      NA 171.5   25.0   37.0      37    32.2     89.9    20.4    20.8      NA      NA     20.6
#> 5  67.4       NA      NA 161.4   25.9   36.0      37    30.6     89.6    18.3    18.5      NA      NA     18.4
nhanesTail("BMX_I")
#>    SEQN                    BMDSTATS BMIWT BMIRECUM BMIHEAD BMIHT       BMDBMIC BMILEG BMIARML BMIARMC BMIWAIST
#> 5 93698  No body measures exam data  <NA>     <NA>    <NA>  <NA>          <NA>   <NA>    <NA>    <NA>     <NA>
#> 4 93699 Complete data for age group  <NA>     <NA>    <NA>  <NA>    Overweight   <NA>    <NA>    <NA>     <NA>
#> 3 93700 Complete data for age group  <NA>     <NA>    <NA>  <NA>          <NA>   <NA>    <NA>    <NA>     <NA>
#> 2 93701 Complete data for age group  <NA>     <NA>    <NA>  <NA> Normal weight   <NA>    <NA>    <NA>     <NA>
#> 1 93702 Complete data for age group  <NA>     <NA>    <NA>  <NA>          <NA>   <NA>    <NA>    <NA>     <NA>
#>   BMDSADCM BMXWT BMXRECUM BMXHEAD BMXHT BMXBMI BMXLEG BMXARML BMXARMC BMXWAIST BMXSAD1 BMXSAD2 BMXSAD3 BMXSAD4
#> 5     <NA>    NA       NA      NA    NA     NA     NA      NA      NA       NA      NA      NA      NA      NA
#> 4     <NA>  29.0       NA      NA 126.2   18.2     NA    26.9    20.7     62.9      NA      NA      NA      NA
#> 3     <NA>  78.2       NA      NA 173.3   26.0   40.3    37.5    30.6     98.9    21.7    21.8      NA      NA
#> 2     <NA>  28.8       NA      NA 126.0   18.1   30.5    25.6    20.8     62.7    14.3    14.0      NA      NA
#> 1     <NA>  58.3       NA      NA 165.0   21.4   38.2    33.5    26.2     72.5    16.9    16.9      NA      NA
#>   BMDAVSAD
#> 5       NA
#> 4       NA
#> 3     21.8
#> 2     14.2
#> 1     16.9
```

### 2. Searching the NHANES database


Comprehensive lists of NHANES variables are maintained for each data group. For example, the demographics variables are available at https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=Demographics. This section describes how to search the NHANES database.

----
  
#### 2.1 Searching for tables
  
The function `nhanesSearchTableNames` lets users search for tables in the database using the table name. For example, we can search the blood pressure related tables using the following code. We search for the string "BPX" as the parameters based on the CDC table name conventions. This also demonstrates the naming convention that is often (although not always) used by the CDC.  There is generally a base name (some short set of uppercase characters) and then a suffix, for all but the first cycle, that increases lexicographically one letter per cycle.  If you click on the next button in the table below you will see that there is one table named "BPXO_J" which is a bit different from the others. According to the documentation during the 2017-2018 cycle *a BP methodology study was conducted to compare BP measurements obtained by a physician using a mercury sphygmomanometer to those obtained by a health technician using an oscillometric device.*


```r
res = nhanesSearchTableNames("BPX", details=TRUE)
datatable(res)
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```

We provide access to functions within the database for matching strings. In the example below the string "BPX[_]" string is passed to the database engine directly.  This string matches only tables containing the string "BPX_"; therefore, the table named "BPXO_J" will not match. We note that the table named "BPX" also has no underscore and it also will not match. Recall that in the first survey cycle the table names have no underscore or suffix.


```r
res = nhanesSearchTableNames("BPX[_]", details=TRUE)
datatable(res)
#> Auto configuration failed
#> 140393665206208:error:25066067:DSO support routines:DLFCN_LOAD:could not load the shared library:dso_dlfcn.c:185:filename(libproviders.so): libproviders.so: cannot open shared object file: No such file or directory
#> 140393665206208:error:25070067:DSO support routines:DSO_load:could not load the shared library:dso_lib.c:244:
#> 140393665206208:error:0E07506E:configuration file routines:MODULE_LOAD_DSO:error loading dso:conf_mod.c:285:module=providers, path=providers
#> 140393665206208:error:0E076071:configuration file routines:MODULE_RUN:unknown module name:conf_mod.c:222:module=providers
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```

----  

#### 2.2 Searching for variables.
  
  ##FIXME: somehow we need to figure out a search strategy that puts some of the output into an HTML page, or a searchable datatable
  ##FIXME (TJFS): I am not sure what you mean by this
  ## the problem with the return values is that they are often long and fairly complex, that is not easy to go through at the R level - if we push this into a datatable and open it in the browser then they could search through that.
  ## FIXME: one way to do this is to just capture the datatable output and push it to html and open it in the browser -

#### 2.3 Searching for Variables

 One of the main challenges in using the NHANES data set is finding the tables that contain the data you want to analyze.  In this section we outline some of the basic methods you can use to do the searching. The returned value can be put into a searchable data table that you can use to further filter, sort and search for specific variables.
 
The primary purpose of the `nhanesSearch` function is to facilitate the search for specific text strings within the variable description field. By utilizing this function, users can obtain a convenient data frame that includes the names of variables whose descriptions meet the specified criteria. Furthermore, the function offers additional filtering options, such as specifying a start and stop year, enabling users to further refine their search results.



```r
# nhanesSearch use examples
#
# Search on the word bladder, restrict to the 2001-2008 surveys, 
# print out 50 characters of the variable description
bl = nhanesSearch("bladder", ystart=2001, ystop=2008, nchar=50)
dim(bl)
#> [1] 26  7
#
# Search on "urin" (will match urine, urinary, etc), from 1999-2010, return table names only
urin = nhanesSearch("urin", ignore.case=TRUE, ystop=2010, namesonly = TRUE)
length(urin)
#> [1] 248
urin[1:10]
#>  [1] "AGQ_D"    "AL_IGE_D" "ALB_CR_D" "ALB_CR_E" "ALB_CR_F" "ALDUST_D" "ALQY_F"   "AQQ_E"    "AQQ_F"    "BAQ"
#
```

The `nhanesSearch` function also provides an option to exclude specific matches. In the previous search, any variable name containing the word "during" would have been considered a match. However, by excluding these terms in the output, the function ensures results that more accurately reflect your desired specifications.

```r
urinEx = nhanesSearch("urin", exclude_terms="during", ignore.case=TRUE, ystop=2010, namesonly=TRUE)
length(urinEx)
#> [1] 96
urinEx[1:10]
#>  [1] "AL_IGE_D" "ALB_CR_D" "ALB_CR_E" "ALB_CR_F" "ALDUST_D" "CAFE_F"   "CARB_D"   "CARB_E"   "CBQPFA_E" "CBQPFA_F"
```

You can also restrict the search to specific data groups (such as EXAM).
Several other types of search are shown below.


```r
#
# Restrict search to 'EXAM' and 'LAB' data groups. Explicitly list matching and exclude terms, leave ignore.case set to default value of FALSE. Search surveys from 2009 to present.
urinrest = nhanesSearch(c("urin", "Urin"), exclude_terms=c("During", "eaten during", "do during"), data_group=c('EXAM', 'LAB'), ystart=2009)
head(urinrest) # namesonly=TRUE by default, and it only returns an vector
#>   Variable.Name                  Variable.Description Data.File.Name   Data.File.Description Begin.Year EndYear
#> 1        URX1NP      1-Aminonaphthalene urine (pg/mL)           AA_H Aromatic Amines - Urine       2013    2014
#> 2      URD1NPLC 1-Aminonaphthalene urine Comment Code           AA_H Aromatic Amines - Urine       2013    2014
#> 3        URX2NP      2-Aminonaphthalene urine (pg/mL)           AA_H Aromatic Amines - Urine       2013    2014
#> 4      URD2NPLC 2-Aminonaphthalene urine Comment Code           AA_H Aromatic Amines - Urine       2013    2014
#> 5        URX4BP         4-Aminobiphenyl urine (pg/mL)           AA_H Aromatic Amines - Urine       2013    2014
#> 6      URD4BPLC    4-Aminobiphenyl urine Comment Code           AA_H Aromatic Amines - Urine       2013    2014
#>    Component
#> 1 Laboratory
#> 2 Laboratory
#> 3 Laboratory
#> 4 Laboratory
#> 5 Laboratory
#> 6 Laboratory
#
# Search on "tooth" or "teeth", all years
teeth = nhanesSearch(c("tooth", "teeth"), ignore.case=TRUE)
head(teeth)
#>   Variable.Name
#> 1        OHQ010
#> 2        OHQ020
#> 3        OHQ630
#> 4        OHQ640
#> 5        OHQ650
#> 6        OHQ660
#>                                                                                                               Variable.Description
#> 1 Now I have some questions about {your/SP's} mouth and teeth. How would you describe the condition of {your/SP's} mouth and teeth
#> 2 How often {do you/does SP} limit the kinds or amounts of food {you/s/he} eat{s} because of problems with {your/his/her} teeth or
#> 3 How often during the last year (have you/ has SP) felt that life in general was less satisfying because of problems with (your/h
#> 4 How often during the last year (have you/has SP) had difficulty doing (your/his/her) usual jobs or attending school because of p
#> 5 How often during the last year (have you/has SP's) sense of taste been affected by problems with (your/his/her) teeth mouth or d
#> 6 How often during the last year (have you/has SP) avoided particular foods because of problems with (your/his/her) teeth mouth or
#>   Data.File.Name Data.File.Description Begin.Year EndYear     Component
#> 1          OHQ_B           Oral Health       2001    2002 Questionnaire
#> 2          OHQ_B           Oral Health       2001    2002 Questionnaire
#> 3          OHQ_C           Oral Health       2003    2004 Questionnaire
#> 4          OHQ_C           Oral Health       2003    2004 Questionnaire
#> 5          OHQ_C           Oral Health       2003    2004 Questionnaire
#> 6          OHQ_C           Oral Health       2003    2004 Questionnaire
#
# Search for variables where the variable description begins with "Tooth"
sttooth = nhanesSearch("^Tooth")
dim(sttooth)
#> [1] 331   7
datatable(sttooth)
#> Auto configuration failed
#> 140245029119936:error:25066067:DSO support routines:DLFCN_LOAD:could not load the shared library:dso_dlfcn.c:185:filename(libproviders.so): libproviders.so: cannot open shared object file: No such file or directory
#> 140245029119936:error:25070067:DSO support routines:DSO_load:could not load the shared library:dso_lib.c:244:
#> 140245029119936:error:0E07506E:configuration file routines:MODULE_LOAD_DSO:error loading dso:conf_mod.c:285:module=providers, path=providers
#> 140245029119936:error:0E076071:configuration file routines:MODULE_RUN:unknown module name:conf_mod.c:222:module=providers
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```


#### 2.4 nhanesSearchVarName

Now suppose we wanted to find variables names that contain information about (low density lipoproteins).  To do that one can first use the `nhanesSearch` function to retrieve a master list of any and all questions matching this search term in it's *Description*. One can then use the output of this search to identify variable names of interest. The variable name can then be searched for using the `nhanesSearchVarName` function.  In the code below we find a variable names corresponding to LDLs and then find all the tables that contain a variable with that name.


```r
s1 = nhanesSearch("LDL", nchar=256, data_group="LAB")
DT::datatable(s1)
#> Auto configuration failed
#> 140225679890368:error:25066067:DSO support routines:DLFCN_LOAD:could not load the shared library:dso_dlfcn.c:185:filename(libproviders.so): libproviders.so: cannot open shared object file: No such file or directory
#> 140225679890368:error:25070067:DSO support routines:DSO_load:could not load the shared library:dso_lib.c:244:
#> 140225679890368:error:0E07506E:configuration file routines:MODULE_LOAD_DSO:error loading dso:conf_mod.c:285:module=providers, path=providers
#> 140225679890368:error:0E076071:configuration file routines:MODULE_RUN:unknown module name:conf_mod.c:222:module=providers
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```

Scrolling through the datatable we find that there are a number of variables that correspond to an actual LDL measurement, several are named `LBDLDL` and so we can now search for that variable.

```r
LDLTabs = nhanesSearchVarName('LBDLDL')
LDLTabs
#>  [1] "L13AM_B"  "L13AM_C"  "LAB13AM"  "TRIGLY_D" "TRIGLY_E" "TRIGLY_F" "TRIGLY_G" "TRIGLY_H" "TRIGLY_I" "TRIGLY_J"
```

### 3 nhanesCodebook

Information about each variable is stored in the NHANES code book. To access the NHANES code book one can use the `nhanesCodebook` function. The function returns a list of length 5 that provides pertinent information about the variable. The first four elements provide basic descriptor information, i.e. `Variable` is the variable name, `Description` is the actual text of the question (or a description of the lab value), `Target` tells you which participants were eligible to be asked and `SasLabel` is the variable label.
The 5th element, the `Codebook`, is a data frame providing information about the structure of the variable, such as which values the variable can take on. When you want to combine variables across study years you will need to be careful to ensure that the `Codebooks` are compatible.  NHANES has changed variables, added or removed possible answers, and done many other things as the questionnaires have evolved.  It is **not safe** to assume that an identical variable name will have an identical interpretation.
 

```r
  cb1 = nhanesCodebook(nh_table = LDLTabs[1], colname = "LBDLDL") 
  cb1
#> $LBDLDL
#> $LBDLDL$`Variable Name:`
#> [1] "LBDLDL"
#> 
#> $LBDLDL$`SAS Label:`
#> [1] "LDL-cholesterol (mg/dL)"
#> 
#> $LBDLDL$`English Text:`
#> [1] "LDL-cholesterol (mg/dL)"
#> 
#> $LBDLDL$`Target:`
#> [1] "Both males and females 3 YEARS - 150 YEARS"
#> 
#> $LBDLDL$LBDLDL
#>   Code.or.Value Value.Description Count Cumulative Skip.to.Item
#> 1     20 to 316   Range of Values  3643       3643         <NA>
#> 2             .           Missing   821       4464         <NA>
```

  The alert reader will have noticed the column labeled Cumulative.  The values in this column are provided by NHANES and can be used to check whether the data extraction you carried out aligns with their reported values.  The column labeled SkipToItem will be non-missing if there was some complex logic in how the survey was performed. In some cases a set of questions will be skipped for a subset of the participants, depending on their answer to the *current* question.  For example, if the current question was ``Have you ever been told by your doctor you have Diabetes?``, and then there say 10 follow-up questions asking about symptoms, someone who answered ``No`` would not want to answer those questions, and so the interviewer will skip over them, to the next relevant question for anyone who says ``No``. This makes for a good survey experience for the participants but it also makes the data analysis a bit messier.  The analyst will have to examine all the questions that can be skipped and assess how to deal with the values recorded.
  While we are on the subject of messy data, the `Target` information can also introduce structured missingness into your data. Some questions are only relevant to certain age groups, and in those cases the `Target` field will indicate who is going to be asked. Everyone outside of the `Target` range will have a missing value for that question.

### 4. Data manipulations

#### 4.1 unionQuery()

The `unionQuery()` function is designed to aggregate data across the years for a fixed Questionnaire. Thus we are assuming all the inputs have essentially the same columns and that all variables are measuring the same concept across years. This function then aggregates by appending rows and returns the results as a data frame. If there are columns that are unique to one (or a few) questionnaires then these will be filled in as NA in any questionnaires that don't have that column.  Currently this function does not check the code books for consistency of inputs across years; analysts will need to do that for themselves. 

For an example of how to utilize this function, we use the blood pressure tables BPX, BPX_B,...BPX_J from years 1999-2000 to 2017-2018. User can aggregate some or all of the data contained in relevant tables.  Note: we are showing this example for illustrative purposes and have not carefully checking the code book. We encourage you to take the time to always ensure that code book entries are compatible.


```r
nhanesSearchTableNames('BPX[_]')
#> [1] "BPX_B" "BPX_C" "BPX_D" "BPX_E" "BPX_F" "BPX_G" "BPX_H" "BPX_I" "BPX_J"

blood_df <- unionQuery(list(BPX_C=c("BPXDI1","BPXDI2","BPXSY1","BPXSY2"),
                            BPX_D=c("BPXDI1","BPXDI2","BPXSY1","BPXSY2")))
DT::datatable(blood_df[1:400,])
#> Auto configuration failed
#> 139684691142592:error:25066067:DSO support routines:DLFCN_LOAD:could not load the shared library:dso_dlfcn.c:185:filename(libproviders.so): libproviders.so: cannot open shared object file: No such file or directory
#> 139684691142592:error:25070067:DSO support routines:DSO_load:could not load the shared library:dso_lib.c:244:
#> 139684691142592:error:0E07506E:configuration file routines:MODULE_LOAD_DSO:error loading dso:conf_mod.c:285:module=providers, path=providers
#> 139684691142592:error:0E076071:configuration file routines:MODULE_RUN:unknown module name:conf_mod.c:222:module=providers
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```

#### 4.2 jointQuery()
The `jointQuery()` function, table list of table name and a set of column names, it merges the researched results and returns the results as a data frame. The data are joined using SEQN which is the unique identifier for individuals.

The example below is much more complex than our previous examples, but it is also a more realistic query example. We are collecting data across 4 tables, DEMO, BPQ, HDL and TRIGLY. And also across data collection cycles I and J.  We first construct our query string, note that it is important that every table appears twice, once with an **_I** and once with an **_J**. In addition the variables being selected must be the same for each cycle and each table.


```r
cols = list(DEMO_I=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
                     DEMO_J=c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2"),
                     BPQ_I=c('BPQ050A','BPQ020'),BPQ_J=c('BPQ050A','BPQ020'),
                     HDL_I=c("LBDHDD"),HDL_J=c("LBDHDD"), TRIGLY_I=c("LBXTR","LBDLDL"),
            TRIGLY_J=c("LBXTR","LBDLDL"))
data <- jointQuery(cols)
tdata = data[1:100,]
datatable(tdata)
#> Auto configuration failed
#> 139967535773632:error:25066067:DSO support routines:DLFCN_LOAD:could not load the shared library:dso_dlfcn.c:185:filename(libproviders.so): libproviders.so: cannot open shared object file: No such file or directory
#> 139967535773632:error:25070067:DSO support routines:DSO_load:could not load the shared library:dso_lib.c:244:
#> 139967535773632:error:0E07506E:configuration file routines:MODULE_LOAD_DSO:error loading dso:conf_mod.c:285:module=providers, path=providers
#> 139967535773632:error:0E076071:configuration file routines:MODULE_RUN:unknown module name:conf_mod.c:222:module=providers
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```



### 5. PHESANT-like process

The NHANES project provides thousands of phenotypes and exposures. Navigating these can be very challenging and we are in the process of developing tools that will aid users in navigating the data quickly and reliably. Developing tools that can better help analysts navigate data at this scale is important.  We are patterning our efforts on those that were developed for the UK Biobank (Bycroft et al. 2018) and specifically the PHESANT (Millard et al. 2017) package.  

We can run a PHESANT-like process to convert each column into data types. It also provides the ratio of unique values (`r_unique`), the proportion of zeros (`r_zeros`), and the ratio of NAs (`r_NAs`), which is calculated by the number of unique values, zeros, and NAs divided by total records. The categorical data types (ordered or unordered) are represented by integers, and we categorize them as multilevel. For example, education (DMDEDUC2) is labeled as Multilevel(7) which means it has 7 levels. Information on whether or not the levels are ordered would have to be obtain from the on-line NHANES documentation.



```r
phs_dat = phesant(data)
data = phs_dat$data
DT::datatable(phs_dat$phs_res)
#> Auto configuration failed
#> 140062286911424:error:25066067:DSO support routines:DLFCN_LOAD:could not load the shared library:dso_dlfcn.c:185:filename(libproviders.so): libproviders.so: cannot open shared object file: No such file or directory
#> 140062286911424:error:25070067:DSO support routines:DSO_load:could not load the shared library:dso_lib.c:244:
#> 140062286911424:error:0E07506E:configuration file routines:MODULE_LOAD_DSO:error loading dso:conf_mod.c:285:module=providers, path=providers
#> 140062286911424:error:0E076071:configuration file routines:MODULE_RUN:unknown module name:conf_mod.c:222:module=providers
#> Error in (function (url = NULL, file = "webshot.png", vwidth = 992, vheight = 744, : webshot.js returned failure value: 1
```

We can also find out which variables are categorical.

```r
categoricalVars = rownames(phs_dat$phs_res)[grep("^Multilevel", phs_dat$phs_res$types)]
categoricalVars
#> [1] "RIAGENDR"   "RIDRETH1"   "DMDEDUC2"   "BPQ050A"    "BPQ020"     "Begin.Year" "EndYear"
```


### 6.Setup factor levels for categorical variables

In the raw NHANES data stored in the database all categorical variables are represented as integers.  In order to make use of these for analysis you will need to transform them into factors in R.  

Categorical variables are presented with integers as shown below.


```r
data[,c('RIAGENDR', 'RIDRETH1','DMDEDUC2')] |> head() |> knitr::kable()
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> RIAGENDR </th>
   <th style="text-align:left;"> RIDRETH1 </th>
   <th style="text-align:left;"> DMDEDUC2 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Male </td>
   <td style="text-align:left;"> Non-Hispanic White </td>
   <td style="text-align:left;"> College graduate or above </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Male </td>
   <td style="text-align:left;"> Non-Hispanic White </td>
   <td style="text-align:left;"> High school graduate/GED or equivalent </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Male </td>
   <td style="text-align:left;"> Non-Hispanic White </td>
   <td style="text-align:left;"> High school graduate/GED or equivalent </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Female </td>
   <td style="text-align:left;"> Non-Hispanic White </td>
   <td style="text-align:left;"> College graduate or above </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Female </td>
   <td style="text-align:left;"> Non-Hispanic Black </td>
   <td style="text-align:left;"> Some college or AA degree </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Female </td>
   <td style="text-align:left;"> Mexican American </td>
   <td style="text-align:left;"> 9-11th grade (Includes 12th grade with no diploma) </td>
  </tr>
</tbody>
</table>


And the real factor levels for year 2003-2004 can be found in [the codebook]() as shown below.
![gender](images/gender.png){width=85%}
![enthinicity](images/ethinicity.png){width=85%}
![education](images/edu.png){width=85%}


The data from NHANES comes as tables with integer codes for each of the levels of a factor variable.  A separate file, one for each cycle and questionnaire, has the map from the codes to the text description of what the levels mean. Because the chances of errors if users have untranslated variables (e.g. treating them as integers for example) we automatically translate all of these tables.  There is a way to access the raw data that is explained in a different vignette.

The code below is how you would do the translation using the `nhanesA` package.  But in the NHANES docker container this is not needed.



```r
##now we can translate the variables that need to be translated
t1 = nhanesTranslate("DEMO_J",c("RIDAGEYR","RIAGENDR","RIDRETH1","DMDEDUC2","years"),data=data)
datatable(t1[1:100,c('SEQN','RIDAGEYR','RIAGENDR', 'RIDRETH1')] )
```


Currently, we are doing as the following flow chat, but both the ordered and unordered are considered as multilevel.
![PHESANT flow chat](images/phesant_like.png){width=80%}

