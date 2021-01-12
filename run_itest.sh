#!/bin/bash

# Run itest with PICO-8 executable

# Usage: build_itest.sh cartridge_suffix
#   cartridge_suffix  'titlemenu', 'stage_intro', 'ingame' or 'stage_clear'

# Any extra arguments are passed to pico8

# Configuration: paths
data_path="$(dirname "$0")/data"

# Configuration: cartridge
cartridge_stem="picosonic_itest_all"
version=`cat "$data_path/version.txt"`

cartridge_suffix="$1"; shift

run_cmd="pico8 -run build/${cartridge_stem}_${cartridge_suffix}_v${version}_itest.p8 -screenshot_scale 4 -gif_scale 4 $@"

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
