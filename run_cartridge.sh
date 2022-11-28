#!/bin/bash

# Run game cartridge located in PICO-8 carts install folder with PICO-8 executable
# Must be called after build and install script for that cartridge suffix.

# Configuration: paths
data_path="$(dirname "$0")/data"
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"

# Configuration: cartridge
cartridge_stem="picosonic"
version=`cat "$data_path/version.txt"`

help() {
  echo "Run a PICO-8 cartridge with the passed config."
  usage
}

usage() {
  echo "Usage: run_cartridge.sh CARTRIDGE_SUFFIX [CONFIG] [OPTIONS]

ARGUMENTS
  CARTRIDGE_SUFFIX          Cartridge to run for the multi-cartridge game
                            See data/cartridges.txt for the list of cartridge names
                            A symbol equal to the cartridge suffix is always added
                            to the config symbols.

  CONFIG                    Run config. Determines defined preprocess symbols.
                            (default: 'debug')

  -i, --itest               Pass this option to run an itest instead of a normal game cartridge.

  -x, --headless            Pass this option to run PICO-8 in headless mode.

  -h, --help                Show this help message
"
}

# Default parameters
config='debug'
itest=false
headless=false

# Read arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# -gt 0 ]]; do
  case $1 in
    -i | --itest )
      itest=true
      shift # past argument
      ;;
    -x | --headless )
      headless=true
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

if [[ "$itest" == true ]]; then
  # itest cartridges enforce special config 'itest' and ignore passed config
  config='itest'
  cartridge_extra_suffix='itest_all_'
else
  cartridge_extra_suffix=''
fi

install_dirpath="${carts_dirpath}/picosonic/v${version}_${config}"

if [[ "$headless" == true ]]; then
  run_option='-x'
else
  run_option='-run'
fi

# in multi-cartridge games, we should always run in PICO-8 carts folder
#  because load() paths may be relative (in our case, inside picosonic/vX.Y)
#  and first cartridge path is only cd-ed into if somewhere inside carts/
# this means you must install the built cartridge before running
run_cmd="pico8 ${run_option} ${install_dirpath}/${cartridge_stem}_${cartridge_extra_suffix}${cartridge_suffix}.p8 -screenshot_scale 4 -gif_scale 4 -gif_len 60 $@"

# Support UNIX platforms without gnome-terminal by checking if the command exists
# If you `reload.sh` the game, the separate terminal allows you to keep watching the program output,
# but depending on your work environment it may not be needed (it is useful with Sublime Text as the output
# panel would get cleared on reload).
# https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
if hash gnome-terminal 2>/dev/null; then
	# gnome-terminal exists
	echo "> gnome-terminal -- bash -x -c \"$run_cmd\""
	gnome-terminal -- bash -x -c "$run_cmd"
else
	echo "> $run_cmd"
	bash -c "$run_cmd"
fi
