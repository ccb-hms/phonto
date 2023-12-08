
all: nhanes-introduction.md nhanes-local.md search-tables.md diagnostics-basics.md diagnostics-codebook.md survey_weights_tutorial.md cobalt_paper.md quick_start.md VariableClassification.md

%.md: %.rmd
	# Rscript -e "rmarkdown::render('$<')"
	Rscript -e "knitr::knit('$<')"
