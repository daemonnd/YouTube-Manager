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
    : "${2:?ERROR: The second arg that should contain the creator name has not been set}"
}

function fetch_transcript {
    if ! transcript="$(fabric -y "$1" --yt-dlp-args="--cookies-from-browser firefox")"; then
        return 1
    fi
}

function get_custom_instuctions {
    # function to get the channel-specific instructions for ai validation
    if [[ -r "./custom_channel_instructions/$1.md" ]]; then
        custom_channel_instructions="$(cat ./custom_channel_instructions/$1.md)"
    else
        custom_channel_instructions=""
    fi
}

function create_final_system_prompt {
    # function for merging the system prompt with the custom channel-specific instructions for the ai
    base_system_prompt="$(cat "$VIDSIFT_CONFIG_DIR"/vidsift_score_youtube_transcript.md)"
    final_system_prompt="${base_system_prompt//'$CUSTOM_CHANNEL_INSTRUCTIONS'/$custom_channel_instructions}"

    # replace the current system prompt for the ai by the new one
    echo "$final_system_prompt" >"/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript/system.md"
}

function rate_video {
    score=$(echo "$transcript" | fabric -sp vidsift_score_youtube_transcript)
    # Check if score is a number
    if [[ "$score" =~ ^[0-9]+$ ]]; then
        score="$score"
    else
        score=-2
    fi
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
    check_args "$@"
    get_custom_instuctions "$2"
    create_final_system_prompt

    rate_video "$@"
}

# call main with all args, as given
main "$@"
