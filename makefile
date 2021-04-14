# Makefile for latex compilation.
#
# This makefile gives the option to complile the same LaTeX document with
# "pdflatex + bibtex(biber) + pdflatex(x2)" command when two (or more) pdf outputs are desired.
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
# make was:		WIAS configuration
# make wias-crop:    	WIAS configuration with cropping figures before latex compilation
#
# Keyword explanations:
#	$< :					the first item in the dependencies list
#	$@ :					the name of the target
#	dvips -Ppdf -G1 $@ -o :			-Ppdf option to include Type 1 (scalable) fonts in the PS file
#						-G1 (or -G0) option to fix a bug in versions of dvips earlier than 5.90
#						(see http://www-rohan.sdsu.edu/~aty/bibliog/latex/LaTeXtoPDF.html)
#	grep -A N --color :			output N lines in color after the line containing the string found by grep
#	pdfcrop [file.pdf] :			cropping pdf file
#	pdftops -eps [file.pdf] [file.eps] : 	converts file to .eps

FILE = positivity
FIGURES = figures
PDF = $(FIGURES)/*.pdf
EPS = $(FIGURES)/*.eps

journal: $(FILE).blg

journal-crop: croppdf $(FILE).blg

wias: $(FILE).bcf

wias-crop: croppdf $(FILE).bcf

$(FILE).blg: $(FILE).tex
	sed -i.bak 's/journalfalse/journaltrue/' $<
	rm -f $(FILE).bbl
	pdflatex $<
	biber $(FILE) || true
	$(MAKE) pdflatex
	rm -f $(FILE).bcf

$(FILE).bcf: $(FILE).tex
	sed -i.bak 's/journaltrue/journalfalse/' $<
	rm -f $(FILE).bbl
	pdflatex $<
	bibtex $(FILE) || true
	$(MAKE) pdflatex
	rm -f $(FILE).blg

pdflatex: $(FILE).tex
	pdflatex $<
	pdflatex $<
	rm -f $(FILE).aux
	grep -A 1 --color 'Error\|Warning\|Overfull\|Underfull\|Badbox' $(FILE).log || true

croppdf:
	for file in $(PDF) ; do \
		pdfcrop $$file ; \
		mv $${file%.*}-crop.pdf $${file%.*}.pdf; \
	done

pdf2eps:
	for file in $(PDF) ; do \
		pdfcrop $$file ; \
		pdftops -eps $${file%.*}-crop.pdf $${file%.*}.eps ; \
		rm $${file%.*}-crop.pdf ; \
	done

clean-eps:
	rm -f $(EPS)

clean:
	rm -f $(FILE).aux*
	rm -f $(FILE).bbl
	rm -f $(FILE).bcf
	rm -f $(FILE).blg
	rm -f $(FILE)-blx.bib
	rm -f $(FILE).dvi
	rm -f $(FILE).idx
	rm -f $(FILE).ilg
	rm -f $(FILE).ind
	rm -f $(FILE).log
	rm -f $(FILE).lof
	rm -f $(FILE).lot
	rm -f $(FILE).nav
	rm -f $(FILE).out
	rm -f $(FILE).ps
	rm -f $(FILE).run.xml
	rm -f $(FILE).synctex.gz 
	rm -f $(FILE).tex.bak
	rm -f $(FILE).thm
	rm -f $(FILE).toc

clean-all: clean clean-eps
