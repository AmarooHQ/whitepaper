OUTDIR=output
WPRAW=whitepaper
WPNOEXT=$(OUTDIR)/$(WPRAW)
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html
WPTEX=$(WPNOEXT).tex


LP_DIR=includes/ut/lp
LP_TABLES=$(LP_DIR)/tables.tex
LP_TABLES_OUT=$(OUTDIR)/tables.tex

PURS_GEN_DIR=includes/ut/complexity/ut-complexity-gen-purs

# preprocessor defualt
PP_MODE=draft
PP_LINT_FLAG=

# default properties for WP -- see `set-wp-properties` cmd
papersize=a4
geometry=left=3cm,right=3cm,top=3cm,bottom=3cm

# default loction that the WP pdf gets written to. Set OUTPUT_PDF to output somewhere else.
OUTPUT_PDF_DEFAULT=$(WPRAW)-latest.pdf
ifndef OUTPUT_PDF
override OUTPUT_PDF = $(OUTPUT_PDF_DEFAULT)
endif


default: whitepaper

release: PP_MODE=release
release: textlint
release: whitepaper
release:
	# No matches for \todo{ should be found
	grep -qzv '\\todo{' output/whitepaper.tex || (grep '\\todo{' output/whitepaper.tex | wc -l; bash bin/msg_error.sh 'Detected `\\\\todo{` in output/whitepaper.tex during release build.'; exit 1)

cilint: PP_MODE=lint
cilint: whitepaper

wp-no-lint: PP_LINT_FLAG="--no-lint-check"
wp-no-lint: whitepaper

# https://tex.stackexchange.com/questions/45/how-to-speed-up-latex-compilation-with-several-tikz-pictures
TIME     = /usr/bin/time -p
LATEXMK  = latexmk -silent -f -g --pdf
PDFLATEX = latexmk -pdf -shell-escape -interaction=batchmode
PDFCROP  = pdfcrop
RM       = /bin/rm
#StandAloneGraphicsTeXFiles = $(wildcard includes/ut/diags/*_sag.tex)
StandAloneGraphicsTeXFiles = $(shell find ./ -iname \*_sag.tex)
PDFGraphics = $(patsubst %_sag.tex,%_sag.pdf,$(StandAloneGraphicsTeXFiles))
DVIGraphics = $(patsubst %_sag.tex,%_sag.dvi,$(StandAloneGraphicsTeXFiles))
PNGGraphics = $(patsubst %_sag.pdf,%_sag.png,$(PDFGraphics))
InputTeXFiles = $(wildcard *_input.tex)
PWD = $(pwd)

watch:
	bin/onchange.sh 10-Ultra-Terminum "make"

wp-graphics-standalone: $(PDFGraphics)
wp-graphics-png: $(PNGGraphics)

%_sag.pdf: %_sag.tex
	cd `dirname $<` && \
	$(PDFLATEX) `basename $<`
	$(PDFCROP) $@ $@

%_sag.png: %_sag.pdf
	cd `dirname $<` && \
	convert -density 400 `basename $<` `basename $@`

whitepaper: $(PDFGraphics) $(InputTeXFiles) build-whitepaper set-wp-properties wp-pandoc mk-latex-pdf wc finished-msg
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
	# replace tables placeholder with actual tables
	node ./includes/ut/complexity/populateWPTables.js --populate-wp-md
# if you need to build the above: cd includes/ut/complexity/ut-complexity-gen-purs && npm i && npm run bundle-for-wp


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

# added to make testing quote boxes easier I think
wp-just-quotes: clean-wp-md
	echo '' > $(WPFILE)
	cat 10-Ultra-Terminum/00.md >> $(WPFILE)
	cat 10-Ultra-Terminum/10-buterins-trilemma.md >> $(WPFILE)
	cat 10-Ultra-Terminum/40-nutin/25-constructing-ut.md >> $(WPFILE)

dev-build: wp-just-quotes wp-pandoc mk-latex-pdf

