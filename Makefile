OUTDIR=output
WPFILENAME=whitepaper
WPNOEXT=$(OUTDIR)/$(WPFILENAME)
WPFILE=$(WPNOEXT).markdown
WPHTML=$(WPNOEXT).html
WPTEX=$(WPNOEXT).tex

# Local texmf directory for custom packages (like ifptex)
export TEXINPUTS := ./texmf/tex/latex//:$(TEXINPUTS)

LP_DIR=includes/ut/lp
LP_TABLES=$(LP_DIR)/tables.tex
LP_TABLES_OUT=$(OUTDIR)/tables.tex

PURS_GEN_DIR=includes/ut/complexity/ut-complexity-gen-purs
PURS_GEN_OUT=includes/ut/complexity/populateWPTables.js

GIT_SHORTHASH=$(shell git rev-parse --short HEAD)

# preprocessor defualt
PP_MODE=draft
PP_LINT_FLAG=

NCPUS = $(shell lscpu | egrep '^CPU.s' | awk '{ print $$2 }')
ifeq ($(NCPUS),)
	NCPUS = 4
endif

# default properties for WP -- see `set-wp-properties` cmd
papersize=a4
geometry=left=3cm,right=3cm,top=3cm,bottom=3cm

# default loction that the WP pdf gets written to. Set OUTPUT_PDF to output somewhere else.
OUTPUT_PDF_DEFAULT=$(WPFILENAME)-latest.pdf
ifndef OUTPUT_PDF
override OUTPUT_PDF = $(OUTPUT_PDF_DEFAULT)
endif

PREPARE_FOR ?=
PREPROC_ARG_PF=
ifdef PREPARE_FOR
override PREPROC_ARG_PF=--prepare-for '$(PREPARE_FOR)'
endif

DARK_MODE ?=
PREPROC_ARG_DM=
ifdef DARK_MODE
override PREPROC_ARG_DM=--dark-mode
endif

SKIP_TEXTLINT = false

default: whitepaper
draft: default

release: entropy
release: PP_MODE=release
release: textlint
release: whitepaper
release: pdflint
release:
	# No matches for \todo{ should be found
	grep -qzv '\\todo{' output/whitepaper.tex || (grep '\\todo{' output/whitepaper.tex | wc -l; bash bin/msg_error.sh 'Detected `\\\\todo{` in output/whitepaper.tex during release build.'; grep '\\todo{' output/whitepaper.tex; exit 1)
	bash bin/msg_good.sh "Release build complete."

release-quick: SKIP_TEXTLINT=true
release-quick: release

cilint-prep: PP_MODE=lint
cilint-prep: whitepaper
	npm i

cilint: cilint-prep lint

wp-no-lint: PP_LINT_FLAG="--no-lint-check"
wp-no-lint: whitepaper

entropy:
	git update-index --assume-unchanged includes/refl_entropy
	python3 bin/preprocessModes.py set-entropy --git $(GIT_SHORTHASH) $(PREPROC_ARG_PF)
	-rm includes/ut/diags/pow_refl_btc_eth_step1_sag.pdf

# https://tex.stackexchange.com/questions/45/how-to-speed-up-latex-compilation-with-several-tikz-pictures
TIME     = /usr/bin/time -p
# LATEXMK  = latexmk -silent -f -g -ps
# PDFLATEX = latexmk -pdf -shell-escape -interaction=nonstopmode
# LATEXRUN = TZ='Australia/Sydney' python3 ./latexrun --color always --latex-args "-shell-escape -interaction=batchmode"
LATEXRUN = python3 ./latexrun --color always --latex-args "-shell-escape -interaction=batchmode"
PDFLATEX = latexmk -pdf -shell-escape -interaction=batchmode
# PDFLATEX = latexmk -pdf -shell-escape -interaction=batchmode
# PDFLATEX = python3 $(PWD)/latexrun --color always --latex-args "-shell-escape -interaction=batchmode"
PSLATEX = latexmk -ps -shell-escape -interaction=batchmode
PDFCROP  = pdfcrop
RM       = /bin/rm
#StandAloneGraphicsTeXFiles = $(wildcard includes/ut/diags/*_sag.tex)
StandAloneGraphicsTeXFiles = $(shell find ./ -iname \*_sag.tex)
PDFGraphics = $(patsubst %_sag.tex,%_sag.pdf,$(StandAloneGraphicsTeXFiles))
PSGraphics = $(patsubst %_sag.tex,%_sag.ps,$(StandAloneGraphicsTeXFiles))
DVIGraphics = $(patsubst %_sag.tex,%_sag.dvi,$(StandAloneGraphicsTeXFiles))
PNGGraphics = $(patsubst %_sag.pdf,%_sag.png,$(PDFGraphics))
InputTeXFiles = $(wildcard *_input.tex)

