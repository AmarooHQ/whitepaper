OUTDIR=output
WPFILE=whitepaper.markdown

whitepaper: clean %.md
	touch $(WPFILE)
	for mdfile in `find *-*/ -iname \*.md`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done

%.md:
	echo 'skipping task for .md files'

clean: init
	-rm $(WPFILE)
	-rm -r $(OUTDIR)/*

init:
	@mkdir -p $(OUTDIR)
