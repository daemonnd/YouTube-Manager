#!/bin/bash
# File for validating the given url from url_collector.sh
# If the url has already been processed (is in already_processed_urls.txt), it gets skippen
# If not, it gets print together with the creator name to stdout for validation

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script url_validator.sh interupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in url_validator.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function main {
    while read -r url name action channelid; do
        # only print the video url and creator name if it is not in already_processed_urls.txt
        if ! grep -q "$url" <"$VIDSIFT_DATA_DIR"/already_processed_urls.txt; then
            echo "$url $name $action" "$channelid"
        fi
    done
}

# call main with all args, as given
main "$@"
