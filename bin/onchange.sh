#!/bin/bash
#
# https://gist.github.com/senko/1154509
#
# Watch current directory (recursively) for file changes, and execute
# a command when a file or directory is created, modified or deleted.
#
# Written by: Senko Rasic <senko.rasic@dobarkod.hr>
#
# Requires Linux, bash and inotifywait (from inotify-tools package).
#
# To avoid executing the command multiple times when a sequence of
# events happen, the script waits one second after the change - if
# more changes happen, the timeout is extended by a second again.
#
# Installation:
#     chmod a+rx onchange.sh
#     sudo cp onchange.sh /usr/local/bin
#
# Example use - rsync local changes to the remote server:
#
#    onchange.sh rsync -avt . host:/remote/dir
#
# Released to Public Domain. Use it as you like.
#

#. _bash_colors.sh
. $(dirname $0)/_ci_logs.sh

EVENTS="CREATE,CLOSE_WRITE,DELETE,MODIFY,MOVED_FROM,MOVED_TO"

if [ -z "$1" ]; then
    msg_warn "Usage: $0 [dir] cmd"
    exit -1;
fi

CURRENT_DIR=$PWD
DIRECTORY=$1
CMD_TO_RUN="$2"
if [ -z "$2" ]; then
    DIRECTORY=$PWD
    CMD_TO_RUN="$1"
fi

msg_good "Watching directory $DIRECTORY; will run \`$CMD_TO_RUN\` in $CURRENT_DIR on change"

(
  cd $DIRECTORY
  inotifywait -e "$EVENTS" -m -r --format '%:e %f' . | (
    WAITING="";
    while true; do
        LINE="";
        read -t 0.1 LINE;
        if test -z "$LINE"; then
            if test ! -z "$WAITING"; then
                    msg_info "CHANGE";
                    WAITING="";
            fi;
        else
            WAITING=1;
        fi;
    done) | (
    while true; do
        read TMP;
	while (read -t 0.01 TMP); do true; done
        msg_good "Running in $CURRENT_DIR: $CMD_TO_RUN"
        (cd $CURRENT_DIR && eval "$CMD_TO_RUN")
    done
  )
)
