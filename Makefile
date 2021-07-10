OUTDIR=output
WPRAW=whitepaper
WPNOEXT=$(OUTDIR)/$(WPRAW)
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html
WPTEX=$(WPNOEXT).tex

# default properties for WP -- see `set-wp-properties` cmd
papersize=a4
geometry=left=3cm,right=3cm,top=3cm,bottom=3cm

# default loction that the WP pdf gets written to. Set OUTPUT_PDF to output somewhere else.
OUTPUT_PDF_DEFAULT=$(WPRAW)-latest.pdf
ifndef OUTPUT_PDF
override OUTPUT_PDF = $(OUTPUT_PDF_DEFAULT)
endif

default: whitepaper

# https://tex.stackexchange.com/questions/45/how-to-speed-up-latex-compilation-with-several-tikz-pictures
TIME     = /usr/bin/time -p
LATEXMK  = latexmk -silent -f -g --pdf
PDFLATEX = latexmk -pdf -shell-escape -interaction=batchmode
PDFCROP  = pdfcrop
RM       = /bin/rm
#StandAloneGraphicsTeXFiles = $(wildcard includes/ut/diags/*_sag.tex)
StandAloneGraphicsTeXFiles = $(shell find ./ -iname \*_sag.tex)
PDFGraphics = $(patsubst %_sag.tex,%_sag.pdf,$(StandAloneGraphicsTeXFiles))
InputTeXFiles = $(wildcard *_input.tex)
PWD = $(pwd)

%_sag.pdf: %_sag.tex
	cd `dirname $<` && \
	$(PDFLATEX) `basename $<`
	$(PDFCROP) $@ $@

whitepaper: $(PDFGraphics) $(InputTeXFiles) build-whitepaper set-wp-properties wp-pandoc mk-latex-pdf wc
whitepaper-skip-pandoc: $(PDFGraphics) $(InputTeXFiles) mk-latex-pdf wc

# atm restrict this to just the UT folder, can generalize again later
# to do that: replace '10-Ultra-Terminum' with '*-*'
# nb: add `clean-wp-md` as a dependency if there are issues building.
build-whitepaper: %.md
	mkdir -p $(OUTDIR)
	echo '' > $(WPFILE)
	for mdfile in `find 10-Ultra-Terminum/ -iname \*.md | sort`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done

# update properties in the whitepaper like papersize and geometry.
# can be set by CLI args like `make whitepaper papersize=a5 geometry=1cm`
set-wp-properties:
	sed -r -i 's/^papersize: (.*)$$/papersize: '$(papersize)'/' $(WPFILE)
	sed -r -i 's/^geometry: (.*)$$/geometry: '$(geometry)'/' $(WPFILE)

	egrep '^papersize: (.*)$$' $(WPFILE)
	egrep '^geometry: (.*)$$' $(WPFILE)

wp-pandoc:
	pandoc -s --number-sections --toc -f markdown -t latex -o $(WPTEX) $(WPFILE)
	sed -i 's/\\%\\%/%/g' $(WPTEX)

wp-just-quotes: clean-wp-md
	echo '' > $(WPFILE)
	cat 10-Ultra-Terminum/00.md >> $(WPFILE)
	cat 10-Ultra-Terminum/10-buterins-trilemma.md >> $(WPFILE)
	cat 10-Ultra-Terminum/40-nutin/25-constructing-ut.md >> $(WPFILE)

dev-build: wp-just-quotes wp-pandoc mk-latex-pdf

wc:
	wc $(WPFILE)

mk-latex-pdf:
	-rm $(WPNOEXT).glsdefs
	TZ='Australia/Sydney' latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(WPTEX)
	makeglossaries -d $(OUTDIR) $(WPRAW)
	TZ='Australia/Sydney' latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(WPTEX)
	cp $(WPNOEXT).pdf $(OUTPUT_PDF)

%.md:
	echo 'skipping task for .md files'

pert:
	dot -Gdpi=300 -Tpng includes/pert/chart.gv -o includes/pert/chart.png

handout:
	dot -Gdpi=300 -Tpng includes/handout/topic-tree.gv -o includes/handout/topic-tree.png
	pandoc --standalone --mathjax -f markdown --pdf-engine=context -V fontsize=11.5pt -o includes/handout/exec-summary.pdf includes/handout/exec-summary.md
	pandoc --standalone --mathjax -f markdown --pdf-engine=context -V fontsize=16pt -o includes/handout/terms.pdf includes/handout/terms.md

clean: init
	$(RM) -fv -- `find . -iname \*.aux -or -iname \*.gls* -or -iname \*.bak -or -iname \*.bbl -or -iname \*.blg -or -iname \*.log -or -iname \*.out -or -iname \*.toc -or -iname \*.tdo -or -iname _region.*`

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

docker-build:
	docker build -f Dockerfile -t whitepaper-build:latest .

# set DOCKER_CMD to run something other than the default `make`. e.g., `make docker DOCKER_CMD=./build.sh`
docker:
	docker run --rm -it -u `id -u ${USER}`:`id -g ${USER}` -v `pwd`:/work whitepaper-build:latest ${DOCKER_CMD}

docker-bash:
	docker run --rm -it -u `id -u ${USER}`:`id -g ${USER}` -v `pwd`:/work whitepaper-build:latest /bin/bash
