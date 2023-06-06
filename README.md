# phonto
PHONTO - PHenome ONTOlogy for NHANES



### Start Docker

#### Start Docker on Mac or Linux
```dockerfile
docker run  --rm --name nhanes-workbench \
        -v <YOUR LOCAL PATH>:/mnt/ \
        -d \
        -p 8787:8787 \
        -p 2200:22 \
        -p 1433:1433 \
        -e 'CONTAINER_USER_USERNAME=phonto' \
        -e 'CONTAINER_USER_PASSWORD=phonto' \
        -e 'ACCEPT_EULA=Y' \
        -e 'SA_PASSWORD=yourStrong(!)Password' \
         hmsccb/nhanes-workbench:latest
```
#### Start Docker on Windows
```dockerfile
docker run  --rm --name nhanes-workbench -d  -v <YOUR LOCAL PATH>:/mnt/ -p 8787:8787 -p 2200:22 -p 1433:1433  -e 'CONTAINER_USER_USERNAME=phonto'  -e 'CONTAINER_USER_PASSWORD=phonto' -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=yourStrong(!)Password' hmsccb/nhanes-workbench:latest
```


### Installation

You can install the development version of `phonto` from [GitHub](https://github.com/) with:
``` {r}
# install.packages("devtools")
devtools::install_github("ccb-hms/phonto")
```

### Examples

This is a basic example which shows you how to solve a common problem:
Testing to see if I can push to this directory (Teresa)
