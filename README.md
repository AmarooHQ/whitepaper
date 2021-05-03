# amaroo + ut whitepaper

## dependencies

- the Makefile presumes you're running this in a linux environment
- you'll need: make, pandoc v2.5, latexmk
- ubuntu pkgs: `texlive-science`, `texlive-extra-utils`, `gnuplot`

if you run into compile errors, you could try installing `texlive-full` -- not a great workaround but does solve some issues (b/c apparently we have a missing dep) -- or just use the docker build via `make docker-build && make docker`

### "supported" build env

- Ubuntu 20.04 (WSL or whatever)

## build it

- `make`: markdown (.md) files in folders with a dash in their name will be "compiled" into `whitepaper.markdown`. the order of files will be via their natural sorting (run `find *-* -iname \*.md` to list them; that's the cmd used in the makefile).
  - todo: some better / fancier compilation stuff
  - todo: latex builds?
  - todo: graphviz compilation for diagrams?
    - graphviz has gross layouts, sagemath with spring layouts are nice tho
  - todo: add your ideas here! or as an issue. or whatever.

The directory names are capitalized atm b/c I think it might be good to keep the option open of using the directory names as section headings, but mb that could be difficult if we want punctuation and stuff. IDK.

I use this to compile and view quickly: `make && code ./output/whitepaper.pdf`

## notes about latex graph stuff

- https://www.baeldung.com/cs/latex-drawing-graphs
- using sagemath for simplex graphs, but the above could be good for blockchain graphs or other things

## resource: scaffold for doing a thesis in markdown + pandoc

mb useful

<https://github.com/chiakaivalya/thesis-markdown-pandoc>

## linting

NB: These aren't enforced atm

* install deps with `npm i`
* lint with `npm run lint`
* linter rules in `.textlintrc`

## latex workshop (vscode addon) and write18 / escape-shell

Add this to vscode settings (JSON), or modify accordingly.

```
    "latex-workshop.latex.tools": [{
        "name": "latexmk",
        "command": "latexmk",
        "args": [
            "-shell-escape",
            "-synctex=1",
            "-interaction=nonstopmode",
            "-file-line-error",
            "-pdf",
            "-outdir=%OUTDIR%",
            "%DOC%"
        ]
    }]
```

## experimental docker build environment

* TL;DR -- `make docker-build && make docker`
  * `docker build -t whitepaper-build:latest .` in project root directory, once to initialize docker container (or `make docker-build`)
  * `make docker` to build once
  * `docker run --rm -it -u $(id -u ${USER}):$(id -g ${USER}) -v $(pwd):/work whitepaper-build:latest /bin/bash` in project root directory (or `make docker-bash`)
  * in resulting shell, run `make` to build whitepaper as normal.
