#!/bin/bash
# file for validating the video. That includes:
# - running fabric with a custom pattern against the transcript and get the score
# - return the action that should be performed

# strict mode
set -Eeuo pipefail

# rm tmp files function
function rm_tmp_files {
    rm -f "${fabric_stdout_file:=}" 2>/dev/null || true
    rm -f "${fabric_stderr_file:=}" 2>/dev/null || true
}

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script video_validator.sh interupted or failed. Cleaning up..."

    # remove tmp files
    rm_tmp_files
    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO video_validator.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    : "${1:?ERROR: The first arg that should contain the video url has not been set}"
    : "${2:?ERROR: The second arg that should contain the creator name has not been set}"
}

function init {
    transcript="$(cat /tmp/vidsift_transcript.txt)"
    # get ai model and provider
    AI_MODEL="$(jq -r '.general_processing.ai_model' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    AI_PROVIDER="$(jq -r '.general_processing.ai_provider' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
}

function get_custom_instuctions {
    # function to get the channel-specific instructions for ai validation
    if [[ -r "$VIDSIFT_CONFIG_DIR/custom_channel_instructions/$1.md" ]]; then
        custom_channel_instructions="$(cat "$VIDSIFT_CONFIG_DIR"/custom_channel_instructions/$1.md)"
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
    fabric_stdout_file=$(mktemp)
    fabric_stderr_file=$(mktemp)
    if ! echo "$transcript" | fabric --vendor "$AI_PROVIDER" --model "$AI_MODEL" -sp vidsift_score_youtube_transcript >"$fabric_stdout_file" 2>"$fabric_stderr_file"; then
        :
    fi
    score=$(cat "$fabric_stdout_file")
    if [[ $(cat "$fabric_stderr_file") == *"empty response"* ]]; then
        score=-3
        echo "$score"
        return 0
    fi
    if [[ -z $(cat "$fabric_stderr_file") ]]; then

        # Check if score is a number
        if [[ "$score" =~ ^[0-9]+$ ]]; then
            :
        else
            score=-2
        fi
        # Check if the score is between 0 and 100 (0 & 100 are included)
        if [[ ! "$score" -ge 0 && ! "$score" -le 100 ]]; then
            score=-1
        fi
        echo "$score"
    else
        cleanup
    fi

}

function main {
    init "$@"
    check_args "$@"
    get_custom_instuctions "$2"
    create_final_system_prompt

    rate_video "$@"

    rm_tmp_files
}

# call main with all args, as given
main "$@"
