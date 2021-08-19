#!/bin/bash

# Build all game cartridges, including data cartridges and install them in PICO-8 carts folder.

# Currently only supported on Linux.

# Configuration: paths
game_scripts_path="$(dirname "$0")"

help() {
  echo "Build and install all PICO-8 cartridges with the passed config."
  usage
}

usage() {
  echo "Usage: build_and_install_all_cartridges.sh [CONFIG] [OPTIONS]

ARGUMENTS
  CONFIG                    Build config. Determines defined preprocess symbols.
                            (default: 'debug')

  -i, --itest               Pass this option to build an itest instead of a normal game cartridge.

  -h, --help                Show this help message
"
}

# Default parameters
config='debug'

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# -gt 0 ]]; do
  case $1 in
    -i | --itest )
      itest=true
      shift # past argument
      ;;
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

if [[ "$itest" == true ]]; then
  # itest cartridges enforce special config 'itest' and ignore passed config
  config='itest'
  options='--itest'
else
  options=''
fi

"$game_scripts_path/build_all_cartridges.sh" "$config" $options
"$game_scripts_path/install_all_cartridges.sh" "$config" $options
