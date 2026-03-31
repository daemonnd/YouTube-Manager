#!/bin/bash
# File for removing comments from the config file, so that it can be parsed by jq

# strict mode
set -Eeuo pipefail

# Cleanup function
function cleanup {
    local exit_code="$?"
    echo "Script parse_config.sh interrupted or failed. Cleaning up..."

    # remove tmp files

    # exit the script, preserving the exit code
    exit "$exit_code"
}

# trap errors
trap 'echo "Error on line $LINENO in parse_config.sh: command \"$BASH_COMMAND\" exited with status $?" >&2' ERR
# trap signals
trap 'cleanup' INT TERM ERR

function check_args {
    echo
}

function main {
    cat /dev/stdin | awk ' {
    gsub(/\/\/.*/, "") 
    print $0
    }
    ' | envsubst
}
# call main with all args, as given
main "$@"
