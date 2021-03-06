#!/bin/bash

# Build a specific cartridge for the game
# It relies on pico-boots/scripts/build_cartridge.sh
# It also defines game information and defined symbols per config.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_src_path="$(dirname "$0")/src"
data_path="$(dirname "$0")/data"
build_dir_path="$(dirname "$0")/build"

# Configuration: cartridge
version=`cat "$data_path/version.txt"`
author="leyn"
cartridge_stem="picosonic"
title="pico sonic v$version"

help() {
  echo "Build a PICO-8 cartridge with the passed config."
  usage
}

usage() {
  echo "Usage: build_single_cartridge.sh CARTRIDGE_SUFFIX [CONFIG]

ARGUMENTS
  CARTRIDGE_SUFFIX          Cartridge to build for the multi-cartridge game
                            'titlemenu', 'stage_intro', 'ingame' or 'stage_clear'
                            A symbol equal to the cartridge suffix is always added
                            to the config symbols.

  CONFIG                    Build config. Determines defined preprocess symbols.
                            (default: 'debug')

  -h, --help                Show this help message
"
}

# Default parameters
config='debug'

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
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

# Define build output folder from config
# (to simplify cartridge loading, cartridge files are always named the same,
#  so we can only distinguish builds by their folder names)
build_output_path="${build_dir_path}/v${version}_${config}"

# Define symbols from config
symbols=''

if [[ $config == 'debug' ]]; then
  # symbols='assert,deprecated,log,visual_logger,tuner,profiler,mouse,cheat,sandbox'
  # lighter config (to remain under 65536 chars)
  symbols='assert,tostring,dump,log,debug_menu,debug_character'
elif [[ $config == 'debug-ultrafast' ]]; then
  symbols='assert,tostring,dump,log,cheat,ultrafast'
elif [[ $config == 'cheat' ]]; then
  # symbols='cheat,tostring,dump,log,debug_menu'
  symbols='assert,cheat,debug_menu'
elif [[ $config == 'tuner' ]]; then
  symbols='tuner,mouse'
elif [[ $config == 'ultrafast' ]]; then
  symbols='ultrafast'
elif [[ $config == 'cheat-ultrafast' ]]; then
  symbols='cheat,ultrafast,debug_menu'
elif [[ $config == 'sandbox' ]]; then
  symbols='assert,deprecated,sandbox'
elif [[ $config == 'assert' ]]; then
  symbols='assert,tostring,dump'
elif [[ $config == 'profiler' ]]; then
  symbols='profiler,cheat'
fi

# we always add a symbol for the cartridge suffix in case
#  we want to customize the build of the same script
#  depending on the cartridge it is built into
if [[ -n "$symbols" ]]; then
  # there was at least one symbol before, so add comma separator
  symbols+=","
fi
symbols+="$cartridge_suffix"

# Build cartridges without version nor config appended to name
#  so we can use PICO-8 load() with a cartridge file name
#  independent from the version and config

# Build cartridge ('titlemenu', 'stage_intro', 'ingame' or 'stage_clear')
# metadata really counts for the entry cartridge (titlemenu)
"$picoboots_scripts_path/build_cartridge.sh"          \
  "$game_src_path" main_${cartridge_suffix}.lua       \
  -d "$data_path/builtin_data_${cartridge_suffix}.p8" \
  -M "$data_path/metadata.p8"                         \
  -a "$author" -t "$title ($cartridge_suffix)"        \
  -p "$build_output_path"                             \
  -o "${cartridge_stem}_${cartridge_suffix}"          \
  -c "$config"                                        \
  --no-append-config                                  \
  -s "$symbols"                                       \
  --minify-level 3                                    \
  --unify "_${cartridge_suffix}"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Build failed, STOP."
  exit 1
fi
