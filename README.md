# amaroo + ut whitepaper

## dependencies

- the Makefile presumes you're running this in a linux environment
- you'll need: make, pandoc, latexmk, pdflatex (usually provided via a latex distribution), `texlive-science` package on ubuntu (for `siunitx`)

## build it

- `make`: markdown (.md) files in folders with a dash in their name will be "compiled" into `whitepaper.markdown`. the order of files will be via their natural sorting (run `find *-* -iname \*.md` to list them; that's the cmd used in the makefile).
  - todo: some better / fancier compilation stuff
  - todo: latex builds?
  - todo: graphviz compilation for diagrams?
  - todo: add your ideas here! or as an issue. or whatever.

The directory names are capitalized atm b/c I think it might be good to keep the option open of using the directory names as section headings, but mb that could be difficult if we want punctuation and stuff. IDK.

I use this to compile and view quickly: `make && code ./output/whitepaper.pdf`

## sagemath to generate some figures

you need (ubuntu pkgs):

- `sagemath`
- `dot2tex`
