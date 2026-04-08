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
        "local")
            fresh_install="false"
            ;;&
        "daemon-setup")
            daemon_setup="true"
            ;;
        esac
    done
}

function clone_repo {
    # cloning the repo to a dir named vidsift in the current directory, and cd into it
    git clone "https://github.com/daemonnd/VidSift.git" "vidsift" && cd "vidsift"
}

function init {
    # checking if the root user or a regular user is running the script
    if [[ "$EUID" -ne 0 ]]; then
        install_vidsift="true"
    else
        install_vidsift="false"
    fi

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
    fresh_install="true"
    daemon_setup="false"
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

function set_up_daemon {
    SUDO_USER="${SUDO_USER:-}"
    if [ -n "$SUDO_USER" ]; then
        SUDO_HOME=$(getent passwd "$SUDO_USER" | awk -F ':' '{ print $6 }')
    else
        SUDO_HOME="$HOME"
    fi

    if ! cat <<EOF >/etc/systemd/system/vidsift-manager.service; then
[Unit]
Description=Service for running vidsift in the background
After=network-online.target

[Service]
Type=oneshot
ExecStart=$SUDO_HOME/.local/bin/vidsift
User=$SUDO_USER

[Install]
WantedBy=multi-user.target
EOF
        echo "ERROR: PermissionError: Please run this script as root to set up the background service."
        exit 1
    fi

    echo "This script assumes that the vidsift bin dir of the sudo user is $SUDO_HOME/.local/bin/. If it is wrong, edit the service file."

    systemctl daemon-reload
    systemctl enable vidsift-manager.service

    echo "The background daemon has been set up successfully"
    echo "Vidsift has not been installed. Please re-run this install script without root priviledges to install or update vidsift."
}

function cp_files {
    # copying the files to their target locations
    # config
    if [[ ! -f "${VIDSIFT_CONFIG_DIR%/}"/config.jsonc ]]; then
        echo "Copying default config.jsonc to ${VIDSIFT_CONFIG_DIR%/}/config.jsonc, because it does not exist or is not readable."
        cp ./config.jsonc "${VIDSIFT_CONFIG_DIR%/}/config.jsonc" || {
            echo "ERROR: config.jsonc not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
            exit 1
        }
    else
        echo "config.jsonc already exists in $VIDSIFT_CONFIG_DIR. Skipping copy to preserve user modifications."
    fi
    cp -r ./custom_channel_instructions/ "$VIDSIFT_CONFIG_DIR/custom_channel_instructions" || true # only copy if it does exist, to preserve user modifications
    cp ./vidsift_score_youtube_transcript.md "$VIDSIFT_CONFIG_DIR/vidsift_score_youtube_transcript.md" || {
        echo "ERROR: vidsift_score_youtube_transcript.md not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
        exit 1
    }
    # data
    cp ./already_processed_urls.txt "$VIDSIFT_DATA_DIR/already_processed_urls.txt" || true # only copy if it does exist, to preserve user modifications
    echo "If you are doing a fresh install, you can ignore the above warnings about, custom_channel_instructions, and already_processed_urls.txt. These files are only copied if they don't already exist, to preserve any modifications you may have made to them."
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
    cp ./fetch_video_data.sh "$VIDSIFT_HELPER_SCRIPTS_DIR/fetch_video_data" || {
        echo "ERROR: fetch_video_data.sh not found. Please make sure it is in the same directory as this install.sh script, which is the project root directory."
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
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/parse_config"
    chmod +x "$VIDSIFT_HELPER_SCRIPTS_DIR/fetch_video_data"
}

function check_installation_path {
    # check if vidsift bin dir in in $PATH, and if not, add it to ~/.bashrc and print a warning
    VIDSIFT_BIN_DIR="${VIDSIFT_BIN_DIR%/}"
    if echo "$PATH" | grep -IFq "$VIDSIFT_BIN_DIR"; then
        mkdir -p "$VIDSIFT_BIN_DIR" # create if it does not exist
        echo "vidsift bin directory $VIDSIFT_BIN_DIR is already in your PATH."
    else
        mkdir -p "$VIDSIFT_BIN_DIR" # create if it does not exist
        if [[ "$HOME" != *"root"* ]]; then
            echo "export PATH="'"$PATH:'$VIDSIFT_BIN_DIR'"' >>"$HOME/.bashrc"
            echo "Please run 'source ~/.bashrc' to add the vidsift bin directory to your PATH"
        fi
        echo "WARNING: $VIDSIFT_BIN_DIR is not in your PATH. It has been added to your ~/.bashrc file if you are not root."
    fi
}

function before_install {
    if [[ "$install_vidsift" != "true" ]]; then
        echo "ERROR: The root/superuser cannot install vidsift, it is a user program. Please run this script when installing without superuser/root priviledges."
        exit 1
    fi
}

function main {
    init "$@"
    check_installation_path "$@"
    check_args "$@"
    # if the user only want to set up the background service
    if [[ "$daemon_setup" == "true" ]]; then
        echo "Any args concerning the installation of vidsift just like the installation of vidsift itself will be skipped, because this script is running as root."
        if [[ "$install_vidsift" == "false" ]]; then
            echo "Setting up the service..."
            set_up_daemon "$@"
            exit 0
        else
            echo "ERROR: Only the root/superuser is allowed to set up the background service"
            exit 0
        fi
    fi
    # if the user want to install vidsift from the github repo or locally
    if [[ "$fresh_install" == "true" ]]; then
        before_install
        echo "Performing a fresh install..."
        clone_repo "$@"
    fi
    before_install
    create_directories "$@"
    cp_files "$@"
    set_permissions "$@"
}

# call main with all args, as given
main "$@"
