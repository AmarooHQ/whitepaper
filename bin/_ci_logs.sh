#!/usr/bin/env bash

. $(dirname $0)/_bash_colors.sh

function msg_good {
    clr_bold clr_green "\n> $1\n"
}

function msg_info {
    clr_bold clr_cyan "\n> $1\n"
}

function msg_warn {
    clr_bold clr_yellow "\n> $1\n"
}

function msg_error {
    clr_bold clr_red "\n> $1\n"
}
