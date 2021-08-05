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
  echo "Usage: build_single_cartridge.sh CARTRIDGE_SUFFIX [CONFIG] [OPTIONS]

ARGUMENTS
  CARTRIDGE_SUFFIX          Cartridge to build for the multi-cartridge game
                            See data/cartridges.txt for the list of cartridge names
                            A symbol equal to the cartridge suffix is always added
                            to the config symbols.

  CONFIG                    Build config. Determines defined preprocess symbols.
                            (default: 'debug')

  -i, --itest               Pass this option to build an itest instead of a normal game cartridge.

  -h, --help                Show this help message
"
}

# Default parameters
config='debug'
itest=false

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

# itest cartridges enforce special config 'itest' and ignore passed config
if [[ "$itest" == true ]]; then
  config='itest'
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
  # symbols='assert,tostring,dump,log,debug_menu,debug_character'
  # symbols='tostring,dump,log,debug_menu,debug_character,cheat'
  # symbols='debug_menu,debug_character,cheat'
  symbols='tostring,dump,debug_character,debug_menu,debug_collision_mask,cheat'
elif [[ $config == 'debug-ultrafast' ]]; then
  symbols='assert,tostring,dump,log,cheat,ultrafast'
elif [[ $config == 'cheat' ]]; then
  # symbols='cheat,tostring,dump,log,debug_menu'
  symbols='cheat,tostring,dump,debug_menu'
elif [[ $config == 'tuner' ]]; then
  symbols='tuner,mouse'
elif [[ $config == 'ultrafast' ]]; then
  symbols='ultrafast'
elif [[ $config == 'cheat-ultrafast' ]]; then
  symbols='cheat,ultrafast,debug_menu'
elif [[ $config == 'sandbox' ]]; then
  symbols='assert,deprecated,sandbox'
elif [[ $config == 'assert' ]]; then
  # symbols='assert,tostring,dump'
  symbols='assert,tostring,debug_collision_mask'
elif [[ $config == 'profiler' ]]; then
  # symbols='profiler,debug_menu'
  # profiler is too heavy right now, cannot build, so use lightweight version
  symbols='profiler_lightweight,cheat'
elif [[ $config == 'recorder' ]]; then
  symbols='recorder,tostring,log'
elif [[ $config == 'itest' ]]; then
  # cheat needed to set debug motion mode; remove if not testing and you need to spare chars
  # symbols='itest,proto,tostring,cheat'
  symbols='itest,proto,tostring'
fi

# we always add a symbol for the cartridge suffix in case
#  we want to customize the build of the same script
#  depending on the cartridge it is built into
if [[ -n "$symbols" ]]; then
  # there was at least one symbol before, so add comma separator
  symbols+=","
fi
symbols+="$cartridge_suffix"

# Define builtin data to use (in most cases it's just the cartridge suffix)
if [[ $cartridge_suffix == 'attract_mode' ]]; then
  # attract mode reuses same data as ingame, so no need for dedicated data cartridge
  builtin_data_suffix="ingame"
  # we must also define the ingame symbols to have access to all ingame code
  # (as opposed to stage_intro / stage_clear code)
  symbols+=",ingame"
else
  if [[ $cartridge_suffix == 'ingame' ]]; then
    # add symbol #normal_mode to distinguish from attract_mode, as both define #ingame
    symbols+=",normal_mode"
  fi
  builtin_data_suffix="$cartridge_suffix"
fi

if [[ "$itest" == true ]]; then
  main_prefix='itest_'
  required_relative_dirpath="itests/${cartridge_suffix}"
  cartridge_extra_suffix='itest_all_'
else
  main_prefix=''
  required_relative_dirpath=''
  cartridge_extra_suffix=''
fi

# Build cartridges without version nor config appended to name
#  so we can use PICO-8 load() with a cartridge file name
#  independent from the version and config

# Build cartridge
# See data/cartridges.txt for the list of cartridge names
# metadata really counts for the entry cartridge (titlemenu)
"$picoboots_scripts_path/build_cartridge.sh"                              \
  "$game_src_path"                                                        \
  ${main_prefix}main_${cartridge_suffix}.lua                         \
  ${required_relative_dirpath}                                            \
  -d "$data_path/builtin_data_${builtin_data_suffix}.p8"                  \
  -M "$data_path/metadata.p8"                                             \
  -a "$author" -t "$title (${cartridge_extra_suffix}${cartridge_suffix})" \
  -p "$build_output_path"                                                 \
  -o "${cartridge_stem}_${cartridge_extra_suffix}${cartridge_suffix}"     \
  -c "$config"                                                            \
  --no-append-config                                                      \
  -s "$symbols"                                                           \
  --minify-level 3                                                        \
  --unify "_${cartridge_suffix}"

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Build failed, STOP."
  exit 1
fi
