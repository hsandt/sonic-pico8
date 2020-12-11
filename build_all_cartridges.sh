#!/bin/bash

# Build all game cartridges.
# This essentially calls build_single_cartridge.sh on each cartridge.

# Configuration: paths
game_scripts_path="$(dirname "$0")"

help() {
  echo "Build a PICO-8 cartridge with the passed config."
  usage
}

usage() {
  echo "Usage: build_all_cartridges.sh CARTRIDGE_SUFFIX [CONFIG]

ARGUMENTS
  CONFIG                    Build config. Determines defined preprocess symbols.
                            (default: 'debug')

  -h, --help                Show this help message
"
}

# Default parameters
config='debug'

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
roots=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help )
      help
      exit 0
      ;;
    -* )    # unknown option
      echo "Unknown option: '$1'"
      usage
      exit 1
      ;;
    * )     # store positional argument for later
      positional_args+=("$1")
      shift # past argument
      ;;
  esac
done

if ! [[ ${#positional_args[@]} -ge 0 && ${#positional_args[@]} -le 1 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 0 or 1."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

if [[ ${#positional_args[@]} -ge 1 ]]; then
  config="${positional_args[0]}"
fi

cartridge_list="titlemenu ingame stage_clear"

for cartridge in $cartridge_list; do
  "$game_scripts_path/build_single_cartridge.sh" "$cartridge" "$config"
done
