OUTDIR=output
WPNOEXT=$(OUTDIR)/whitepaper
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html
WPTEX=$(WPNOEXT).tex

whitepaper: build-whitepaper mk-latex-pdf wc

# atm restrict this to just the UT folder, can generalize again later
# to do that: replace '10-Ultra-Terminum' with '*-*'
build-whitepaper: clean-wp-md %.md
	touch $(WPFILE)
	for mdfile in `find 10-Ultra-Terminum/ -iname \*.md`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done
	pandoc -s --toc -f markdown -t latex -o $(WPTEX) $(WPFILE)
	sed -i 's/\\%\\%/%/g' $(WPTEX)

wc:
	wc $(WPFILE)

mk-latex-pdf:
	# pdflatex -output-directory=$(OUTDIR) $(WPNOEXT).tex
	latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(WPTEX)

%.md:
	echo 'skipping task for .md files'

pert:
	dot -Gdpi=300 -Tpng includes/pert/chart.gv -o includes/pert/chart.png

clean: init
	-rm -r $(OUTDIR)/*

clean-wp-md:
	-rm $(WPFILE)

init:
	@mkdir -p $(OUTDIR)
