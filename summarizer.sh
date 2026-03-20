#!/bin/bash
# File for summarizing a yt video transcript.
# It uses fabric for the ai and reads the transcript from a tmp file, the destination path is given as argument

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
    dest_path="${1}/${title}.md"
    echo "$transcript" | fabric -sp youtube_summary >"$dest_path"
    # if the user has the file renamer, rename it
    if [[ -x /usr/local/bin/rename_one_file.sh ]]; then
        /usr/local/bin/rename_one_file.sh 2 "$dest_path"
    fi
}

# call main with all args, as given
main "$@"
