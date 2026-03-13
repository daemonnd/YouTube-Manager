#!/bin/bash

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function main {
    while read -r name channelid; do
        echo "Reading RSS feed from $name with channel id ${channelid}..."
        # extract all the urls from the xml
        while read -r url; do
            echo "$url" >>new_urls.txt
        done < <(curl -s "https://www.youtube.com/feeds/videos.xml?channel_id=$channelid" | xmllint --xpath "//*[local-name() = 'link']/@href" - | awk -F '"' ' {print $2} ' | grep -oE 'http.*watch.*')
    done < <(jq -r "to_entries[]"' | [.key, .value] | @tsv' channelids.json)
}

# call main with all args, as given
main "$@"
