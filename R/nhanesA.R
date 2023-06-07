##some variable definitions from nhanesA package - copyright by Christopher Endres
## # Christopher J. Endres 09/18/2022
# Create a list of nhanes groups
# Include convenient aliases
nhanes_group <- list()
nhanes_group['DEMO']          <- "DEMOGRAPHICS"
nhanes_group['DEMOGRAPHICS']  <- "DEMOGRAPHICS"
nhanes_group['DIETARY']       <- "DIETARY"
nhanes_group['DIET']          <- "DIETARY"
nhanes_group['EXAMINATION']   <- "EXAMINATION"
nhanes_group['EXAM']          <- "EXAMINATION"
nhanes_group['LABORATORY']    <- "LABORATORY"
nhanes_group['LAB']           <- "LABORATORY"
nhanes_group['QUESTIONNAIRE'] <- "QUESTIONNAIRE"
nhanes_group['Q']             <- "QUESTIONNAIRE"
nhanes_group['LIMITED']       <- "NON-PUBLIC"
nhanes_group['LTD']           <- "NON-PUBLIC"
nhanes_survey_groups <- unlist(unique(nhanes_group))

nhanes_min_year = "1999"
nhanes_max_year = "2023"
nhanes_years = c("1999", "2000", "2001", "2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010",
    "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023")

# Although continuous NHANES is grouped in 2-year intervals,
# for convenience we want to specify using a single year
nh_years <- list()
nh_years['1999'] <- "1999-2000"
nh_years['2000'] <- "1999-2000"
nh_years['2001'] <- "2001-2002"
nh_years['2002'] <- "2001-2002"
nh_years['2003'] <- "2003-2004"
nh_years['2004'] <- "2003-2004"
nh_years['2005'] <- "2005-2006"
nh_years['2006'] <- "2005-2006"
nh_years['2007'] <- "2007-2008"
nh_years['2008'] <- "2007-2008"
nh_years['2009'] <- "2009-2010"
nh_years['2010'] <- "2009-2010"
nh_years['2011'] <- "2011-2012"
nh_years['2012'] <- "2011-2012"
nh_years['2013'] <- "2013-2014"
nh_years['2014'] <- "2013-2014"
nh_years['2015'] <- "2015-2016"
nh_years['2016'] <- "2015-2016"
nh_years['2017'] <- "2017-2018"
nh_years['2018'] <- "2017-2018"
nh_years['2019'] <- "2019-2020"
nh_years['2020'] <- "2019-2020"
nh_years['2021'] <- "2021-2022"
nh_years['2022'] <- "2021-2022"
nh_years['2023'] <- "2023-2024"
nh_years['2024'] <- "2023-2024"

# Continuous NHANES table names have a letter suffix that indicates the collection interval
data_idx <- list()
data_idx["A"] <- '1999-2000'
data_idx["a"] <- '1999-2000'
data_idx["B"] <- '2001-2002'
data_idx["b"] <- '2001-2002'
data_idx["C"] <- '2003-2004'
data_idx["c"] <- '2003-2004'
data_idx["D"] <- '2005-2006'
data_idx["E"] <- '2007-2008'
data_idx["F"] <- '2009-2010'
data_idx["G"] <- '2011-2012'
data_idx["H"] <- '2013-2014'
data_idx["I"] <- '2015-2016'
data_idx["J"] <- '2017-2018'
data_idx["K"] <- '2019-2020'
data_idx["L"] <- '2021-2022'
data_idx["M"] <- '2023-2024'

