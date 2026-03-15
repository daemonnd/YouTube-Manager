#!/bin/bash
# main script
# executes and orchestrates all the others

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
function init {
    # set up fabric system prompt for validation later
    # create the target dir
    mkdir -p "/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript"
    # copy the custom pattern into fabric
    cp ./vidsift_score_youtube_transcript.md "/home/$USER/.config/fabric/patterns/vidsift_score_youtube_transcript/system.md"

    # currently hardcoded dest paths
    download_path="/home/$USER/Videos/ytd/"
    if [[ ! -w "$download_path" || ! -d "$download_path" ]]; then
        echo "ERROR: Video download target path seems to be corrupt. The user $USER needs writing permission to the dir at ${download_path}."
        exit 1
    fi
    summary_path="/home/$USER/Documents/markdown/ai_answers_fabrici/"
    if [[ ! -w "$summary_path" || ! -d "$summary_path" ]]; then
        echo "ERROR: Summary target path seems to be corrupt. The user $USER needs writing permission to the dir at ${summary_path}."
        exit 1
    fi

}

function main {
    init
    while read -r url; do
        echo "url: $url"
        score=$(./video_validator.sh "$url" </dev/null)
        if [[ "$score" -eq -1 ]]; then
            echo "ERROR: Failed to download, summarize or do nothing with the video ${url}, because the score from the ai was not between 0 and 100."
            echo "Therefore, nothing will be done with this video."
            continue
        elif [[ "$score" -gt 80 ]]; then
            echo "The video with the url $url would have been downloaded, because its score is $score"
        elif [[ "$score" -lt 80 && "$score" -gt 40 || "$score" -eq 80 ]]; then
            echo "The video with the url $url would have been summarized, because its score is $score"
        else
            echo "Then video with the url $url would neither have been summarized nor been downloaded, because its score is $score"
        fi
    done < <(./url_collector.sh | ./url_validator.sh)
}

# call main with all args, as given
main "$@"
