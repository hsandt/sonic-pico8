#!/bin/bash

# Build a specific cartridge for the game
# It relies on pico-boots/scripts/build_cartridge.sh
# It also defines game information and defined symbols per config.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_prebuild_path="$(dirname "$0")/prebuild"
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

# Required positional arguments
cartridge_suffix="${positional_args[0]}"

# Optional positional arguments
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

# Note that config is not automatically added as symbol by build_cartridge.sh,
# so we manually add a symbol corresponding to the config at the beginning of each symbols list
# (or two symbols for compounded-configs)
if [[ $config == 'debug' ]]; then
  # symbols='assert,deprecated,log,visual_logger,tuner,profiler,mouse,cheat,sandbox'
  # lighter config (to remain under 65536 chars)
  # symbols='assert,tostring,dump,log,debug_menu,debug_character'
  # symbols='tostring,dump,log,debug_menu,debug_character,cheat'
  # symbols='debug_menu,debug_character,cheat'
  symbols='debug,tostring,dump,debug_character,debug_menu,debug_collision_mask,cheat,pfx'
elif [[ $config == 'debug-ultrafast' ]]; then
  symbols='debug,ultrafast,assert,tostring,dump,log,cheat'
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
  # symbols='assert,deprecated,sandbox'
  symbols='sandbox,assert,tuner,mouse'
elif [[ $config == 'assert' ]]; then
  # symbols='assert,tostring,dump'
  symbols='assert,tostring,log,debug_collision_mask'
elif [[ $config == 'profiler' ]]; then
  # for stage intro and others, full profiler fits
  symbols='profiler,debug_menu'
  # profiler is too heavy in ingame, cannot build, so use lightweight version
  # however, Ctrl+P gives even more information without overhead, so prefer this
  # symbols='profiler_lightweight,cheat'
elif [[ $config == 'recorder' ]]; then
  symbols='recorder,tostring,log'
elif [[ $config == 'itest' ]]; then
  # cheat needed to set debug motion mode; remove if not testing and you need to spare chars
  # symbols='itest,proto,tostring,cheat'
  symbols='itest,proto,tostring'
elif [[ $config == 'release' ]]; then
  # usually release has no symbols except those that help making the code more compact
  # in this game project we define 'release' as a special symbol for that
  # most of the time, we could replace `#if release` with
  # `#if debug_option1 || debug_option2 || debug_option3 ` but the problem is that
  # 2+ OR statements syntax is not supported by preprocess.py yet
  symbols='release'
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
if [[ $cartridge_suffix == 'sandbox' ]]; then
  # uncomment to test Sonic sprites in sandbox (e.g. rotation)
  # data_filebasename="data_stage_sonic"
  data_filebasename="data_stage1_ingame"
elif [[ $cartridge_suffix == 'generate_gfx_sage_choir_pcm_data' ]]; then
  # no data at all, the cartridge's role is to generate gfx data from pcm string
  data_filebasename=""
else
  if [[ $cartridge_suffix == 'attract_mode' ]]; then
    # attract mode reuses same data as ingame, so no need for dedicated data cartridge
    builtin_data_suffix="ingame"
    # we must also define the ingame symbols to have access to all ingame code
    # (as opposed to stage_intro / stage_clear code)
    symbols+=",ingame"
  else
    if [[ $cartridge_suffix == 'ingame' ]]; then
      # add symbol #normal_mode to distinguish playable ingame from attract_mode,
      # as both define #ingame
      symbols+=",normal_mode"
    elif [[ $cartridge_suffix == 'titlemenu' ]]; then
      # titlemenu now uses new engine feature sprite_data:render parameter scale,
      # but ingame doesn't need it so we strip it unless #sprite_scale
      symbols+=",sprite_scale"
    fi
    builtin_data_suffix="$cartridge_suffix"
  fi

  if [[ $cartridge_suffix == 'stage_intro' ]]; then
    symbols+=",landing_anim,pfx"
  fi

  # uncomment to enable landing anim (without pfx)
  # for ingame (including attract_mode)
  # currently, it's slightly out of chars budget
  # if [[ $builtin_data_suffix == 'ingame' ]]; then
  #   symbols+=",landing_anim"
  # fi

  if [[ "$itest" == true ]]; then
    main_prefix='itest_'
    required_relative_dirpath="itests/${cartridge_suffix}"
    cartridge_extra_suffix='itest_all_'
    # Do NOT unify itest cartridges: they rely on [[add_require]] injection being done
    # after injecting the app into itest_run, and unification dismantles require order,
    # forgetting exact line positioning and only caring about file dependency order.
    unify_option=''
  else
    main_prefix=''
    required_relative_dirpath=''
    cartridge_extra_suffix=''
    unify_option="--unify _${cartridge_suffix}"
  fi
  data_filebasename="builtin_data_${builtin_data_suffix}"
fi

# only pass data option if there is data
if [[ -n "$data_filebasename" ]]; then
  data_option="-d \"${data_path}/${data_filebasename}.p8\""
else
  data_option=""
fi

# Define list of paths to modules containing constants to substitute at prebuild time,
# separated by space (Python argparse nargs='*')
game_constant_module_paths_string_prebuild="${game_src_path}/data/camera_data.lua \
${game_src_path}/data/playercharacter_numerical_data.lua \
${game_src_path}/data/stage_clear_data.lua \
${game_src_path}/data/stage_common_data.lua \
${game_src_path}/menu/splash_screen_phase.lua \
${game_src_path}/resources/audio.lua \
${game_src_path}/resources/memory.lua \
${game_src_path}/resources/visual_ingame_numerical_data.lua"

# Define list of paths to modules containing constants to substitute at postbuild time,
# separated by space (Python argparse nargs='*')
# This is for files containing special characters (such as Unicode strings) that may cause
# trouble with `p8tool listrawlua` done during minify step (just before this in post-build)
game_constant_module_paths_string_postbuild="${game_src_path}/data/pcm_data.lua"

# Build cartridges without version nor config appended to name
#  so we can use PICO-8 load() with a cartridge file name
#  independent from the version and config

# Build cartridge
# See data/cartridges.txt for the list of cartridge names
# metadata really counts for the entry cartridge (titlemenu)
"$picoboots_scripts_path/build_cartridge.sh"                                            \
  "$game_src_path"                                                                      \
  ${main_prefix}main_${cartridge_suffix}.lua                                            \
  ${required_relative_dirpath}                                                          \
  ${data_option}                                                                        \
  -M "$data_path/metadata.p8"                                                           \
  -a "$author" -t "$title (${cartridge_extra_suffix}${cartridge_suffix})"               \
  -p "$build_output_path"                                                               \
  -o "${cartridge_stem}_${cartridge_extra_suffix}${cartridge_suffix}"                   \
  -c "$config"                                                                          \
  --no-append-config                                                                    \
  -s "$symbols"                                                                         \
  --game-constant-module-paths-prebuild "$game_constant_module_paths_string_prebuild"   \
  --game-constant-module-paths-postbuild "$game_constant_module_paths_string_postbuild" \
  -r "$game_prebuild_path"                                                              \
  -v version="$version"                                                                 \
  --minify-level 3                                                                      \
  $unify_option

if [[ $? -ne 0 ]]; then
  echo ""
  echo "Build failed, STOP."
  exit 1
fi
