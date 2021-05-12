# Makefile for latex compilation.
# © Yiannis Hadjimichael, 11 May 2021
#
# This makefile gives the option to complile the same LaTeX document with
# "pdflatex + biber (or bibtex) + pdflatex (x2)" command when two (or more) pdf outputs are desired.
#
# At the beginning of the .tex file a boolean variable (ifpaper) is set to "journaltrue"
# for the default latex configuration or "journalfalse" for the alternative one.
# This is useful when two different latex configurations are used to produce pdf outputs
# out of a single .tex file; for example, a pdf output based on a journal's template and a pdf
# output output for a pre-print or arXiv version.
#
# By default both compilations do not crop pdf and/or eps figures, however this is possible
# by running the corresponding make commands, e.g., make journal-crop.
# The "pdfcrop" package is used for removing the unnecessary white space before running
# latex/pdflatex commands. The package is contained in Tex Live and Mik Tex distributions and
# can be also downloaded from https://www.ctan.org/pkg/pdfcrop?lang=en
#
# LATEX warnings in .log file are shown after compilations.
#
# make journal:		journal configuration
# make journal-crop:    journal configuration with cropping figures before latex compilation
# make wias:		WIAS configuration
# make wias-crop:    	WIAS configuration with cropping figures before latex compilation
#
# Keyword explanations:
#	@  :					avoid displaying the command displayed by make
#	$< :					the first item in the dependency list
#	$@ :					the name of the target
#	$(word #,$^) :				the name of the #th dependency
#	dvips -Ppdf -G1 $@ -o :			-Ppdf option to include Type 1 (scalable) fonts in the PS file
#						-G1 (or -G0) option to fix a bug in versions of dvips earlier than 5.90
#						(see http://www-rohan.sdsu.edu/~aty/bibliog/latex/LaTeXtoPDF.html)
#	grep -A N --color :			output N lines in color after the line containing the string found by grep
#	pdfcrop [file.pdf] :			cropping pdf file
#	pdftops -eps [file.pdf] [file.eps] : 	converts file to .eps



### Below are the only variables that need to be set ###
# FILE:		the main tex file to compile
# TEMPLATES:	the different templates used to produced pdf outputs
# BIBENGINES:	the corresponding bibliography compiler for each template
# FLAGS:	the corresponding change of flags in the .tex file to enable switching from one template to another

FILE = positivity
TEMPLATES = journal wias
BIBENGINES = biber bibtex
FLAGS = journalfalse/journaltrue journaltrue/journalfalse



### Code part of Makefile ###
FIGURES = figures
PDF = $(FIGURES)/*.pdf
EPS = $(FIGURES)/*.eps
TEMPLATE_INFO = .latex_template


ifneq ("$(wildcard $(TEMPLATE_INFO))","")
	PREV_TEMPLATE = $(shell cat $(TEMPLATE_INFO))
else
	PREV_TEMPLATE =
endif

# code from https://stackoverflow.com/questions/62337774/using-word-function-in-makefile-with-variable
# $1 - list to check
# $2 - element to find
# returns - index of element
define get_index
	$(sort $(eval index_count :=) \
	$(foreach word,$(1), \
		$(eval index_count := $(index_count) x) \
		$(if $(findstring $(word),$(2)),$(words $(index_count)))) \
	)
endef

$(foreach template,$(TEMPLATES), \
	$(eval index = $(call get_index,$(TEMPLATES),$(template)) ) \
	$(eval $(word $(index),$(TEMPLATES))_BIBENGINE := $(word $(index),$(BIBENGINES))) \
	$(eval $(word $(index),$(TEMPLATES))_FLAG := $(word $(index),$(FLAGS))) \
)



# Make recipes:

.PHONY: $(TEMPLATES) compile croppdf pdf2eps clean-eps clean

$(TEMPLATES):
	@$(MAKE) TEMPLATE=$@ BIBENGINE=$($@_BIBENGINE) FLAG=$($@_FLAG) compile
	@echo "$@" > $(TEMPLATE_INFO) # update TEMPLATE_INFO

compile:
	@if [ "$(PREV_TEMPLATE)" != "$(TEMPLATE)" ]; then \
		echo "Change template $(FLAG) in $(FILE).tex ...\n" ; \
		sed -i.bak s/$(FLAG)/ $(FILE).tex ; \
	fi

	@echo "LaTex compilation ..."
	@$(MAKE) $(FILE).out

$(FILE).out: $(FILE).tex
	@echo "Removing $(FILE).bbl to enable biber/bibtex compilation ..."
	@rm -f $(FILE).bbl
	@rm -f $(FILE).aux
	pdflatex $<
	$(BIBENGINE) $(FILE) || true
	pdflatex $<
	pdflatex $<
	@echo "\nChecking for errors or warnings ...\n"
	@grep -A 1 --color 'Error\|Warning\|Overfull\|Underfull\|Badbox' $(FILE).log || true

croppdf:
	@for file in $(PDF) ; do \
		pdfcrop $$file ; \
		mv $${file%.*}-crop.pdf $${file%.*}.pdf; \
	done

pdf2eps:
	@for file in $(PDF) ; do \
		pdfcrop $$file ; \
		pdftops -eps $${file%.*}-crop.pdf $${file%.*}.eps ; \
		rm $${file%.*}-crop.pdf ; \
	done

clean-eps:
	@$(RM) $(EPS)

clean:
	@echo "Removing latex auxiliary files."
	@$(RM)  $(FILE).aux*
	@$(RM)  $(FILE).bbl
	@$(RM)  $(FILE).bcf
	@$(RM)  $(FILE).blg
	@$(RM)  $(FILE)-blx.bib
	@$(RM)  $(FILE).dvi
	@$(RM)  $(FILE).idx
	@$(RM)  $(FILE).ilg
	@$(RM)  $(FILE).ind
	@$(RM)  $(FILE).log
	@$(RM)  $(FILE).lof
	@$(RM)  $(FILE).lot
	@$(RM)  $(FILE).nav
	@$(RM)  $(FILE).out
	@$(RM)  $(FILE).ps
	@$(RM)  $(FILE).run.xml
	@$(RM)  $(FILE).synctex.gz
	@$(RM)  $(FILE).tex.bak
	@$(RM)  $(FILE).thm
	@$(RM)  $(FILE).toc
	@$(RM)  .latex_template

clean-all: clean clean-eps
