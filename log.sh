#!/bin/bash

# strict mode
set -Eeuo pipefail

# calculate the output mode with the -v and -s flags
function calc_output_mode {
    output_mode=$(($output_mode + $1))
}

# parse the args
# s = silent (no output except errors) output_mode=-1
# default (no s nor v): only prints errors and the current dir processed in the given file output_mode=0
# v = errors and info
# vv = errors, info and debug
function parse_flags {
    output_mode=0
    while getopts "sv" flag; do
        case "${flag}" in
        s) calc_output_mode -1 ;;
        v) calc_output_mode 1 ;;
        *) echo "The options are '-v' for verbose output and '-s' for silent output" && exit 1 ;;
        esac
    done
    shift "$((OPTIND - 1))"
    export ARGS="$@"
    export OUTPUT_MODE="$output_mode"
}

# logs the output depending on the output_mode
# args:
# 1. loglevel (DEBUG, INFO, WARNING, ERROR, CRITICAL)
# 2. logmessage
# 3. min. output_mode
#
# output modes for loglevels:
# CRITICAL: -2
# ERROR: -1
# WARNING: 0
# INFO: 1
# DEBUG 2
function log {
    case "$1" in
    "DEBUG")
        if [[ "$OUTPUT_MODE" -ge 2 ]]; then
            echo "${1}: $2"
        fi
        ;;
    "INFO")
        if [[ "$OUTPUT_MODE" -ge 1 ]]; then
            echo "${1}: $2"
        fi
        ;;
    "WARNING")
        if [[ "$OUTPUT_MODE" -ge 0 ]]; then
            echo "${1}: $2"
        fi
        ;;
    "ERROR")
        if [[ "$OUTPUT_MODE" -ge -1 ]]; then
            echo "${1}: $2"
        fi
        ;;
    "CRITICAL")
        if [[ "$OUTPUT_MODE" -ge -2 ]]; then
            echo "${1}: $2"
        fi
        ;;
    *) echo "Invalid loglevel: $1 Exiting..." && exit 1 ;;
    esac
}