WATCH_CMD = make

watch:
	bash bin/msg_good.sh "Watching. Command to re-run: $(WATCH_CMD)"
	bin/onchange.sh ./10-Ultra-Terminum ./includes/ut/content ./includes/ut/algorithms '$(WATCH_CMD)'

evince-draft-bg:
	evince output/whitepaper-draft-reloadable.pdf 2>/dev/null &

watch-evince: evince-draft-bg watch

watch-release: WATCH_CMD=make release-quick
watch-release: watch

wp-graphics-standalone: $(PDFGraphics)
wp-graphics-ps: $(PSGraphics)
wp-graphics-png: $(PNGGraphics)

%_sag.pdf: %_sag.tex
	#$(LATEXRUN) $< -O `dirname $<`
	bash bin/msg_good.sh "[$<]: PP_MODE=$(PP_MODE)"
	cd `dirname $<` && \
	$(PDFLATEX) `basename $<`
	$(PDFCROP) $@ $@

%_sag.ps: %_sag.tex
	bash bin/msg_good.sh "[$<]: PP_MODE=$(PP_MODE)"
	cd `dirname $<` && \
	$(PSLATEX) `basename $<`
# $(PDFCROP) $@ $@

%_sag.png: %_sag.pdf
	cd `dirname $<` && \
	convert -density 400 `basename $<` `basename $@`

# all the prerequisite things to generate whitepaper.tex
whitepaper-prereqs: $(PDFGraphics) $(InputTeXFiles) build-whitepaper set-wp-properties wp-pandoc
# full build of whitepaper pdf
whitepaper: whitepaper-prereqs mk-latex-pdf wc finished-msg
# rebuild tex/graphics but skip md and pandoc step (it assumes whitepaper.tex is already built and doesn't need updating)
whitepaper-skip-pandoc: $(PDFGraphics) $(InputTeXFiles) mk-latex-pdf wc

# parallel build of all graphics
par-gfx:
	$(MAKE) -j $(NCPUS) $(PDFGraphics)

# atm restrict this to just the UT folder, can generalize again later
# to do that: replace '10-Ultra-Terminum' with '*-*'
# nb: add `clean-wp-md` as a dependency if there are issues building.
build-whitepaper: %.md
	bash bin/msg_good.sh "[build-whitepaper]: PP_MODE=$(PP_MODE)"
	mkdir -p $(OUTDIR)
	echo '' > $(WPFILE)
	for mdfile in `find 10-Ultra-Terminum/ -iname \*.md | sort`; do \
	  echo "Processing: $$mdfile" && \
	  cat $$mdfile >> $(WPFILE) && \
	  echo -n "\n\n" >> $(WPFILE) ; \
	done
	# replace tables placeholder with actual tables
	node $(PURS_GEN_OUT) --populate-wp-md
	# this fixes texcount (since import-paths don't need to be searched).
	sed -r -i 's/input\{([0-9]+-[a-z]+)/input\{includes\/ut\/content\/\1/' $(WPFILE)
# if you need to build the above: cd includes/ut/complexity/ut-complexity-gen-purs && npm i && npm run bundle-for-wp


# update properties in the whitepaper like papersize and geometry.
# can be set by CLI args like `make whitepaper papersize=a5 geometry=1cm`
set-wp-properties:
	sed -r -i 's/^papersize: (.*)$$/papersize: '$(papersize)'/' $(WPFILE)
	sed -r -i 's/^geometry: (.*)$$/geometry: '$(geometry)'/' $(WPFILE)

	egrep '^papersize: (.*)$$' $(WPFILE)
	egrep '^geometry: (.*)$$' $(WPFILE)

wp-pandoc:
	bash bin/msg_good.sh "[wp-pandoc]: PP_MODE=$(PP_MODE)"
	pandoc -s --number-sections --toc -f markdown-latex_macros -t latex -o $(WPTEX) $(WPFILE)
	sed -i 's/\\%\\%/%/g' $(WPTEX)
#	sed -i 's/timum Imus/timum \\=Imus/g' $(WPTEX)
# note: \=I doesn't work right via pandoc, so it needs to be replaced. The command works, but capital I-bar isn't a common character so causing issues

