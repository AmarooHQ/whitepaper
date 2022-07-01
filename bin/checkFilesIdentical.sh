#!/usr/bin/env bash

# Exit 0 if files are the same
# Exit 1 if not

. $(dirname $0)/_ci_logs.sh

file_one=$1
file_two=$2

if [[ -z "$file_one" || -z "$file_two" ]]; then
    msg_bad "error: please provide two filenames to $0"
    msg_warn "example: $0 ci-check-purs-1.log ci-check-purs-2.log"
    exit 99
fi

if [[ "$(diff $file_one $file_two | wc -c)" = "0" ]]; then
    msg_good "Files identical: $file_one and $file_two"
    exit 0
fi

msg_bad "Error: files are not identical. Files: $file_one and $file_two"
exit 1
