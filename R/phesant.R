

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

  order_cols <- names(distinct_cnt[distinct_cnt > 2 & distinct_cnt <= 20])



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

  # NEEDS FURTHER VERY TO BE ORDER
  unorder_cols <- names(distinct_cnt[distinct_cnt > 2])


  # **********************categorical (single) end************************
  continous_cols<-continous_cols[!is.na(continous_cols)]
  data_types[continous_cols] <- 'continuous'
  data_types[bin_cols] <- 'binary'
  data_types[order_cols] <- 'ordered'
  data_types[unorder_cols] <- 'unordered'


  df[, names(data_types[data_types %in% c("ordered", "unordered", "binary")])] <-
    lapply(df[, names(data_types[data_types %in% c("ordered", "unordered", "binary")])], as.factor)

  df[, names(data_types[data_types == "continuous"])] <-
    lapply(df[, names(data_types[data_types == "continuous"])], as.numeric)

  return(list(data = df, phs_types = data_types))

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
