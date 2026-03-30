#!/bin/bash

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script install.sh interrupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in install.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    # check if the script is being run with arguments
    # check for arguments for a fresh install
    for arg in "$@"; do
        case "$arg" in
        "fresh")
            fresh_install="true"
            ;;
        esac
    done
}

function clone_repo {
    # cloning the repo to a dir named vidsift in the current directory, and cd into it
    git clone "https://github.com/daemonnd/VidSift.git" "vidsift" && cd "vidsift"
}

function init {
    # set directories
    # config dir
    VIDSIFT_CONFIG_DIR="${VIDSIFT_CONFIG_DIR:-${XDG_CONFIG_HOME-${HOME}/.config/vidsift/}}"
    # data dir
    VIDSIFT_DATA_DIR="${VIDSIFT_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share/vidsift/}}"
    # vidsift bin dir
    VIDSIFT_BIN_DIR="${VIDSIFT_BIN_DIR:-${XDG_BIN_HOME:-"$HOME/.local/bin/"}}"
    # helper scripts dir
    VIDSIFT_HELPER_SCRIPTS_DIR="${VIDSIFT_HELPER_SCRIPTS_DIR:-${XDG_BIN_HOME:-"$HOME/.local/lib/vidsift"}}"

    # add "vidsift" to the end of the dirs if it is not already there
    if [[ ${VIDSIFT_CONFIG_DIR} != *"vidsift"* ]]; then
        VIDSIFT_CONFIG_DIR="${VIDSIFT_CONFIG_DIR%/}/vidsift"
    fi
    if [[ "$VIDSIFT_DATA_DIR" != *"vidsift"* ]]; then
        VIDSIFT_DATA_DIR="${VIDSIFT_DATA_DIR%/}/vidsift"
    fi
    if [[ "$VIDSIFT_HELPER_SCRIPTS_DIR" != *"vidsift"* ]]; then
        VIDSIFT_HELPER_SCRIPTS_DIR="${VIDSIFT_HELPER_SCRIPTS_DIR%/}/vidsift"
    fi

    # set default values for flags
    fresh_install="false"
}

function create_directories {
    # create the directories if they don't exist
    # config dir
    mkdir -p "$VIDSIFT_CONFIG_DIR"
    # data dir
    mkdir -p "$VIDSIFT_DATA_DIR"
    # vidsift bin dir
    mkdir -p "$VIDSIFT_BIN_DIR"
    # helper scripts dir
    mkdir -p "$VIDSIFT_HELPER_SCRIPTS_DIR"
}

function cp_files {
    # copying the files to their target locations
    # config
    cp ./channelids.json "$VIDSIFT_CONFIG_DIR/channelids.json" || true                             # only copy if it does exist, to preserve user modifications
    cp -r ./custom_channel_instructions/ "$VIDSIFT_CONFIG_DIR/custom_channel_instructions" || true # only copy if it does exist, to preserve user modifications
    cp ./vidsift_score_youtube_transcript.md "$VIDSIFT_CONFIG_DIR/vidsift_score_youtube_transcript.md" || {
        echo "ERROR: vidsift_score_youtube_transcript.md not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    # data
    cp ./already_processed_urls.txt "$VIDSIFT_DATA_DIR/already_processed_urls.txt" || true # only copy if it does exist, to preserve user modifications
    echo "If you are doing a fresh install, you can ingore the above warnings about channelids.json, custom_channel_instructions, and already_processed_urls.txt. These files are only copied if they don't already exist, to preserve any modifications you may have made to them."
    # vidsift bin
    cp ./vidsift.sh "$VIDSIFT_BIN_DIR/vidsift" || {
        echo "ERROR: vidsift.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    # helper scripts
    cp ./url_collector.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/url_collector" || {
        echo "ERROR: url_collector.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    cp ./url_validator.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/url_validator" || {
        echo "ERROR: url_validator.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    cp ./video_validator.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/video_validator" || {
        echo "ERROR: video_validator.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    cp ./downloader.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/downloader" || {
        echo "ERROR: downloader.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    cp ./summarizer.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/summarizer" || {
        echo "ERROR: summarizer.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    cp ./parse_config.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/parse_config" || {
        echo "ERROR: parse_config.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
}

function set_permissions {
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

function check_installation_path {
    # check if vidsift bin dir in in $PATH, and if not, add it to ~/.bashrc and print a warning
    VIDSIFT_BIN_DIR="${VIDSIFT_BIN_DIR%/}"
    if echo "$PATH" | grep -IFq "$VIDSIFT_BIN_DIR"; then
        mkdir -p "$VIDSIFT_BIN_DIR" # create if it does not exist
        echo "vidsift bin directioty $VIDSIFT_BIN_DIR is already in your PATH."
    else
        mkdir -p "$VIDSIFT_BIN_DIR" # create if it does not exist
        echo "export PATH="'"$PATH:'$VIDSIFT_BIN_DIR'"' >>"$HOME/.bashrc"
        echo "WARNING: $VIDSIFT_BIN_DIR is not in your PATH. It has been added to your ~/.bashrc file."
        echo "Please run 'source ~/.bashrc' to add the vidsift bin directory to your PATH"
    fi
}

function main {
    init "$@"
    check_installation_path "$@"
    check_args "$@"
    if [[ "$fresh_install" == "true" ]]; then
        echo "Performing a fresh install..."
        clone_repo "$@"
    fi
    create_directories "$@"
    cp_files "$@"
    set_permissions "$@"
}

# call main with all args, as given
main "$@"
