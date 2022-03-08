#!/usr/bin/env bash

TEX_FILES="$@"

# for texfile in ${TEX_FILES[@]}; do
#   echo "$texfile"
# done

# echo "${TEX_FILES}"
# exit 0

if [ -z "$TEX_FILES" ]; then
    bin/msg_error.sh "Please pass a .tex file. Usage: bin/texLint.sh includes/ut/content/**/*.tex"
    exit 1
fi

bin/msg_good.sh "texLint.sh grepping over files: $(echo $TEX_FILES | wc -w)"

function checkFor {
    REGEX="$1"
    FAILED=
    for texfile in ${TEX_FILES[@]}; do
        grep "$REGEX" "$texfile" > /dev/null
        GREP_STATUS="$?"
        if [ "0" = "$GREP_STATUS" ]; then
        bin/msg_error.sh "Lint failed for regex: \`${REGEX}\` in $texfile"
        FAILED=1
        fi
    done
    if [[ "$FAILED" = "1" ]]; then
      false
    else
        bin/msg_good.sh "Lint okay for regex: \`${REGEX}\`"
    fi
}

# if post@space is there, are you using \defineTerm from a .tex document (not .md)?
#   solution -> use \defineTermTex (drop-in replacement)

checkFor '\$DAA_N\$' && \
checkFor 'TTS_' && \
checkFor 'N_{[Bb]lock' && \
checkFor 'B_[fh]\^' && \
true
