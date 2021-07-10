#!/usr/bin/env bash

set -x

NCPUS=$(lscpu | egrep '^CPU\(s\)' | awk '{ print $2 }')
make -j ${NCPUS:-4} wp-graphics-standalone
make -j ${NCPUS:-4}
make -j ${NCPUS:-4} whitepaper papersize=a5 geometry=left=1cm,right=1cm,top=1.5cm,bottom=1.5cm OUTPUT_PDF=./whitepaper-a5-latest.pdf
make -j ${NCPUS:-4} whitepaper papersize= geometry=left=7.5mm,right=7.5mm,top=1.5cm,bottom=2cm,paperwidth=12cm,paperheight=24cm OUTPUT_PDF=./wp-phone-latest.pdf
