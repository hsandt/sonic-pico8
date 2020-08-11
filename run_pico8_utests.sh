#!/bin/bash

# Run itest with PICO-8 executable (itests only work in debug config)
# Pass any extra arguments to pico8

# Configuration: cartridge
cartridge_stem="picosonic_pico8_utests_all"
version="3.1"

run_cmd="pico8 -run build/${cartridge_stem}_v${version}_debug.p8 -screenshot_scale 4 -gif_scale 4 $@"

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