anomalytables2005 <- c('CHLMD_DR', 'SSUECD_R', 'HSV_DR')
nchar_max <- 1024
nchar_default <- 128
#------------------------------------------------------------------------------
# An internal function that determines which survey year the table belongs to.
# For most tables the year is indicated by the letter suffix following an underscore.
# E.g. for table 'BPX_E', the suffix is '_E'
# If there is no suffix, then we are likely dealing with data from 1999-2000.
.get_year_from_nh_table <- function(nh_table) {
  if(nh_table %in% anomalytables2005) {return('2005-2006')}
  if(length(grep('^P_', nh_table))>0) {return('2017-2018')} # Pre-pandemic
  if(length(grep('^Y_', nh_table))>0) {return('Nnyfs')} # Youth survey
  nhloc <- data.frame(stringr::str_locate_all(nh_table, '_'))
  nn <- nrow(nhloc)
  if(nn!=0){ #Underscores were found
    if((nhloc$start[nn]+1) == nchar(nh_table)) {
      idx <- stringr::str_sub(nh_table, -1, -1)
      if(idx=='r'||idx=='R') {
        if(nn > 1) {
          newloc <- nhloc$start[nn-1]+1
          idx <- stringr::str_sub(nh_table, newloc, newloc)
        } else {stop('Invalid table name')}
      }
      return(data_idx[idx])
    } else { ## Underscore not 2nd to last. Assume table is from the first set.
      return("1999-2000")}
  } else { #If there are no underscores then table must be from first survey
    return("1999-2000")
  }
#    nh_year <- "1999-2000"
}

#------------------------------------------------------------------------------
# An internal function that converts a year into the nhanes interval.
# E.g. 2003 is converted to '2003-2004'
# @param year where year is numeric in yyyy format
# @return The 2-year interval that includes the year, e.g. 2001-2002
#
.get_nh_survey_years <- function(year) {
  if(length(year) > 1) {
     warning("more than one year input, using only the first one")
     year = year[1]
  }
  if(as.character(year) %in% names(nh_years)) {
    return( as.character(nh_years[as.character(year)]) )
  }
  else {
    stop('Data for year ', year, ' are not available')
    return(NULL)
  }
}

# Internal function to determine if a number is even
.is.even <- function(x) {x %% 2 == 0}

####end of copyright Christopher J. Endres 09/18/2022
######
#####
#####
########################################################


#' Returns a list of table names for the specified survey group.
#'
#' @param data_group The type of survey (DEMOGRAPHICS, DIETARY, EXAMINATION, LABORATORY, QUESTIONNAIRE). Abbreviated terms may also be used: (DEMO, DIET, EXAM, LAB, Q).
#' @param year The year in yyyy format where 1999 <= yyyy.
#' @param nchar Truncates the table description to a max length of nchar.
#' @param details If TRUE then a more detailed description of the tables is returned (default=FALSE).
#' @param namesonly 	If TRUE then only the table names are returned (default=FALSE).
#' @param includerdc If TRUE then RDC only tables are included in list (default=FALSE).
#'
#' @return Returns a data frame that contains table attributes. If namesonly=TRUE, then a character vector of table names is returned.
#' @export
#'
#' @examples nhanesTables('EXAM', 2007)
nhanesTables = function( data_group, year,
      nchar = 128,  details = FALSE,
      namesonly = FALSE, includerdc = FALSE ) {

  # ##check if they are using the short name
  if( data_group %in% names(nhanes_group) )
      data_group = nhanes_group[data_group]
  if ( !(data_group %in% nhanes_group) )
    stop("Invalid survey group")


  if (is.numeric(year))
     EVEN = .is.even(year)
  else stop("Invalid year")
  ##construct SQL queries


  tables = paste0("SELECT Questionnaire AS 'Data.File.Name',
                Description as 'Data.File.Description',
                BeginYear as 'Begin.Year',
                DataGroup as Component, EndYear
                FROM
                QuestionnaireDescriptions where DataGroup='",
                    data_group, "' and ", ifelse(EVEN, "EndYear", "BeginYear"), "=",year)


  if(details==FALSE){
    tables = paste0("SELECT Questionnaire AS 'Data.File.Name',
                Description as 'Data.File.Description'
                FROM
                QuestionnaireDescriptions where DataGroup='",
                    data_group, "' and ", ifelse(EVEN, "EndYear", "BeginYear"), "=",year)
  }

  nhanesQuery(tables)

}



##note for our system we only need nh_table - the other details are not relevant
##so no need to process or pay attention to them

