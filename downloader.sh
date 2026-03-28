#!/bin/bash
# File for downloading a video
# It gets the url and target dir and downloads the video to the target dir using yt-dlp

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

function rename_dest_path {
    # if the user has the file renamer, rename it
    if [[ -x /usr/local/bin/rename_one_file.sh ]]; then
        /usr/local/bin/rename_one_file.sh 2 "$1"
    fi
}

function main {
    # cd to target dir
    cd "$2"
    yt-dlp \
        -f "bestvideo+bestaudio/best" \
        --merge-output-format mkv \
        --fragment-retries 10 \
        --retries 10 \
        --cookies-from-browser firefox \
        --exec 'if [[ ! -x /usr/local/bin/rename_one_file.sh ]]; then
                    exit 0
                fi
                echo $0
                /usr/local/bin/rename_one_file.sh 2 ' \
        "$1"
}

# call main with all args, as given
main "$@"
