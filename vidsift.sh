#!/bin/bash
# main script
# executes and orchestrates all the others:
# Gets the video urls from url_collector.sh, then validates them using url_validator.sh
# Runs video_validator.sh to validate the video
# Downloads, summarizes or does nothing depending on the score
# Go to the next video

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script vidsift.sh interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in vidsift.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    :
}

function validate_target_dir {
    if [[ ! -w "$1" || ! -d "$1" ]]; then
        echo "ERROR: $2 target path seems to be corrupt. The user $USER needs writing permission to the dir at ${1}."
        exit 1
    fi
}

function init {
    # set directories
    # config dir
    export VIDSIFT_CONFIG_DIR="${VIDSIFT_CONFIG_DIR:-${XDG_CONFIG_HOME-${HOME}/.config/vidsift/}}"
    # data dir
    export VIDSIFT_DATA_DIR="${VIDSIFT_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share/vidsift/}}"
    # vidsift bin dir
    export VIDSIFT_BIN_DIR="${VIDSIFT_BIN_DIR:-${XDG_BIN_HOME:-"$HOME/.local/bin/"}}"
    # helper scripts dir
    export VIDSIFT_HELPER_SCRIPTS_DIR="${VIDSIFT_HELPER_SCRIPTS_DIR:-${XDG_BIN_HOME:-"$HOME/.local/lib/vidsift"}}"

    # set up fabric system prompt for validation later
    # create the target dir
    mkdir -p "/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript"
    # copy the custom pattern into fabric
    cp "$VIDSIFT_CONFIG_DIR"/vidsift_score_youtube_transcript.md "/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript/system.md"

    # currently hardcoded dest paths
    download_path="/home/$USER/Videos/vidsift/"
    validate_target_dir "$download_path" "Video download"
    summary_path="/home/$USER/Documents/vidsift"
    validate_target_dir "$summary_path" "Ai summary"
}

function main {
    init
    while read -r url name; do
        echo "Processing video $url from ${name}..."
        score=$("$VIDSIFT_HELPER_SCRIPTS_DIR"/video_validator "$url" "$name" </dev/null)
        if [[ "$score" -eq -1 ]]; then
            echo "ERROR: Failed to download, summarize or do nothing with the video ${url}, because the score from the ai was not between 0 and 100."
            echo "Therefore, nothing will be done with this video."
            continue
        elif [[ "$score" -eq -2 ]]; then
            echo "ERROR: Failed to download, summarize or do nothing with the video ${url}, because the ai did not return a number as score."
        elif [[ "$score" -gt 80 ]]; then
            echo "Downloading ${url}..."
            "$VIDSIFT_HELPER_SCRIPTS_DIR"/downloader "$url" "$download_path"
            # add the url to already_processed_urls.txt
            echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
        elif [[ "$score" -lt 80 && "$score" -gt 40 || "$score" -eq 80 ]]; then
            echo "Summarizing transcript of ${url}..."
            "$VIDSIFT_HELPER_SCRIPTS_DIR"/summarizer "$summary_path"
            # add the url to already_processed_urls.txt
            echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
        else
            echo "Then video with the url $url would neither have been summarized nor been downloaded, because its score is $score"
            # add the url to already_processed_urls.txt
            echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
        fi
    done < <("$VIDSIFT_HELPER_SCRIPTS_DIR"/url_collector | "$VIDSIFT_HELPER_SCRIPTS_DIR"/url_validator)
}

# call main with all args, as given
main "$@"
