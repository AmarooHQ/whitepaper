#!/usr/bin/env bash

make
make whitepaper papersize=a5 geometry=left=1cm,right=1cm,top=1.5cm,bottom=1.5cm OUTPUT_PDF=./whitepaper-a5-latest.pdf
make whitepaper papersize= geometry=left=7.5mm,right=7.5mm,top=1.5cm,bottom=2cm,paperwidth=12cm,paperheight=24cm OUTPUT_PDF=./wp-phone-latest.pdf
