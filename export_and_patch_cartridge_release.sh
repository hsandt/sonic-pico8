#!/bin/bash

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
data_path="$(dirname "$0")/data"
# Linux only
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"

# Configuration: cartridge
version=`cat "$data_path/version.txt"`
export_folder="picosonic/v${version}_release"
cartridge_basename="picosonic_v${version}_release"
bin_folder="$carts_dirpath/$export_folder/${cartridge_basename}.bin"

# Export via PICO-8 editor
pico8 -x export_cartridge_release.p8

# Patch the runtime binaries with 4x_token and fast_reload
patch_cmd="\"$picoboots_scripts_path/patch_pico8_runtime.sh\" \"$bin_folder/linux/$cartridge_basename\""
echo "> $patch_cmd"
bash -c "$patch_cmd"
