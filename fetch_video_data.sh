#!/bin/bash
# file for fetching the transcript and the title of the video.
# It uses fabric for fetching the transcript and yt-dlp for fetching the title

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script fetch_video_data.sh interrupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in fetch_video_data.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    : "${1:?ERROR: The first arg that should contain the video url has not been set}"
}

function init {
    # load the yt-dlp args for using yt-dlp and for example the cookies from the user-specified browser
    mapfile -t yt_dlp_args < <(cat "$VIDSIFT_DATA_DIR"/parsed_config.json | jq -r '.general_processing."yt-dlp_args"[]')
    source "$VIDSIFT_HELPER_SCRIPTS_DIR"/log
    log "DEBUG" "Initializing fetch_video_data.sh went well"
}

# function to fetch the transcript of the video with fabric
function fetch_transcript {
    log "DEBUG" "Fetching the transcript from $1 with the additional yt-dlp_args ${yt_dlp_args[*]}..."
    if ! transcript="$(fabric -y "$1" --yt-dlp-args="${yt_dlp_args[*]}")"; then
        return 1
    else
        echo "$transcript" >/tmp/vidsift_transcript.txt
    fi
    log "DEBUG" "Fetching the transcript from $1 with the additional yt-dlp_args ${yt_dlp_args[*]}... Done (It has been written to /tmp/vidsift_transcript.txt)"
}

# function to fetch the title of the video for later use as name for the summary file
function fetch_title {
    log "DEBUG" "Fetching the title from $1 with additional yt-dlp_args ${yt_dlp_args[*]}..."
    yt-dlp --skip-download "${yt_dlp_args[@]}" -O '%(title)s' "$1" >/tmp/vidsift_title.txt
    log "DEBUG" "Fetching the title from $1 with additional yt-dlp_args ${yt_dlp_args[*]}... Done (It has been written to /tmp/vidsift_title.txt)"
}

function main {
    init "$@"
    fetch_transcript "$@"
    fetch_title "$@"
}

# call main with all args, as given
main "$@"
