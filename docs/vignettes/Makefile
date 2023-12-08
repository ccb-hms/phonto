
all: nhanes-introduction.md nhanes-local.md search-tables.md diagnostics-basics.md diagnostics-codebook.md survey_weights_tutorial.md

%.md: %.rmd
	# Rscript -e "rmarkdown::render('$<')"
	Rscript -e "knitr::knit('$<')"