pandoc-stdin:
	pandoc -s --number-sections -f markdown-latex_macros -t latex

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
	bash bin/msg_good.sh "Wordcount via wc: $$(wc -w output/whitepaper.markdown)"
	bash bin/msg_good.sh "Wordcount via texcount: $$(texcount output/whitepaper.tex -merge -sum -0)"

# preprocess tex for draft/release/lint
preprocess-build:
	python3 bin/preprocessModes.py process-tex $(WPTEX) --mode $(PP_MODE) --allow-in-place $(PP_LINT_FLAG) $(PREPROC_ARG_PF) $(PREPROC_ARG_DM)
	bash bin/msg_good.sh "Finished preprocessing of $(WPTEX) in mode $(PP_MODE)"

# latexrun first for error msgs, then run run latexmk once for gitinfo2/glossary, then use latexrun
# note: the *-reloadable.pdf files are copies of interim outputs (and then the final output) so that you can f5 them in a browser without getting partially written documents.
mk-latex-pdf: preprocess-build mk-latex-pdf-inner
mk-latex-pdf-inner:
	bash bin/msg_good.sh "[mk-latex-pdf]: PP_MODE=$(PP_MODE)"
	bash bin/msg_good.sh "Run ./latexrun to get good error msgs"
	$(LATEXRUN) $(WPTEX) -O $(OUTDIR) || true
	cp $(WPNOEXT).pdf $(WPNOEXT)-$(PP_MODE)-reloadable.pdf

	bash bin/msg_good.sh "Running latexmk to update gitinfo, build glossaries; PP_MODE=$(PP_MODE)"
	latexmk -pdf -interaction=batchmode --enable-write18 -output-directory=$(OUTDIR) $(WPTEX) > _latexmk.log

	bash bin/msg_good.sh "Update glossaries (run \`make glossary-fix-1 && make && make\` to fix glossaries if something breaks). PP_MODE=$(PP_MODE)"
	#-rm $(WPNOEXT).gl*
	(cd $(OUTDIR) && makeglossaries $(WPFILENAME))

	bash bin/msg_good.sh "./latexrun to build paper proper. PP_MODE=$(PP_MODE)"
	$(LATEXRUN) $(WPTEX) -O $(OUTDIR)
	cp $(WPNOEXT).pdf $(WPNOEXT)-$(PP_MODE)-reloadable.pdf

	cp $(WPNOEXT).pdf $(OUTPUT_PDF)
	cp $(WPNOEXT).pdf $(WPNOEXT)-$(PP_MODE).pdf
	cp $(WPNOEXT).pdf $(WPFILENAME)-$(PP_MODE).pdf
	bash bin/msg_good.sh "Copied build to\n  - $(OUTPUT_PDF)\n  - $(WPNOEXT)-$(PP_MODE).pdf\n  - $(WPFILENAME)-$(PP_MODE).pdf"
	python3 bin/preprocessModes.py copy-prepared-for $(WPNOEXT).pdf $(PREPROC_ARG_PF) --git $(GIT_SHORTHASH)

glossary-fix-1:
	rm -v $(WPNOEXT).gl*

finished-msg:
	bash bin/msg_good.sh 'Finished build for mode=$(PP_MODE)'

lint: textlint texlint pdflint

textlint:
	bash bin/msg_good.sh "[textlint] PP_MODE=$(PP_MODE)"
	if [ "$(SKIP_TEXTLINT)" = "false" ]; then npm run lint; else bash bin/msg_warn.sh 'skipping textlint'; fi

texlint:
	bash bin/msg_good.sh "[texlint]: PP_MODE=$(PP_MODE)"
	bash bin/texLint.sh \
		`find ./includes/ut/content -iname \*.tex` \
		`find ./10-Ultra-Terminum/ -iname \*.md` \
		`find ./includes/ut -iname \*.tex`

pdflint:
	bash bin/msg_good.sh "[pdflint]: PP_MODE=$(PP_MODE)"
	bash bin/pdfLint.sh output/whitepaper.pdf

%.md:
	echo 'skipping task for .md files'

mk-lp-tables:
	cp $(LP_TABLES) $(LP_TABLES_OUT)
	export REPLACE_TABLES_IN=$(LP_TABLES_OUT) && \
	node $(PURS_GEN_OUT) --populate-wp-md --lp-tables
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

purs-ci-init-hash:
	sha256sum $(PURS_GEN_OUT) > ci-check-purs-1.log
	cp $(PURS_GEN_OUT) $(PURS_GEN_OUT).old

purs-ci-post-hash:
	sha256sum $(PURS_GEN_OUT) > ci-check-purs-2.log

