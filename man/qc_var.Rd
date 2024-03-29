% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qc-codebook.R
\name{qc_var}
\alias{qc_var}
\alias{summary.qc_var}
\alias{print.qc_var}
\title{qc_var: QC on NHANES variable}
\usage{
qc_var(x, var = metadata_var(x), cb = metadata_cb(x), tab = metadata_tab())

\method{summary}{qc_var}(object, ...)

\method{print}{qc_var}(x, ...)
}
\arguments{
\item{x}{Character string naming a variable in one or more NHANES tables}

\item{var}{Optional data frame containing variable metadata}

\item{cb}{Optional data frame containing codebook metadata}

\item{tab}{Optional data frame containing table metadata}

\item{object}{An object of class \code{"qv_var"}}

\item{...}{Additional arguments, ignored}
}
\value{
An object of S3 class \code{"qc_var"} with suitable print and summary methods.
}
\description{
QC report for a variable in NHANES
}
\author{
Deepayan Sarkar
}
