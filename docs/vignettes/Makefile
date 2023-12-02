
all: nhanes-introduction.md nhanes-local.md

%.md: %.rmd
	# Rscript -e "rmarkdown::render('$<')"
	Rscript -e "knitr::knit('$<')"
