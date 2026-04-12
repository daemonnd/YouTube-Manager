#!/bin/bash

export VIDSIFT_DATA_DIR="$HOME/.local/share/vidsift"
export VIDSIFT_CONFIG_DIR="$HOME/.config/vidsift"
export VIDSIFT_HELPER_SCRIPTS_DIR="$HOME/.local/lib/vidsift/"
export VIDSIFT_BIN_DIR="$HOME/.local/bin/"
export OUTPUT_MODE=2

./parse_config.sh <"$VIDSIFT_CONFIG_DIR/config.jsonc" >"$VIDSIFT_DATA_DIR/parsed_config.json"
