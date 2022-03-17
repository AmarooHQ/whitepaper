#!/usr/bin/env bash

PDF_FILE="$1"

if [ -z "$PDF_FILE" ]; then
    bin/msg_error.sh "Please pass a PDF file. Usage: bin/lintPdf.sh output/whitepaper.pdf"
    exit 1
fi

function checkFor {
    REGEX="$1"
    pdfgrep "$REGEX" "$PDF_FILE" > /dev/null
    PDFGREP_STATUS="$?"
    if [ "0" = "$PDFGREP_STATUS" ]; then
      bin/msg_error.sh "Lint failed for regex: \`${REGEX}\`"
      false
    else
      bin/msg_good.sh "Lint okay for regex: \`${REGEX}\`"
      true
    fi
}

# if post@space is there, are you using \defineTerm from a .tex document (not .md)?
#   solution -> use \defineTermTex (drop-in replacement)

checkFor 'post@space' && \
checkFor '\?\?' && \
checkFor 'todo'
