OUTDIR=output
WPNOEXT=$(OUTDIR)/whitepaper
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html

whitepaper: build-whitepaper mk-latex-pdf wc

# atm restrict this to just the UT folder, can generalize again later
# to do that: replace '10-Ultra-Terminum' with '*-*'
build-whitepaper: clean %.md
	touch $(WPFILE)
	for mdfile in `find 10-Ultra-Terminum/ -iname \*.md`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done
	pandoc -s --toc -f markdown -t latex -o $(WPNOEXT).tex $(WPFILE)

wc:
	wc $(WPFILE)

mk-latex-pdf:
	# pdflatex -output-directory=$(OUTDIR) $(WPNOEXT).tex
	latexmk -pdf -output-directory=$(OUTDIR) $(WPNOEXT).tex

%.md:
	echo 'skipping task for .md files'

pert:
	dot -Gdpi=300 -Tpng includes/pert/chart.gv -o includes/pert/chart.png

clean: init
	-rm -r $(OUTDIR)/*

init:
	@mkdir -p $(OUTDIR)
