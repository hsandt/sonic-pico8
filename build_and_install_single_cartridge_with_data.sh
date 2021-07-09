#!/bin/bash

# Build a specific cartridge for the game and install it with data cartridges in PICO-8 carts folder
#  to allow playing with multiple cartridges and newest data.

# Currently only supported on Linux

# Configuration: paths
game_scripts_path="$(dirname "$0")"

help() {
  echo "Build a PICO-8 cartridge with the passed config."
  usage
}

usage() {
  echo "Usage: build_and_install_single_cartridge_with_data.sh CARTRIDGE_SUFFIX [CONFIG]

ARGUMENTS
  CARTRIDGE_SUFFIX          Cartridge to build for the multi-cartridge game
                            See data/cartridges.txt for the list of cartridge names

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

if ! [[ ${#positional_args[@]} -ge 1 && ${#positional_args[@]} -le 2 ]]; then
  echo "Wrong number of positional arguments: found ${#positional_args[@]}, expected 1 or 2."
  echo "Passed positional arguments: ${positional_args[@]}"
  usage
  exit 1
fi

if [[ ${#positional_args[@]} -ge 1 ]]; then
  cartridge_suffix="${positional_args[0]}"
fi

if [[ ${#positional_args[@]} -ge 2 ]]; then
  config="${positional_args[1]}"
fi

if [[ "$itest" == true ]]; then
  # itest cartridges enforce special config 'itest' and ignore passed config
  config='itest'
  options='--itest'
else
  options=''
fi

# Immediately export to carts to allow multi-cartridge loading
"$game_scripts_path/build_single_cartridge.sh" "$cartridge_suffix" "$config" $options

if [[ $? -ne 0 ]]; then
  echo ""
  echo "build_single_cartridge.sh failed, STOP."
  exit 1
fi

"$game_scripts_path/install_single_cartridge_with_data.sh" "$cartridge_suffix" "$config" $options
