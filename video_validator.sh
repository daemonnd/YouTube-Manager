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
    if ! transcript="$(fabric -y "$1" --yt-dlp-args="--cookies-from-browser firefox")"; then
        return 1
    fi
}

function rate_video {
    score=$(echo "$transcript" | fabric -sp vidsift_score_youtube_transcript)
    # Check if the score is between 0 and 100 (0 & 100 are included)
    if [[ ! "$score" -ge 0 && ! "$score" -le 100 ]]; then
        score=-1
    fi
    # write the transcript to a file if it should be summarized
    if [[ "$score" -lt 80 && "$score" -gt 40 || "$score" -eq 80 ]]; then
        echo "$transcript" >/tmp/vidsift_transcript.txt
        yt-dlp --skip-download -O '%(title)s' "$1" >/tmp/vidsift_title.txt
    fi
    echo "$score"

}

function main {
    if ! fetch_transcript "$1"; then
        echo -1
        return 0
    fi
    rate_video "$@"
}

# call main with all args, as given
main "$@"