purs-ci-check: purs-ci-init-hash purs-build purs-ci-post-hash
	bash bin/checkFilesIdentical.sh ci-check-purs-1.log ci-check-purs-2.log \
	  || (diff -c $(PURS_GEN_OUT) $(PURS_GEN_OUT).old && false)

pert:
	mkdir -p output/pert
	dot -Gdpi=300 -Tpng includes/pert/chart.gv -o output/pert/chart.png
	dot -Gdpi=300 -Tpng includes/pert/chart2.gv -o output/pert/chart2.png

handout:
	dot -Gdpi=300 -Tpng includes/handout/topic-tree.gv -o includes/handout/topic-tree.png
	pandoc --standalone --mathjax -f markdown-latex_macros --pdf-engine=context -V fontsize=11.5pt -o includes/handout/exec-summary.pdf includes/handout/exec-summary.md
	pandoc --standalone --mathjax -f markdown-latex_macros --pdf-engine=context -V fontsize=16pt -o includes/handout/terms.pdf includes/handout/terms.md

# latex files anywhere
clean: init
	$(RM) -fv -- `find . -iname \*.aux -or -iname \*.gls* -or -iname \*.bak -or -iname \*.bbl -or -iname \*.blg -or -iname \*.log -or -iname \*.out -or -iname \*.toc -or -iname \*.tdo -or -iname _region.*`

# standalone graphics pdfs
deponly-clean:
	$(RM) -fv -- `find ./ -iname \*_sag.pdf`
	$(RM) -fv -- `find ./ -iname \*_sag.ps`

depclean: clean deponly-clean

depclean-por:
	$(RM) -fv -- `find ./ -iname pow_refl\*_sag.pdf`

depclean-tiling:
	$(RM) -fv -- `find ./ -iname tiling\*_sag.pdf`

depclean-simplex:
	$(RM) -fv -- `find ./ -iname simplex\*_sag.pdf`

depclean-%:
	$(RM) -fv -- `find ./ -iname $*\*_sag.pdf`

#re-make SAG files with a given name-prefix
sag-%:
	$(MAKE) depclean-$*
	if [ -z "`find ./ -iname $*\*_sag.tex`" ]; then echo 'no matching files'; else $(MAKE) -j $(NCPUS) `find ./ -iname $*\*_sag.tex | sed 's/\.tex$$/.pdf/'`; fi

# run make for output files based on input files:
# $(MAKE) `find ./ -iname $*\*_sag.tex | sed 's/\.tex$$/.pdf/'`

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
	docker run --rm -t -u `id -u ${USER}`:`id -g ${USER}` -e 'TERM=xterm-color' -v `pwd`:/work whitepaper-build:latest ${DOCKER_CMD}

docker-bash:
	docker run --rm -it -u `id -u ${USER}`:`id -g ${USER}` -v `pwd`:/work whitepaper-build:latest /bin/bash

# run a little python3 server from output dir
serve:
	cd $(OUTDIR) && python3 -m http.server 3131

view:
	wslview output/whitepaper.pdf

viewweb:
	wslview http://localhost:3131/whitepaper.pdf

cloc:
	cloc --exclude-dir=node_modules,bin,target,.spago,output --exclude_ext=svg,pdf,js,json,toml ./10-Ultra-Terminum ./bin ./experiments ./includes

GIT_WC_DEPTH ?= 0
GIT_WC_REMOVED = $(shell git diff HEAD~$(GIT_WC_DEPTH) --word-diff=porcelain | grep -e '^-[^-]' | wc -w)
GIT_WC_ADDED = $(shell git diff HEAD~$(GIT_WC_DEPTH) --word-diff=porcelain | grep -e '^+[^+]' | wc -w)

count-words-git-help:
	@echo "!! note the parameter: GIT_WC_DEPTH env var"

count-words-diff: count-words-git-help
	@echo "Words added: $(GIT_WC_ADDED)"
	@echo "Words removed: $(GIT_WC_REMOVED)"
	@echo "Words diff: `echo $(GIT_WC_ADDED)-$(GIT_WC_REMOVED) | bc`"

git-count-words: count-words-diff

git-setup-hooks:
	for _f in `ls ./bin/hooks`; do ln -s "../../bin/hooks/$$_f" ".git/hooks/$$_f"; done

# shortcut for simulation RandHR PMFs -- only here b/c it's mentioned in the WP.
# for simulation makefile proper see /experiments/por-sim-rs/Makefile
print-randhr-pmfs:
	cd experiments/por-sim-rs && $(MAKE) print-randhr-pmfs || echo "\nHint: is /experiments/por-sim-rs set up? (cargo, rust, etc)"
