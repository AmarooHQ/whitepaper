OUTDIR=output
WPNOEXT=$(OUTDIR)/whitepaper
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html
WPTEX=$(WPNOEXT).tex

default: whitepaper

# https://tex.stackexchange.com/questions/45/how-to-speed-up-latex-compilation-with-several-tikz-pictures
TIME     = /usr/bin/time -p
LATEXMK  = latexmk -silent -f -g --pdf
PDFLATEX = pdflatex -interaction=batchmode
PDFCROP  = pdfcrop
RM       = /bin/rm
#StandAloneGraphicsTeXFiles = $(wildcard includes/ut/diags/*_sag.tex)
StandAloneGraphicsTeXFiles = $(shell find ./ -iname \*_sag.tex)
PDFGraphics = $(patsubst %_sag.tex,%_sag.pdf,$(StandAloneGraphicsTeXFiles))
InputTeXFiles = $(wildcard *_input.tex)

%_sag.pdf: %_sag.tex
	$(PDFLATEX) -output-directory=`dirname $<` $<
	$(PDFCROP) $@ $@

whitepaper: $(PDFGraphics) $(InputTeXFiles) build-whitepaper wp-pandoc mk-latex-pdf wc

# atm restrict this to just the UT folder, can generalize again later
# to do that: replace '10-Ultra-Terminum' with '*-*'
build-whitepaper: clean-wp-md %.md
	touch $(WPFILE)
	for mdfile in `find 10-Ultra-Terminum/ -iname \*.md | sort`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done

wp-pandoc:
	pandoc -s --number-sections --toc -f markdown -t latex -o $(WPTEX) $(WPFILE)
	sed -i 's/\\%\\%/%/g' $(WPTEX)

wp-just-quotes: clean-wp-md
	touch $(WPFILE)
	cat 10-Ultra-Terminum/00.md >> $(WPFILE)
	cat 10-Ultra-Terminum/10-buterins-trilemma.md >> $(WPFILE)
	cat 10-Ultra-Terminum/40-nutin/25-constructing-ut.md >> $(WPFILE)

dev-build: wp-just-quotes wp-pandoc mk-latex-pdf

wc:
	wc $(WPFILE)

mk-latex-pdf:
	# pdflatex -output-directory=$(OUTDIR) $(WPNOEXT).tex
	latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(WPTEX)
	cp $(WPNOEXT).pdf ./whitepaper-latest.pdf

%.md:
	echo 'skipping task for .md files'

pert:
	dot -Gdpi=300 -Tpng includes/pert/chart.gv -o includes/pert/chart.png

handout:
	dot -Gdpi=300 -Tpng includes/handout/topic-tree.gv -o includes/handout/topic-tree.png
	pandoc --standalone --mathjax -f markdown --pdf-engine=context -V fontsize=11.5pt -o includes/handout/exec-summary.pdf includes/handout/exec-summary.md

clean: init
	$(RM) -fv -- `find . -iname \*.aux -or -iname \*.bak -or -iname \*.bbl -or -iname \*.blg -or -iname \*.log -or -iname \*.out -or -iname \*.toc -or -iname \*.tdo -or -iname _region.*`

deponly-clean:
	$(RM) -fv -- `find ./ -iname \*_sag.pdf`

depclean: clean deponly-clean

distclean: depclean
	-rm -r $(OUTDIR)/*

clean-wp-md:
	-rm .git/gitHeadInfo.gin
	-rm $(WPFILE)
	-rm $(WPNOEXT).pdf

init:
	@mkdir -p $(OUTDIR)
