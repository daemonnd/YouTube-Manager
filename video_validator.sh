#!/bin/bash
# file for validating the video. That includes:
# - fetching the transcript of the video
# - running fabric with a custom pattern against the transcript and get the score
# - return the action that should be performed

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script video_validator.sh interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO video_validator.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    :
}

function fetch_transcript {
    transcript="$(fabric -y "$1")"
}

function rate_video {
    score=$(echo "$transcript" | fabric -sp vidsift_score_youtube_transcript)
    # Check if the score is between 0 and 100 (0 & 100 are included)
    if [[ "$score" -lt 0 || "$score" -gt 100 ]]; then
        score=-1
    fi
    echo "$score"

}

function main {
    fetch_transcript "$1"
    rate_video
}

# call main with all args, as given
main "$@"
