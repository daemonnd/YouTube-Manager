#!/bin/bash
# main script
# executes and orchestrates all the others

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
    :
}

function main {
    while read -r url; do
        echo "$url"
    done < <(./url_collector.sh | ./url_validator.sh)
}

# call main with all args, as given
main "$@"
