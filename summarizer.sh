#!/bin/bash
# File for summarizing a yt video transcript.
# It uses fabric for the ai and reads the transcript from a tmp file, the destination path is given as argument

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
    echo "Script summarizer.sh interrupted or failed. Cleaning up..."

    # remove tmp files
    rm_tmp_files
    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in summarizer.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    :
}

function init {
    # get ai model and provider
    AI_MODEL="$(jq -r '.general_processing.ai_model' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    AI_PROVIDER="$(jq -r '.general_processing.ai_provider' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
}

function rename_dest_path {
    # if the user has the file renamer, rename it
    if [[ -x /usr/local/bin/rename_one_file.sh ]]; then
        /usr/local/bin/rename_one_file.sh 2 "$dest_path"
    fi
}

function main {
    init "$@"

    transcript="$(cat /tmp/vidsift_transcript.txt)"
    title="$(cat /tmp/vidsift_title.txt)"
    dest_path="${1}/${title}.md"

    fabric_stdout_file=$(mktemp)
    fabric_stderr_file=$(mktemp)
    if ! echo "$transcript" | fabric --vendor "$AI_PROVIDER" --model "$AI_MODEL" -sp youtube_summary >"$fabric_stdout_file" 2>"$fabric_stderr_file"; then
        :
    fi
    # if response is empty
    if [[ $(cat "$fabric_stderr_file") == *"empty response"* ]]; then
        echo "Please remove the url with the title $title from $VIDSIFT_DATA_DIR/already_processed_urls.txt"
        rm_tmp_files
    fi
    # if there is no stderr, write the summary to the destination path
    if [[ -z "$(cat $fabric_stderr_file)" ]]; then
        cat "$fabric_stdout_file" >"$dest_path"

        rename_dest_path

        rm_tmp_files
        exit 0
    else
        # if not, exit with an error
        cleanup
    fi
}

# call main with all args, as given
main "$@"
