#!/bin/bash

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script <script name> interrupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in <script name>: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function main {
    # set directories
    # config dir
    VIDSIFT_CONFIG_DIR="${XDG_CONFIG_HOME:-"$HOME/.config/vidsift"}"
    # data dir
    VIDSIFT_DATA_DIR="${XDG_DATA_HOME:-"$HOME/.local/share/vidsift"}"
    # vidsift bin dir
    VIDSIFT_BIN_DIR="${XDG_BIN_HOME:-"$HOME/.local/bin"}"
    # helper scripts dir
    VIDSIFT_HELPER_SCRIPTS_DIR="${XDG_BIN_HOME:-"$HOME/.local/lib/vidsift"}"

    # create the directories if they don't exist
    # config dir
    mkdir -p "$VIDSIFT_CONFIG_DIR"
    # data dir
    mkdir -p "$VIDSIFT_DATA_DIR"
    # vidsift bin dir
    mkdir -p "$VIDSIFT_BIN_DIR"
    # helper scripts dir
    mkdir -p "$VIDSIFT_HELPER_SCRIPTS_DIR"

    # copying the files to their target locations
    # config
    cp ./channelids.json "$VIDSIFT_CONFIG_DIR/channelids.json"
    cp -r ./custom_channel_instructions/ "$VIDSIFT_CONFIG_DIR/custom_channel_instructions"
    cp ./vidsift_score_youtube_transcript.md "$VIDSIFT_CONFIG_DIR/vidsift_score_youtube_transcript.md"
    # data
    cp ./already_processed_urls.txt "$VIDSIFT_DATA_DIR/already_processed_urls.txt"
    # vidsift bin
    cp ./vidsift.sh "$VIDSIFT_BIN_DIR/vidsift"
    # helper scripts
    cp ./url_collector.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/url_collector"
    cp ./url_validator.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/url_validator"
    cp ./video_validator.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/video_validator"
    cp ./downloader.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/downloader"
    cp ./summarizer.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/summarizer"

    # giving execute permissions to the vidsift bin and helper scripts
    # vidsift bin
    chmod +x "$VIDSIFT_BIN_DIR/vidsift"
    # vidsift helper scripts
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/url_collector"
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/url_validator"
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/video_validator"
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/downloader"
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/summarizer"
}

# call main with all args, as given
main "$@"
