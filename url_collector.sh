#!/bin/bash
# File for fetching the channelids from channelids.json and dealing with the xml from each channel
# It reads the rss feed, filters it down to the video links and creation date with awk,
# then check if it is older than 2 weeks.
# If it is older, it won't be processed
# If it is newer, it gets print to stdout for further processing

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script url_collector.sh interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in url_collector.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function init {
    # create the file already_processed_urls.txt only if it is non-existant
    if [[ ! -w "$VIDSIFT_DATA_DIR"/already_processed_urls.txt ]]; then
        touch "$VIDSIFT_DATA_DIR"/already_processed_urls.txt
    fi
}

function main {
    init

    while read -r name channelid; do
        # extract all the urls from the xml
        while read -r date url; do
            if ! date="$(echo $date | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')"; then # only if the line contains a valid date
                continue
            fi
            if [[ "$date" > "$(date -d '14 days ago' '+%F')" ]]; then # checking if the date is older than 14 days. If older: do nothing, if newer: add to stdout for later processing
                echo "$url $name"
            fi
        done < <(
            # get the xml rss feed, filter it down to the publication date and link with awk
            xml=$(curl -s "https://www.youtube.com/feeds/videos.xml?channel_id=$channelid")
            echo "$xml" | awk -F '"' ' $0 ~ /link/ || $0 ~/published/ {
                    if ( $0 ~ /watch/ ) {
                        link=$4
                    }
                    if ( $0 ~ /published/ ) {
                            if ( link ~ /watch/ ) {
                                print $0,  link
                                link=""
                            }
                        }
                }'
        )

    done < <(jq -r "to_entries[]"' | [.key, .value] | @tsv' "$VIDSIFT_CONFIG_DIR"/channelids.json)
}

# call main with all args, as given
main "$@"
