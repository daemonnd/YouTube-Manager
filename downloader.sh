#!/bin/bash
# File for downloading a video
# It gets the url and target dir and downloads the video to the target dir using yt-dlp

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script downloader.sh interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in downloader.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function init {
    declare -a yt_dlp_args
    declare -a download_specific_yt_dlp_args
    # get the additional yt-dlp args used for every yt-dlp call from the parsed config file
    mapfile -t yt_dlp_args < <(cat "$VIDSIFT_DATA_DIR"/parsed_config.json | jq -r '.general_processing."yt-dlp_args"[]')
    cat "$VIDSIFT_DATA_DIR"/parsed_config.json | jq -r '.general_processing."yt-dlp_args"[]'
    # get the download-specific yt-dlp args used for the download operation from the parsed config file and add them to the general yt-dlp args
    mapfile -t download_specific_yt_dlp_args < <(cat "$VIDSIFT_DATA_DIR"/parsed_config.json | jq -r '.video_download."yt-dlp_args"[]')
    cat "$VIDSIFT_DATA_DIR"/parsed_config.json | jq -r '.video_download."yt-dlp_args"[]'
}

function rename_dest_path {
    # if the user has the file renamer, rename it
    if [[ -x /usr/local/bin/rename_one_file.sh ]]; then
        /usr/local/bin/rename_one_file.sh 2 "$1"
    fi
}

function main {
    init "$@"
    # cd to target dir
    cd "$2"
    yt-dlp \
        "${yt_dlp_args[@]}" \
        "${download_specific_yt_dlp_args[@]}" \
        --exec 'if [[ ! -x /usr/local/bin/rename_one_file.sh ]]; then
                    exit 0
                fi
                echo $0
                /usr/local/bin/rename_one_file.sh 2 ' \
        "$1"
}

# call main with all args, as given
main "$@"
