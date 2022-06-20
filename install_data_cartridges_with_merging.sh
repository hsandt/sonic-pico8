#!/bin/bash
# Install data cartridges to the default PICO-8 carts location,
#  merging data sections when needed to have 16 cartridges maximum.
# This should be done as part of install cartridge with data, or after editing data.

# Usage: install_data_cartridges_with_merging.sh config
#   config            build config (e.g. 'debug' or 'release'. Default: 'debug')

# Currently only supported on Linux

# check that source and output paths have been provided
if ! [[ $# == 1 ]] ; then
    echo "install_single_cartridge_with_data.sh takes 1 param, provided $#:
    \$1: config ('debug', 'release', etc. Default: 'debug')"

    exit 1
fi

# Configuration: paths
data_path="$(dirname "$0")/data"

# Configuration: cartridge
cartridge_stem="picosonic"
version=`cat "$data_path/version.txt"`
config="$1"; shift

# recompute same install dirpath as used in install_single_cartridge.sh
# (no need to mkdir -p "${install_dirpath}", it must have been created in said script)
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/${cartridge_stem}/v${version}_${config}"

# Copy data cartridges (but not extra gfx cartridges)
echo "Copying data cartridges data/data_*.p8 in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp data/data_*.p8 "${install_dirpath}/"

# We've already reached the max limit of 16 cartridges, so we must add additional gfx cartridges by
# merging their content (__gfx__ section) into one of the existing cartridges for which
# we don't care about __gfx__ data at runtime, i.e. the stage tilemap cartridges (their original __gfx__ are only useful
# to visualize tiles during edit).
# So we rebuild data_stage1_xx.p8 from itself (preserving __map__, we can throw away the __gff__ since flags are taken
# from builtin data) and gfx_ extra data files (__gfx__ section).
# This means that the data_stage1_xx.p8 files located in install dirpath (under carts/) may not be the same as the data_stage1_xx.p8
# located in the project's data folder. We could rename them, but that would mess up with the dynamic region cartridge loading system.
# Note that we've already copied data_stage1_xx.p8 with the command above, so this will overwrite them.

# Merging list
# data_stage1_00.p8 + gfx_start_cinematic.p8 = data_stage1_00.p8 for release
# data_stage1_01.p8 + gfx_splash_screen.p8 = data_stage1_00.p8 for release

echo "Merging gfx_start_cinematic.p8 __gfx__ with data_stage1_00.p8 __map__ into ${install_dirpath}/data_stage1_00.p8 ..."
build_merged_gfx_start_cinematic_cmd="p8tool build --gfx data/gfx_start_cinematic.p8 --map data/data_stage1_00.p8 \"${install_dirpath}/data_stage1_00.p8\""
echo "> $build_merged_gfx_start_cinematic_cmd"
bash -c "$build_merged_gfx_start_cinematic_cmd"

echo "Merging gfx_splash_screen.p8 __gfx__ with data_stage1_01.p8 __map__ into ${install_dirpath}/data_stage1_01.p8 ..."
build_merged_gfx_splash_screen_cmd="p8tool build --gfx data/gfx_splash_screen.p8 --map data/data_stage1_01.p8 \"${install_dirpath}/data_stage1_01.p8\""
echo "> $build_merged_gfx_splash_screen_cmd"
bash -c "$build_merged_gfx_splash_screen_cmd"
