#!/bin/bash
# file for fetching the transcript and the title of the video.
# It uses fabric for fetching the transcript and yt-dlp for fetching the title

# strict mode
set -Eeuo pipefail

# rm tmp files function
function rm_tmp_files {
    rm -f "${title_stdout_file:=}" 2>/dev/null || true
    rm -f "${title_stderr_file:=}" 2>/dev/null || true
    rm -f "${transcript_stdout_file:=}" 2>/dev/null || true
    rm -f "${transcript_stderr_file:=}" 2>/dev/null || true
}

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script fetch_video_data.sh interrupted or failed. Cleaning up..."

    # remove tmp files
    rm_tmp_files
    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in fetch_video_data.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    : "${1:?ERROR: The first arg that should contain the video url has not been set}"
    : "${2:?ERROR: The second arg that should contain the channelid has not been set}"
}

function init {
    # load the yt-dlp args for using yt-dlp and for example the cookies from the user-specified browser
    mapfile -t yt_dlp_args < <(cat "$VIDSIFT_DATA_DIR"/parsed_config.json | jq -r '.general_processing."yt-dlp_args"[]')
    source "$VIDSIFT_HELPER_SCRIPTS_DIR"/log
    # getting the date that should be used until a youtube rate limit affected channel gets unblocked
    RATE_LIMIT_UNBLOCK_DATE="$(jq -r '.video_filtering.rate_limit_unblock_time' "$VIDSIFT_DATA_DIR/parsed_config.json")"
    RATE_LIMIT_UNBLOCK_DATE="$(date -d "$RATE_LIMIT_UNBLOCK_DATE" '+%F')"
    log "DEBUG" "Initializing fetch_video_data.sh went well"
}

# function to fetch the transcript of the video with fabric
function fetch_transcript {
    transcript_stdout_file=$(mktemp)
    transcript_stderr_file=$(mktemp)
    log "DEBUG" "Fetching the transcript from $1 with the additional yt-dlp_args ${yt_dlp_args[*]}..."
    if ! fabric -y "$1" --yt-dlp-args="${yt_dlp_args[*]}" >"$transcript_stdout_file" 2>"$transcript_stderr_file"; then
        if [[ "$(cat $transcript_stderr_file)" == *"YouTube rate limit exceeded"* ]]; then
            echo "$RATE_LIMIT_UNBLOCK_DATE" "$2" >>"$VIDSIFT_DATA_DIR/rate_limit_affected_channelids.txt"
            log "WARNING" "An Error occured while fetching the transcript: $(cat $transcript_stderr_file), the channelid will be added to rate_limit_affected_channelids.txt and blocked until $RATE_LIMIT_UNBLOCK_DATE."
            return 1
        else
            log "ERROR" "An Error occured while fetching the transcript: $(cat $transcript_stderr_file)"
            return 1
        fi
    else
        cat "$transcript_stdout_file" >/tmp/vidsift_transcript.txt
    fi
    log "DEBUG" "Fetching the transcript from $1 with the additional yt-dlp_args ${yt_dlp_args[*]}... Done (It has been written to /tmp/vidsift_transcript.txt)"
}

# function to fetch the title of the video for later use as name for the summary file
function fetch_title {
    title_stdout_file=$(mktemp)
    title_stderr_file=$(mktemp)

    log "DEBUG" "Fetching the title from $1 with additional yt-dlp_args ${yt_dlp_args[*]}..."
    if ! yt-dlp --skip-download "${yt_dlp_args[@]}" -O '%(title)s' "$1" >"$title_stdout_file" 2>"$title_stderr_file"; then
        if [[ "$(cat $title_stderr_file)" == *"YouTube rate limit exceeded"* ]]; then
            echo "$RATE_LIMIT_UNBLOCK_DATE" "$2" >>"$VIDSIFT_DATA_DIR/rate_limit_affected_channelids.txt"
            log "WARNING" "An Error occured while fetching the title: $(cat $title_stderr_file), the channelid will be added to rate_limit_affected_channelids.txt and blocked until $RATE_LIMIT_UNBLOCK_DATE."
            return 1
        else
            log "ERROR" "An Error occured while fetching the title: $(cat $title_stderr_file)"
            return 1
        fi
    else
        cat "$title_stdout_file" >/tmp/vidsift_title.txt
    fi
    log "DEBUG" "Fetching the title from $1 with additional yt-dlp_args ${yt_dlp_args[*]}... Done (It has been written to /tmp/vidsift_title.txt)"
    #YouTube rate limit exceeded
}

function main {
    init "$@"
    fetch_transcript "$@"
    fetch_title "$@"
}

# call main with all args, as given
main "$@"
