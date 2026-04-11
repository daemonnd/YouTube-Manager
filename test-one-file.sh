#!/bin/bash

export VIDSIFT_DATA_DIR="$HOME/.local/share/vidsift"
export VIDSIFT_CONFIG_DIR="$HOME/.config/vidsift"

./parse_config.sh <"$VIDSIFT_CONFIG_DIR/config.jsonc" >"$VIDSIFT_DATA_DIR/parsed_config.json"
