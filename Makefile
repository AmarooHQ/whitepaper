OUTDIR=output
WPNOEXT=$(OUTDIR)/whitepaper
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html

whitepaper: build-whitepaper mk-latex-pdf wc

build-whitepaper: clean %.md
	touch $(WPFILE)
	for mdfile in `find *-*/ -iname \*.md`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done
	pandoc -s -f markdown -t html -o $(WPHTML) $(WPFILE)
	pandoc -s -f markdown -t latex -o $(WPNOEXT).tex $(WPFILE)

wc:
	wc $(WPFILE)

mk-latex-pdf:
	pdflatex $(WPNOEXT).tex

%.md:
	echo 'skipping task for .md files'

clean: init
	-rm -r $(OUTDIR)/*

init:
	@mkdir -p $(OUTDIR)
