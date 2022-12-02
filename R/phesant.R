

#' simple version of PHEnome Scan ANalysis Tool (PHESANT)
#'
#' @param df data frame to be processed
#'
#' @return suggested data types
#' @export
#'
#' @examples  phesant(df=nhanes)
phesant <- function(df) {
  cnt_data <- nrow(df)

  # set default data type as unknown
  data_types <- rep('unknown', ncol(df))
  names(data_types) <- colnames(df)

  # **********************continuous started*******************************
  # note the the following process including continuous and integers
  # int_cols <- sapply(df, is.integer)
  num_cols <- sapply(df, is.numeric)

  distinct_cnt <- n_unique(df,num_cols)
  same_ratio <-
    round(1 - distinct_cnt/cnt_data, 4)

  continous_cols <- names(same_ratio[same_ratio < 0.35])


  ex_continous_cols <- names(distinct_cnt[distinct_cnt > 20])
  continous_cols <- c(continous_cols, ex_continous_cols)

  # remove less than 10 participants
  paticipants_cnt <- sapply(df, function(x)
    sum(!is.na(x)))
  data_types[names(paticipants_cnt[paticipants_cnt < 10])] = "remove"


  # assign to order and binary
  bin_cols <- names(distinct_cnt[distinct_cnt <= 2])

  multilevel <- names(distinct_cnt[distinct_cnt > 2 & distinct_cnt <= 20])



  # **********************continuous end***********************************



  # **********************categorical (single) started*******************
  cat_cols <- sapply(df, is.character)
  cat_cols <- c(cat_cols,sapply(df, is.factor))

  # remove categories than less than 10 participants:
  cols <- names(cat_cols[cat_cols==TRUE])
  for (col in cols) {
    cnt <- table(df[,col])
    df[!df[,col] %in% names(cnt[cnt<=10]),]
  }
  # ordered or un-ordered:

  distinct_cnt <- n_unique(df,cat_cols)
  bin_cols <- c(bin_cols, names(distinct_cnt[distinct_cnt <= 2]))

  # NEEDS FURTHER VERY TO BE ORDERED
  factors_cols <- names(distinct_cnt[distinct_cnt > 2])


  # **********************categorical (single) end************************
  continous_cols<-continous_cols[!is.na(continous_cols)]
  data_types[continous_cols] <- 'Continuous'
  data_types[bin_cols] <- 'Binary'
  data_types[multilevel] <- 'Multilevel'
  data_types[factors_cols] <- 'Factors'


  # df[, names(data_types[data_types %in% c("Multilevel", "Factors", "Binary")])] <-
  #   lapply(df[, names(data_types[data_types %in% c("Multilevel", "Factors", "Binary")])], as.factor)

  # df[, names(data_types[data_types == "continuous"])] <-
  #   lapply(df[, names(data_types[data_types == "continuous"])], as.numeric)

  phs_res <- data.frame(
    r_unique =round(sapply(df, function(x) length(unique(x))/nrow(df)),6),
    r_zero = round(sapply(df, function(x) sum((x==0),na.rm=TRUE)/nrow(df)),6),
    r_NAs = round(sapply(df,function(x)sum(is.na(x))/nrow(df)),6)

  )

  # assign multilevel numbers
  uniq_len = sapply(df, function(x) length(unique(x)))
  data_types[data_types=='Multilevel'] = paste0(data_types[data_types=='Multilevel'],"(",
                                                uniq_len[names(data_types[data_types=='Multilevel'])],")")
  # filter and add non phenotype variables eg.SEQN
  phs_res$types = data_types
  # nonPhenotypes = read.csv("../data/nonPhenotypes.csv")
  nonPhenotypes = unique(nonPhenotypes[,c('names','types')])
  nonphtypes = intersect(rownames(phs_res),nonPhenotypes$names)
  phs_res[rownames(phs_res) %in% nonphtypes,]$types = nonPhenotypes[nonPhenotypes$names %in%nonphtypes, ]$types




  return(list(data = df, phs_res = phs_res))

}


n_unique <- function (df,cols){
  if (length(cols) == 0)
    return
  else{
    cols <- names(cols[cols==TRUE])
  }

  if(length(cols) == 1){
    n <- length(unique(df[,cols]))
    names(n) <- cols[1]
    return (n)
  }else{
    n <- sapply(df[,cols], function(x)
      length(unique(x)))
    return (n)
  }

}
