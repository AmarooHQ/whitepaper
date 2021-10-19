#!/usr/bin/env bash

set -x

bash ./bin/msg_good.sh "Starting build -- graphics"

NCPUS=$(lscpu | egrep '^CPU\(s\)' | awk '{ print $2 }')
make -j ${NCPUS:-4} wp-graphics-standalone
# make wp-graphics-standalone

bash ./bin/msg_good.sh "Built graphics"

if [[ -z "$SKIP_BUILD" ]]; then

bash ./bin/msg_good.sh "Building WP for multiple geometries"

make whitepaper papersize=a5 geometry=left=1cm,right=1cm,top=1.5cm,bottom=1.5cm OUTPUT_PDF=./amaroo-wp-a5-latest.pdf
make whitepaper papersize= geometry=left=7.5mm,right=7.5mm,top=1.5cm,bottom=2cm,paperwidth=12cm,paperheight=24cm OUTPUT_PDF=./amaroo-wp-phone-latest.pdf
make

bash ./bin/msg_good.sh "Built WP for multiple geometries"

fi
