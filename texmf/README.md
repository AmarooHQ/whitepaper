# Local TeX Packages

This directory contains LaTeX packages that are stored locally in the repository for portability.

## Usage

To use these packages, set the `TEXINPUTS` environment variable before running LaTeX commands:

```bash
export TEXINPUTS=./texmf/tex/latex//:
```

Or use it inline:
```bash
TEXINPUTS=./texmf/tex/latex//: pdflatex mydocument.tex
```

## Packages Included

- **ifptex** - Provides conditional compilation for pTeX variants
  - Source: https://ctan.org/pkg/ifptex
  - License: See `ifptex/LICENSE`
