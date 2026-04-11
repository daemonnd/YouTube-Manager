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
    # create the file rate_limit_affected_channelids.txt only if it is non-existant
    if [[ ! -r "$VIDSIFT_DATA_DIR"/rate_limit_affected_channelids.txt ]]; then
        touch "$VIDSIFT_DATA_DIR"/rate_limit_affected_channelids.txt
    fi
    # parse the config file, savaing the relevant channels for the different operations to variables
    VALIDATE_CHANNELS="$(jq '.channel_operations.validate' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    DOWNLOAD_CHANNELS="$(jq '.channel_operations.download' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    SUMMARY_CHANNELS="$(jq '.channel_operations.summary' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
    # get the date when the videos should be newer than
    UPLOADED_BEFORE="$(jq -r '.video_filtering.uploaded_before' "$VIDSIFT_DATA_DIR"/parsed_config.json)"
}

function read_channelids {
    local operation_var="${1^^}_CHANNELS"   # get the variable name in uppercase with _CHANNELS suffix, e.g. VALIDATE_CHANNELS
    local operation_var="${!operation_var}" # indirect variable expansion to get the value of the variable, which is a json object with channel names as keys and channel ids as values
    while read -r name channelid; do
        # getting the last date with the channelid
        if ! channel_blocked_until=$(cat "$VIDSIFT_DATA_DIR/rate_limit_affected_channelids.txt" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2} $channelid" | awk ' { print $1 } ' | sort | tail -n1); then
            channel_blocked_until='0000-00-00'
        fi

        # checking if the channelid is blocked because of youtube rate limit issues
        if [[ "$(date '+%F')" < "$channel_blocked_until" ]]; then
            continue
        fi

        # extract all the urls from the xml
        while read -r date url; do
            if ! date="$(echo $date | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')"; then # only if the line contains a valid date
                continue
            fi
            if [[ "$date" > "$(date -d "$UPLOADED_BEFORE" '+%F')" ]]; then # checking if the date is older than 14 days. If older: do nothing, if newer: add to stdout for later processing
                echo "$url $name" "$1" "$channelid"
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

    done < <(echo "$operation_var" | jq -r "to_entries[]"' | [.key, .value] | @tsv')
}

function main {
    init
    read_channelids "download"
    read_channelids "validate"
    read_channelids "summary"

}

# call main with all args, as given
main "$@"
