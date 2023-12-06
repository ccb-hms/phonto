
all: nhanes-introduction.md nhanes-local.md search-tables.md diagnostics-basic.md

%.md: %.rmd
	# Rscript -e "rmarkdown::render('$<')"
	Rscript -e "knitr::knit('$<')"