wc:
	(find . -iname '*.md' -or -iname '*.tex' | grep -v node_mod | grep -v spago | grep -v output | grep -v diags | xargs wc && \
	  wc $(WPFILE)) > wc-$(PP_MODE).log
	wc $(WPFILE)

# preprocess tex for draft/release/lint
preprocess-build:
	python3 bin/preprocessModes.py process-tex $(WPTEX) --mode $(PP_MODE) --allow-in-place $(PP_LINT_FLAG)
	bash bin/msg_good.sh "Finished preprocessing of $(WPTEX) in mode $(PP_MODE)"

mk-latex-pdf: preprocess-build
	TZ='Australia/Sydney' latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(WPTEX)
	#-rm $(WPNOEXT).glsdefs
	(cd $(OUTDIR) && makeglossaries $(WPRAW))
	TZ='Australia/Sydney' latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(WPTEX)
	cp $(WPNOEXT).pdf $(OUTPUT_PDF)
	cp $(WPNOEXT).pdf $(WPNOEXT)-$(PP_MODE).pdf
	cp $(WPNOEXT).pdf $(WPRAW)-$(PP_MODE).pdf
	bash bin/msg_good.sh "Copied build to\n  - $(OUTPUT_PDF)\n  - $(WPNOEXT)-$(PP_MODE).pdf\n  - $(WPRAW)-$(PP_MODE).pdf"

finished-msg:
	bash bin/msg_good.sh 'Finished build for mode=$(PP_MODE)'

textlint:
	npm run lint

%.md:
	echo 'skipping task for .md files'

mk-lp-tables:
	cp $(LP_TABLES) $(LP_TABLES_OUT)
	export REPLACE_TABLES_IN=$(LP_TABLES_OUT) && \
	node ./includes/ut/complexity/populateWPTables.js --populate-wp-md --lp-tables
	latexmk -pdf --enable-write18 -output-directory=$(OUTDIR) $(LP_TABLES_OUT)
	cp $(OUTDIR)/tables.pdf ./tables.pdf

purs-setup:
	cd $(PURS_GEN_DIR) && \
	npm i

purs-build:
	cd $(PURS_GEN_DIR) && \
	npm run bundle-for-wp

# for development, I suggest cd-ing to PURS_GEN_DIR and running `spago test -w` or similar to auto-rebuild and test
purs-test:
	cd $(PURS_GEN_DIR) && \
	npm run test

pert:
	mkdir -p output/pert
	dot -Gdpi=300 -Tpng includes/pert/chart.gv -o output/pert/chart.png
	dot -Gdpi=300 -Tpng includes/pert/chart2.gv -o output/pert/chart2.png

handout:
	dot -Gdpi=300 -Tpng includes/handout/topic-tree.gv -o includes/handout/topic-tree.png
	pandoc --standalone --mathjax -f markdown --pdf-engine=context -V fontsize=11.5pt -o includes/handout/exec-summary.pdf includes/handout/exec-summary.md
	pandoc --standalone --mathjax -f markdown --pdf-engine=context -V fontsize=16pt -o includes/handout/terms.pdf includes/handout/terms.md

# latex files anywhere
clean: init
	$(RM) -fv -- `find . -iname \*.aux -or -iname \*.gls* -or -iname \*.bak -or -iname \*.bbl -or -iname \*.blg -or -iname \*.log -or -iname \*.out -or -iname \*.toc -or -iname \*.tdo -or -iname _region.*`

# standalone graphics pdfs
deponly-clean:
	$(RM) -fv -- `find ./ -iname \*_sag.pdf`

depclean: clean deponly-clean

# everything in output + the rest
distclean: depclean
	-rm -r $(OUTDIR)/*

# usually good enough to fix failing builds
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
	docker run --rm -u `id -u ${USER}`:`id -g ${USER}` -e 'TERM=xterm-color' -v `pwd`:/work whitepaper-build:latest ${DOCKER_CMD}

docker-bash:
	docker run --rm -it -u `id -u ${USER}`:`id -g ${USER}` -v `pwd`:/work whitepaper-build:latest /bin/bash
