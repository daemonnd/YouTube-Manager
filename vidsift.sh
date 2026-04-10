#!/bin/bash
# main script
# executes and orchestrates all the others:
# Gets the video urls from url_collector.sh, then validates them using url_validator.sh
# Runs video_validator.sh to validate the video
# Downloads, summarizes or does nothing depending on the score
# Go to the next video

# strict mode
set -Eeuo pipefail

function rm_tmp_files {
    rm "$VIDSIFT_DATA_DIR"/parsed_config.json 2>/dev/null || true
    rm "/tmp/vidsift_transcript.txt" 2>/dev/null || true
    rm "/tmp/vidsift_title.txt" 2>/dev/null || true
}

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script vidsift.sh interupted or failed. Cleaning up..."

    # remove tmp files
    rm_tmp_files
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

    # parse the config file, write the parsed version to a file in the data dir
    cat "${VIDSIFT_CONFIG_DIR%/}"/config.jsonc | "${VIDSIFT_HELPER_SCRIPTS_DIR%/}"/parse_config >"${VIDSIFT_DATA_DIR%/}"/parsed_config.json

    # set up fabric system prompt for validation later
    # create the target dir
    mkdir -p "/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript"
    # copy the custom pattern into fabric
    cp "$VIDSIFT_CONFIG_DIR"/vidsift_score_youtube_transcript.md "/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript/system.md"

    # set the destination paths for download and summary, and validate them
    download_path="$(jq -r '.dest_paths.videos' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    validate_target_dir "$download_path" "Video download"
    summary_path="$(jq -r '.dest_paths.summaries' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    validate_target_dir "$summary_path" "Ai summary"

    # add the paths that $PATH needs and export it
    mapfile -t required_paths < <(cat "$VIDSIFT_DATA_DIR/parsed_config.json" | jq -r '.general_processing.required_paths[]')
    old_ifs="$IFS"
    IFS=:
    required_paths=$(echo "${required_paths[*]}") #  elements get joined together depending on first character of $IFS
    export PATH="$PATH:$required_paths"
    IFS="$old_ifs"
}

function download_video {
    echo "Downloading ${1}..."
    "${VIDSIFT_HELPER_SCRIPTS_DIR}/downloader" "$1" "$download_path"
}

function summarize_video {
    echo "Summarizing transcript of ${1}..."
    "$VIDSIFT_HELPER_SCRIPTS_DIR"/summarizer "$summary_path"
}

function main {
    init
    while read -r url name action; do
        echo "Processing video $url from ${name} with action ${action}..."
        # check wether the video should be validated, downloaded or summarized, depending on the given action
        # validate: let ai validate the transcript and decide wether to download, summarize or do nothing with the video, depending on the score
        if [[ "$action" == "validate" ]]; then
            # fetch the necessary video data for validation and maybe summarization
            if ! "$VIDSIFT_HELPER_SCRIPTS_DIR"/fetch_video_data "$url" </dev/null; then
                echo "ERROR: Failed to fetch the transcript or title for the video ${url}. Therefore, this video will be skipped."
                continue
            fi
            # get the score from the ai
            score=$("$VIDSIFT_HELPER_SCRIPTS_DIR"/video_validator "$url" "$name" </dev/null)
            # if there was an error during the validation, the video gets skipped
            if [[ "$score" -eq -1 ]]; then
                echo "ERROR: Failed to download, summarize or do nothing with the video ${url}, because the score from the ai was not between 0 and 100."
                echo "Therefore, nothing will be done with this video."
                continue
            # if the ai did not return a number as score, the video gets skipped
            elif [[ "$score" -eq -2 ]]; then
                echo "ERROR: Failed to download, summarize or do nothing with the video ${url}, because the ai did not return a number as score."
                continue
            elif [[ "$score" -eq -3 ]]; then
                echo "ERROR: Failed to download, summarize or do nothing with the video ${url}, because the ai did not return anything, the response was empty."
            # if the score is above 80, it gets downloaded
            elif [[ "$score" -gt 80 ]]; then
                download_video "$url"
                # add the url to already_processed_urls.txt
                echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
            # if the score is between 40 and 80, it gets summarized
            elif [[ "$score" -lt 80 && "$score" -gt 40 || "$score" -eq 80 ]]; then
                summarize_video "$url"
                # add the url to already_processed_urls.txt
                echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
            # if the score is below 40, it gets neither downloaded nor summarized
            else
                echo "The video with the url $url would neither have been summarized nor been downloaded, because its score is $score"
                # add the url to already_processed_urls.txt
                echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
            fi
        # download: download the video without validating it with the ai
        elif [[ "$action" == "download" ]]; then
            download_video "$url"
            # add the url to already_processed_urls.txt
            echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
        # summarize: summarize the video transcript without validating it with ai
        elif [[ "$action" == "summary" ]]; then
            # fetch the necessary video data for summarization (transcript and title)
            if ! "$VIDSIFT_HELPER_SCRIPTS_DIR"/fetch_video_data "$url" </dev/null; then
                echo "ERROR: Failed to fetch the transcript or title for the video ${url}. Therefore, this video will be skipped."
            fi
            summarize_video "$url"
            # add the url to already_processed_urls.txt
            echo "$url" >>"$VIDSIFT_DATA_DIR"/already_processed_urls.txt
        # if the action is not valid, nothing happend with the video
        else
            echo "ERROR: Action $action for video $url from channel $name is not valid. Therefore, nothing will be done with this video."
            continue
        fi

    done < <("$VIDSIFT_HELPER_SCRIPTS_DIR"/url_collector | "$VIDSIFT_HELPER_SCRIPTS_DIR"/url_validator)

    # cleanup tmp files
    echo "All videos processed. Cleaning up..."
    rm_tmp_files
}

# call main with all args, as given
main "$@"
