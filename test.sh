#!/bin/bash

# Copied from pico-boots-demo/test.sh

# Configuration
game_src_path="$(dirname "$0")/src"
game_config_path="$(dirname "$0")/config"
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"

help() {
  echo "Test game modules with busted

This is essentially a proxy script for pico-boots/scripts/test_scripts.sh that avoids
passing src/FOLDER every time we want to test a group of scripts in the game.

It doesn't prepend the engine path though, so if you want to test engine folders easily,
use pico-boots/test.sh instead.

Dependencies:
- busted (must be in PATH)
- luacov (must be in PATH)
"
  usage
}

usage() {
  echo "Usage: test.sh [FOLDER-1 [FOLDER-2 [...]]]

ARGUMENTS
  FOLDER                    Path to game folder to test.
                            Path is relative to src. Sub-folders are supported.
                            (optional)

  -h, --help                Show this help message
"
}

# Default parameters
folders=()
other_options=()

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
roots=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help )
      help
      exit 0
      ;;
    -* )    # we started adding options
            # since we don't support "--" for final positional arguments, just pass all the rest to test_scripts.sh
      break
      ;;
    * )     # positional argument: folder
      folders+=("$1")
      shift # past argument
      ;;
  esac
done

if [[ ${#folders[@]} -ne 0 ]]; then
  # Paths are relative to game src, so prepend it before passing to actual test script
  for folder in "${folders[@]}"; do
    roots+=("\"$game_src_path/$folder\"")
  done
else
  # No folder passed, test the whole game folder
  roots=("\"$game_src_path\"")
fi

# Add extra lua root 'src' to enable require for game scripts
"$picoboots_scripts_path/test_scripts.sh" ${roots[@]} --lua-root src -c "$game_config_path/.luacov_game" $@
