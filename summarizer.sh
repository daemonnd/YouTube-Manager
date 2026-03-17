#!/bin/bash

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script summarizer.sh interrupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in summarizer.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function main {
    transcript="$(cat /tmp/vidsift_transcript.txt)"
    title="$(cat /tmp/vidsift_title.txt)"
    dest_path="${1}${title}.md"
    echo "$transcript" | fabric -sp youtube_summary -o "$dest_path"
    /usr/local/bin/rename_one_file.sh 2 "$dest_path"
}

# call main with all args, as given
main "$@"
