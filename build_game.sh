#!/bin/bash

# This is essentially a proxy script for pico-boots/scripts/build_cartridge.sh.
# However, this is also where you define game information and defined symbols per config.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_src_path="$(dirname "$0")/src"
data_path="$(dirname "$0")/data"
build_output_path="$(dirname "$0")/build"

# Configuration: cartridge
author="hsandt"
title="pico-sonic"
cartridge_stem="picosonic"
version="3.2"

help() {
  echo "Build a PICO-8 cartridge with the passed config."
  usage
}

usage() {
  echo "Usage: test.sh [CONFIG]

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

# Define symbols from config
symbols=''

if [[ $config == 'debug' ]]; then
  # symbols='assert,deprecated,log,visual_logger,tuner,profiler,mouse,cheat,sandbox'
  # lighter config (to remain under 65536 chars)
  symbols='assert,deprecated,log,cheat,sandbox'
elif [[ $config == 'debug-ultrafast' ]]; then
  symbols='assert,deprecated,log,cheat,sandbox,ultrafast'
elif [[ $config == 'cheat' ]]; then
  symbols='assert,deprecated,cheat'
elif [[ $config == 'ultrafast' ]]; then
  symbols='assert,deprecated,ultrafast'
elif [[ $config == 'cheat-ultrafast' ]]; then
  symbols='assert,deprecated,cheat,ultrafast'
elif [[ $config == 'sandbox' ]]; then
  symbols='assert,deprecated,sandbox'
elif [[ $config == 'assert' ]]; then
  symbols='assert'
elif [[ $config == 'profiler' ]]; then
  symbols='profiler'
fi

# Build from main
"$picoboots_scripts_path/build_cartridge.sh"          \
  "$game_src_path" main.lua                           \
  -d "$data_path/data.p8" -M "$data_path/metadata.p8" \
  -a "$author" -t "$title"                            \
  -p "$build_output_path"                             \
  -o "${cartridge_stem}_v${version}"                  \
  -c "$config"                                        \
  -s "$symbols"                                       \
  --minify-level 2