#' Displays a list of variables in the specified NHANES table.
#'
#' @param data_group data_group: The type of survey (DEMOGRAPHICS, DIETARY, EXAMINATION,LABORATORY, QUESTIONNAIRE). Abbreviated terms may also beused: (DEMO, DIET, EXAM, LAB, Q).
#' @param nh_table The name of the specific table to retrieve.
#' @param details If TRUE then a more detailed description of the tables is returned (default=FALSE).
#' @param nchar Truncates the table description to a max length of nchar.
#' @param namesonly If TRUE then only the table names are returned (default=FALSE).
#'
#' @return The number of characters in the Variable Description to print. Default length is 128, which is set to enhance readability cause variable descriptions can be very long.
#' @export
#'
#' @examples nhanesTableVars('LAB', 'CBC_E')
#'@examples nhanesTableVars('CBC_E')
nhanesTableVars = function(data_group, nh_table, details = FALSE, nchar=128, namesonly = FALSE) {

  # FIXME: We need to add Use.Constraints when DB is updated
  param = match.call()
  if(is.null(param$nh_table)){
    nh_table = param$data_group
    data_group = NULL
  }

  sql = paste0("SELECT V.Variable AS 'Variable.Name',
                       SUBSTRING(V.Description,1,",nchar,") AS 'Variable.Description',
                       V.Questionnaire AS 'Data.File.Name',
                       SUBSTRING(Q.[Description],1,",nchar,") AS 'Data.File.Description',
                       V.BeginYear AS 'Begin.Year',
                       V.EndYear,
                       CONCAT(SUBSTRING(DataGroup,1,1),LOWER(SUBSTRING(DataGroup,2,20))) AS Component
                  FROM QuestionnaireDescriptions Q
                  JOIN QuestionnaireVariables V ON V.Questionnaire = Q.Questionnaire
                  WHERE V.Questionnaire = '",nh_table,"'")
  if(!is.null(data_group)){
    sql = paste0(sql," AND DataGroup LIKE '",data_group,"%'")
  }


  df = nhanesQuery(sql)
  if(namesonly){
    return(df$Variable.Name)
  }else if(!details){
    return(df[,c('Variable.Name','Variable.Description')])
  }else{
    return(df)
  }
}

#' Download/Load an NHANES table and return as a data frame.
#'
#' @param nh_table The name of the specific table to retrieve.
#'
#' @return  data frame
#' @export
#'
#' @examples nhanes('BPX_E')
#' @description Use to download/load NHANES data tables that are in SAS format.

nhanes = function(nh_table){
  sql = paste0("SELECT * FROM ",nh_table)
  df = nhanesQuery(sql)

  cols = paste0("SELECT Variable from
                QuestionnaireVariables where Questionnaire='",
                nh_table,
                "'")
  cols = nhanesQuery(cols)
  cols = cols$Variable
  cols = cols[!cols %in% c("years","DownloadUrl","Questionnaire")]
  df[,cols]
}


#' Search for tables that contain a specified variable,implementation of nhanesA::nhanesSearchVarName()
#'
#' @details The NHANES Comprehensive Variable List is scanned to find all data tables that contain the given variable name. Only a single variable name may be entered, and only exact matches will be found.
#' @param varnames Names of variable to match.
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#' @param includerdc If TRUE then RDC only tables are included in list (default=FALSE).
#' @param nchar Truncates the variable description to a max length of nchar.
#' @param namesonly 	If TRUE then only the table names are returned (default=TRUE).
#'
#' @return By default, a character vector of table names that include the specified variable is returned. If namesonly=FALSE, then a data frame of table attributes is returned.
#' @export
#'
#' @examples nhanesSearchVarName('BPXPULS',nchar=38, namesonly=FALSE))
#' @examples nhanesSearchVarName(c('BPXPULS','BMXBMI'),ystop=2004)
nhanesSearchVarName <- function(varnames = NULL,
                              ystart = NULL,
                              ystop = NULL,
                              includerdc = FALSE,
                              nchar = 128,
                              namesonly = TRUE){

  sql = paste0("SELECT V.Variable AS 'Variable.Name',
                       SUBSTRING(V.Description,1,",nchar,") AS 'Variable.Description',
                       V.Questionnaire AS 'Data.File.Name',
                       SUBSTRING(Q.[Description],1,",nchar,") AS 'Data.File.Description',
                       V.BeginYear AS 'Begin.Year',
                       V.EndYear,
                       CONCAT(SUBSTRING(DataGroup,1,1),LOWER(SUBSTRING(DataGroup,2,20))) AS Component
                  FROM QuestionnaireDescriptions Q
                  JOIN QuestionnaireVariables V ON V.Questionnaire = Q.Questionnaire
                  WHERE V.Variable IN (", toString(sprintf("'%s'", varnames)),")")



  if(!is.null(ystart)){
    sql <- paste(sql,"AND V.BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND V.EndYear <=",ystop)
  }

  df = nhanesQuery(sql)
  if(is.null(df)){
      warning(paste("Variable ",v, "is not found in the database!"))
    }


  if(namesonly){
    df = df$Data.File.Name
  }

  df

}


#' Search for matching table names, implementation of nhanesA::nhanesSearchTableNames()
#'
#' @param pattern Pattern of table names to match
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#' @param includerdc If TRUE then RDC only tables are included (default=FALSE).
#' @param nchar Truncates the variable description to a max length of nchar.
#' @param details If TRUE then complete table information from the comprehensive data list is returned (default=FALSE).
#'
#' @return Returns a character vector of table names that match the given pattern. If details=TRUE, then a data frame of table attributes is returned. NULL is returned when an HTML read error is encountered.
#' @export
#'
#' @examples nhanesSearchTableNames("BPX")
nhanesSearchTableNames <-  function(pattern = NULL,
                               ystart = NULL,
                               ystop = NULL,
                               includerdc = FALSE,
                               nchar = 128,
                               details = FALSE){

  sql <- paste0("SELECT DISTINCT
                        Questionnaire,TableName,
                        CONCAT(q.BeginYear, '-', q.EndYear) AS years
                      FROM QuestionnaireVariables q
                  WHERE Questionnaire LIKE '%",pattern,"%'"
  )
  if(!is.null(ystart)){
    sql <- paste(sql,"AND BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND EndYear <=",ystop)
  }
  if( includerdc ) warning("The DB has no restricted data")

  df = nhanesQuery(sql)

  if(is.null(df) | nrow(df)==0){
    warning(paste("Cannot find any table name like:",pattern,"!"))
  }

  if(details)
     return(df)
  else
     return(df$Questionnaire)
}



  ##rewritten to work columnwise
  ##for now silently skip over any continuous variable
  ##we have a clunky test for it - which should be replaced at some point
  translate = function(input_codes, data) {
     if( !all(names(input_codes) %in% names(data)))
       stop("name mismatch in translate")  ##FIXME - maybe figure out which one?
     for(i in names(input_codes) ) {
        bb = input_codes[[i]]
        if( bb[1, "Value.Description"] == "Range of Values" ) next
        z1 = data[,i]
        labels = bb$Value.Description[match(sort(unique(z1)), bb$Code.or.Value)]
        labels = labels[!is.na(labels)]
        data[,i] = factor(z1, labels = labels)
     }
     return(data)
  }
##
##translate = function(var_df, data){
##  for(i in 1:nrow(var_df)){
##    data[data[,var_df[i,]$Variable] == var_df[i,]$CodeOrValue,
##         var_df[i,]$Variable] = var_df[i,]$ValueDescription
##  }
##  data[unique(var_df$Variable)] = lapply(data[unique(var_df$Variable)], factor)
##  data
##}

#' Display code translation information.
#'
#' @param nh_table The name of the NHANES table to retrieve.
#' @param colnames 	The names of the columns to translate.
#' @param data If a data frame is passed, then code translation will be applied directly to the data frame.
#'             In that case the return argument is the code-translated data frame.
#' @param nchar Applies only when data is defined. Code translations can be very long. Truncate the length by setting nchar (default = 32).
#' @param mincategories The minimum number of categories needed for code translations to be applied to the data (default=2).
#' @param details If TRUE then all available table translation information is displayed (default=FALSE).
#' @param dxa If TRUE then the 2005-2006 DXA translation table will be used (default=FALSE).
#' @details Most NHANES data tables have encoded values. E.g. 1 = 'Male', 2 = 'Female'. Thus it is often helpful to view the code translations and perhaps insert the translated values in a data frame. Only a single table may be specified, but multiple variables within that table can be selected. Code translations are retrieved for each variable.
#'
#' @return The code translation table (or translated data frame when data is defined). Returns NULL upon error.
#' @export
#'
#' @examples v1 = nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1"))
#' @examples v2 = nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1"),data=TRUE)

nhanesTranslate = function( nh_table, colnames = NULL, data = FALSE, nchar = 32,
      mincategories = 2, details = FALSE, dxa = FALSE){

  if(length(nh_table) > 1 ) stop("you can only select one table")
  if(details){
    sql = "SELECT Variable,CodeOrValue AS 'Code.or.Value',ValueDescription AS 'Value.Description',
            Count,Cumulative,SkipToItem AS 'Skip.to.Item'
            FROM VariableCodebook WHERE Questionnaire='"
  } else {
    sql = "SELECT Variable,CodeOrValue AS 'Code.or.Value',ValueDescription AS 'Value.Description'
             FROM VariableCodebook WHERE Questionnaire='"
  }
  sql = paste0(sql,nh_table,"'")
  if(!is.null(colnames))
     sql = paste0(sql,"AND Variable IN (", toString(sprintf("'%s'", colnames)),")")

  df = nhanesQuery(sql)
  ans=split(df[-which(names(df)=="Variable")], df$Variable)
  ans=lapply(ans,function(x){row.names(x)=NULL;x}) # reset row names
  ##here we are going to let data either be a dataframe - in which case we translate in place
  ##or it can be TRUE or FALSE - in which case we extract the data and then translate
  if(is.data.frame(data)) {
     data=translate(ans, data)
     return(data)
  }
  if(data) {
    data = translate(ans,nhanes(nh_table))
    return(data)
  }
  return(ans)
  }


## explicitly this searches the Description field (which is the text read to the participant) of
## the QuestionaireVariables table. It should probably have some way to also consider the SASLabel
## do we know what nhanesA does?
##we should strip the TableName out of the return value - that is an implementation detail
#' Perform a search over the comprehensive NHANES variable list.
#'
#' @param search_terms List of terms or keywords.
#' @param exclude_terms List of exclusive terms or keywords.
#' @param data_group Which data groups (e.g. DIET, EXAM, LAB) to search. Default is to search all groups.
#' @param ignore.case 	Ignore case if TRUE. (Default=FALSE).
#' @param ystart Four digit year of first survey included in search, where ystart >= 1999.
#' @param ystop Four digit year of final survey included in search, where ystop >= ystart.
#' @param includerdc including document
#' @param nchar Truncates the variable description to a max length of nchar.
#' @param namesonly If TRUE then only the table names are returned (default=FALSE).
#'
#' @return Returns a data frame that describes variables that matched the search terms. If namesonly=TRUE, then a character vector of table names that contain matched variables is returned.
#' @export
#'
#' @examples b1 = nhanesSearch("bladder", ystart=2001, ystop=2008, nchar=50)
#' @examples b2 = nhanesSearch("urin", exclude_terms="During", ystart=2009)
#' @examples b3 = nhanesSearch(c("urine", "urinary"), ignore.case=TRUE, ystop=2006, namesonly=TRUE)
nhanesSearch = function( search_terms = NULL,
                         exclude_terms = NULL,
                         data_group = NULL,
                         ignore.case = FALSE,
                         ystart = NULL,
                         ystop = NULL,
                         includerdc = FALSE,
                         nchar = 128,
                         namesonly = FALSE){


  sql = paste0("SELECT V.Variable AS 'Variable.Name',
                       SUBSTRING(V.Description,1,",nchar,") AS 'Variable.Description',
                       V.Questionnaire AS 'Data.File.Name',
                       SUBSTRING(Q.[Description],1,",nchar,") AS 'Data.File.Description',
                       V.BeginYear AS 'Begin.Year',
                       V.EndYear,
                       CONCAT(SUBSTRING(DataGroup,1,1),LOWER(SUBSTRING(DataGroup,2,20))) AS Component
                  FROM QuestionnaireDescriptions Q
                  JOIN QuestionnaireVariables V ON V.Questionnaire = Q.Questionnaire
                  WHERE (V.Description COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '%")

  # COLLATE SQL_Latin1_General_CP1_CS_AS  : is to make case sensitive pattern match

  sql = paste0(sql,search_terms[1],"%'")
  # match multiple patterns
  if (length(search_terms)>=2){
    for (term in search_terms[2:length(search_terms)]){
      sql = paste0(sql," OR V.Description COLLATE SQL_Latin1_General_CP1_CS_AS LIKE '%",term,"%'")
    }
  }
  sql = paste0(sql,")")



  if(!is.null(exclude_terms)){
    for (term in exclude_terms){
          sql = paste0(sql," AND V.Description COLLATE SQL_Latin1_General_CP1_CS_AS NOT LIKE '%",term,"%'")
       }
  }

  if(ignore.case){
    sql = gsub("COLLATE SQL_Latin1_General_CP1_CS_AS", "", sql)
  }


  if(!is.null(data_group)){
    if(length(data_group>1)){
      sql = paste0(sql,"AND (DataGroup LIKE '%",data_group[1],"%'")
      for (term in data_group[2:length(data_group)]){
        sql = paste0(sql," OR DataGroup LIKE '%",term,"%'")
      }
      sql = paste0(sql,")")
    }else{
      sql = paste0(sql," AND DataGroup LIKE '%",data_group,"%'")
    }
  }



  sql = gsub("%\\^", "", sql) # address start with ..


  if(!is.null(ystart)){
    sql = paste(sql,"AND V.BeginYear >=",ystart)
  }
  if(!is.null(ystop)){
    sql <- paste(sql,"AND V.EndYear <=",ystop)
  }


  df = nhanesQuery(sql)
  if(namesonly){
    df = df$Data.File.Name
  }

  df
}


#' Display the NHANES codebook for selected variable.
#'
#' @param nh_table The name of the NHANES Questionaire that contains the desired variable.
#' @param colname The NHANES variable name.
#'
#' @return The codebook is returned as a list with components
#'         Variable, Description, Target, SasLabel and Codebook
#' @export
#'
#' @examples t1 = nhanesCodebook('AUX_D', 'AUQ020D')
#' @examples t2 = nhanesCodebook('DEMO_D', 'RIAGENDR')
nhanesCodebook = function(nh_table, colname){
  # FIXME: we need handle multiple targets once DB is updated!
  if(length(colname) > 1){
    stop("colname not accepts a list, please provide one colunm name only!")
  }
  sql = paste0("SELECT Variable AS 'Variable Name:',
                       SasLabel AS 'SAS Label:',
                       Description AS 'English Text:',
                       Target AS 'Target:'
                       FROM QuestionnaireVariables WHERE Questionnaire='",nh_table,"' AND Variable='",colname,"'")
  res = as.list(nhanesQuery(sql))
  if(length(res[[1]])==0){
    stop(paste0("The variable \"",colname,"\" is not found in the data file/table \"",nh_table,"\".
                Please check the table and variable name!"))
  }

  res[colname]=phonto::nhanesTranslate(nh_table, colname,details = TRUE)

  res
}


#' Show the doc page
#'
#' @param nh_table a NHANES table name
#'
#' @return open the CDC doc page
#' @export
#'
#' @examples nhanesCDCDataDoc("DEMO_C")
nhanesCDCDataDoc = function(nh_table){
  url_str = paste0("https://wwwn.cdc.gov/nchs/nhanes/",.get_year_from_nh_table(nh_table),"/",nh_table,".htm")
  browseURL(url_str)

}



