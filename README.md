# phonto

PHONTO - PHenome ONTOlogy for NHANES

This package is designed to work with the Docker container available
from <https://github.com/ccb-hms/NHANES> That container can be obtained
by running the code below. Once installed and started users can log in
via a web browser to analyze NHANES data using any tools they would
like. The data live in a SQL database and can be accessed by a variety
of tools. We provide an interface via RStudio and this package works
together with the [nhanesA package](https://github.com/cjendres1/nhanes) to support a wide variety of analyses.
phonto provides a few vignettes and users can familiarize themselves
with the [Quick Start vignette](https://ccb-hms.github.io/phonto/vignettes/cobalt_paper.html) in order to find out how to interact with
the DB. More docs can be found [Phonto page](https://ccb-hms.github.io/phonto/)

### Start Docker

**1. Start Docker**

Start Docker on Mac or Linux

``` dockerfile
docker \
    run \
        --rm \
        --platform=linux/amd64 \
        --name nhanes-workbench \
        -v <YOUR LOCAL PATH>:/mnt/ \
        -d \
        -p 8787:8787 \
        -p 2200:22 \
        -p 1433:1433 \
        -e 'CONTAINER_USER_USERNAME=USER' \
        -e 'CONTAINER_USER_PASSWORD=PASSWORD' \
        -e 'ACCEPT_EULA=Y' \
        -e 'SA_PASSWORD=yourStrong(!)Password' \
         hmsccb/nhanes-workbench:version-0.2.0
```

Start Docker on Windows

``` dockerfile
docker ^
    run ^
        --rm ^
        --platform=linux/amd64 ^
        --name nhanes-workbench ^
  -v <YOUR LOCAL PATH>:/mnt/ ^
  -p 8787:8787 -p 2200:22 -p 1433:1433 ^
  -e "CONTAINER_USER_USERNAME=USER" ^
  -e "CONTAINER_USER_PASSWORD=PASSWORD" ^
  -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=yourStrong(!)Password" ^
  hmsccb/nhanes-workbench:version-0.2.0

```

**2. Log into Rstudio**

Log into RStudio via: <http://localhost:8787> and using the username set
in the command above. In the above command, the username and password
are set as `USER` and `PASSWORD`, respectively, but you can modify them if you prefer.

More details about the [NHANES
Docker](https://github.com/ccb-hms/NHANES).

<br/>

### Installation

You can install the development version of `phonto` from
[GitHub](https://github.com/) with:



``` r
# install.packages("devtools")

devtools::install_github("ccb-hms/phonto")
```

### Examples

This is a basic example which shows you how to solve a common problem:
Testing to see if I can push to this directory (Teresa)
