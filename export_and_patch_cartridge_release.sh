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
web_folder="$carts_dirpath/$export_folder/${cartridge_basename}.web"

# Cleanup bin folder as a bug in PICO-8 makes it accumulate files in .zip for each export (even homonymous files!)
rm -rf "$bin_folder"

# Export via PICO-8 editor
pico8 -x export_game_release.p8

# Patch the runtime binaries in-place with 4x_token, fast_reload, fast_load (experimental) if available
patch_bin_cmd="\"$picoboots_scripts_path/patch_pico8_runtime.sh\" --inplace \"$bin_folder\" \"$cartridge_basename\""
echo "> $patch_bin_cmd"
bash -c "$patch_bin_cmd"

# Patch the html export in-place with 4x_token, fast_reload
js_filepath="${web_folder}/${cartridge_basename}.js"
patch_js_cmd="python3.6 \"$picoboots_scripts_path/patch_pico8_js.py\" \"$js_filepath\" \"${js_filepath}\""
echo "> $patch_js_cmd"
bash -c "$patch_js_cmd"
