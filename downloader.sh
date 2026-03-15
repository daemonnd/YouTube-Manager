#!/bin/bash

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script downloader.sh interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in downloader.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function main {
    # cd to target dir
    cd "/home/$USER/Videos/ytd"
    yt-dlp \
        -f "bestvideo+bestaudio/best" \
        --merge-output-format mkv \
        --fragment-retries 10 \
        --retries 10 \
        "$1"
}

# call main with all args, as given
main "$@"
