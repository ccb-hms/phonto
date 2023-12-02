---
layout: default
title: "Accessing NHANES data locally"
editor_options: 
  chunk_output_type: console
---



In its default mode of operation, functions in the __nhanesA__ package
scrape data directly from the CDC website each time they are invoked.
The advantage is simplicity; users only need to install the nhanesA
package without any additional setup.  However, the response time is
contingent upon internet speed and the size of the requested data.

Starting with version `0.8.x`, __nhanesA__ offers two alternatives:
using a prebuilt SQL database and using a mirror.

# Using SQL database

Functions in the __nhanesA__ package can obtain (most) data from a
suitably configured Microsoft SQL Server database instead of accessing
the CDC website directly. The easiest way to obtain such a database is
to use the [docker image](https://github.com/ccb-hms/NHANES) created
as part of the Epiconductor project. This docker image includes
versions of R and RStudio, and is configured in a way that causes
__nhanesA__ to use the database when it is run inside the docker
instance.

It is also possible to configure __nhanesA__ to use a SQL database
when running _outside_ a docker instance, provided the machine has
access to the database, which could be running in a docker instance on
the same machine, or on another machine in the local network. To do
so, the following environment variables need to be define prior to
loading the __nhanesA__ package:

- `EPICONDUCTOR_CONTAINER_VERSION` (e.g., `v0.12.0`)
- `EPICONDUCTOR_COLLECTION_DATE` (e.g., `2023-11-21`)
- `EPICONDUCTOR_DB_DRIVER` (e.g., `FreeTDS` on Linux)
- `EPICONDUCTOR_DB_SERVER` (e.g., `localhost`)
- `EPICONDUCTOR_DB_PORT` (e.g., `1433`)

The first two are for information, and need not actually match the
version of the database. They indicate the date on which a snapshot of
the NHANES data was collected from the CDC website, and are defined
suitably when running inside the docker image. However, they must be
specified explicitly when trying to connect to the database from an
instance of R running outside docker.

The last three environment variables define the details of how to
connect to the database. For details, see the
[DBI](https://github.com/r-dbi/DBI) and
[odbc](https://github.com/r-dbi/odbc) packages.


## Usage 

Although there are minor differences, the __nhanesA__ package should
ideally behave similarly whether or not a database is being used. When
a database is successfully found on startup, the package sets an
option called `use.db` to `TRUE`.


```r
library(nhanesA)
nhanesOptions()
```

```
$use.db
[1] TRUE
```

Even in this case, it is possible to pause use of the database and
revert to downloading from the CDC website by setting


```r
nhanesOptions(use.db = FALSE, log.access = TRUE)
```

The `log.access` option, if set, causes a message to be printed every
time a web resource is accessed.

With these settings, we get


```r
bpq_b_web <- nhanes("BPQ_B")
```

```
Downloading: https://wwwn.cdc.gov/Nchs/Nhanes/2001-2002/BPQ_B.XPT
```

On the other hand, if we use the database, we get


```r
nhanesOptions(use.db = TRUE)
bpq_b_db <- nhanes("BPQ_B")
```

The two versions have minor differences: The order of rows and columns
may be different, and categorical variables may be represented either
as factors of character strings. However, as long as the data has not
been updated on the NHANES website, the contents should be identical.


```r
str(bpq_b_web[1:10])
```

```
'data.frame':	6634 obs. of  10 variables:
 $ SEQN   : num  9966 9967 9968 9969 9970 ...
 $ BPQ010 : Factor w/ 7 levels "Less than 6 months ago,",..: 1 1 1 1 2 2 1 1 3 1 ...
 $ BPQ020 : Factor w/ 3 levels "Yes","No","Don't know": 2 2 1 2 2 1 2 2 2 2 ...
 $ BPQ030 : Factor w/ 3 levels "Yes","No","Don't know": NA NA 1 NA NA 2 NA NA NA NA ...
 $ BPQ040A: Factor w/ 3 levels "Yes","No","Don't know": NA NA 1 NA NA 1 NA NA NA NA ...
 $ BPQ040B: Factor w/ 3 levels "Yes","No","Don't know": NA NA 2 NA NA 1 NA NA NA NA ...
 $ BPQ040C: Factor w/ 3 levels "Yes","No","Don't know": NA NA 1 NA NA 1 NA NA NA NA ...
 $ BPQ040D: Factor w/ 3 levels "Yes","No","Don't know": NA NA 2 NA NA 1 NA NA NA NA ...
 $ BPQ040E: Factor w/ 3 levels "Yes","No","Don't know": NA NA 2 NA NA 1 NA NA NA NA ...
 $ BPQ040F: Factor w/ 3 levels "Yes","No","Don't know": NA NA 2 NA NA 2 NA NA NA NA ...
```

```r
str(bpq_b_db[1:10])
```

```
'data.frame':	6634 obs. of  10 variables:
 $ SEQN   : int  9975 10025 10060 10074 10077 10093 10410 10542 10592 10593 ...
 $ BPQ010 : chr  "Less than 6 months ago" "Less than 6 months ago" "Less than 6 months ago" "Less than 6 months ago" ...
 $ BPQ020 : chr  "No" "No" "No" "No" ...
 $ BPQ030 : chr  NA NA NA NA ...
 $ BPQ040A: chr  NA NA NA NA ...
 $ BPQ040B: chr  NA NA NA NA ...
 $ BPQ040C: chr  NA NA NA NA ...
 $ BPQ040D: chr  NA NA NA NA ...
 $ BPQ040E: chr  NA NA NA NA ...
 $ BPQ040F: chr  NA NA NA NA ...
```


