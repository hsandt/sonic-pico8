#!/bin/bash

# Run game cartridge located in PICO-8 carts install folder with PICO-8 executable
# Must be called after build and install script for that cartridge suffix.
# Usage: run_game.sh cartridge_suffix config [extra]
#   cartridge_suffix  see data/cartridges.txt for the list of cartridge names
#   config            build config (e.g. 'debug' or 'release')

# Any extra arguments are passed to pico8
# Currently only supported on Linux

# Configuration: paths
data_path="$(dirname "$0")/data"

# Configuration: cartridge
cartridge_stem="picosonic"
version=`cat "$data_path/version.txt"`

# shift allows to pass extra arguments as $@
cartridge_suffix="$1"; shift
config="$1"; shift
# ! This is a short version for the usual while-case syntax, but in counterpart
# ! it doesn't support reordering (--itest must be after config)
if [[ $1 == '-i' || $i == '--itest' ]]; then
  itest=true
  shift
fi

if [[ "$itest" == true ]]; then
  # itest cartridges enforce special config 'itest' and ignore passed config
  config='itest'
  cartridge_extra_suffix='itest_all_'
else
  cartridge_extra_suffix=''
fi

carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/picosonic/v${version}_${config}"

# in multi-cartridge games, we should always run in PICO-8 carts folder
#  because load() paths may be relative (in our case, inside picosonic/vX.Y)
#  and first cartridge path is only cd-ed into if somewhere inside carts/
# this means you must install the built cartridge before running
run_cmd="pico8 -run ${install_dirpath}/${cartridge_stem}_${cartridge_extra_suffix}${cartridge_suffix}.p8 -screenshot_scale 4 -gif_scale 4 -gif_len 60 $@"

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
