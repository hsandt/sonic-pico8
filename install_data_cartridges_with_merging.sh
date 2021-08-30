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

# Copy data cartridges
echo "Copying data cartridges data/data_*.p8 in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp data/data_*.p8 "${install_dirpath}/"

# Since data_start_cinematic.p8 is the 17th cartridge, it would go out of the 16-cartridge limit,
# so we must merge its content (__gfx__ section) into one of the existing cartridges for which
# we don't care about __gfx__ data at runtime, i.e. the stage tilemap cartridges (__gfx__ are only useful
# to visualize tiles during edit). So we rebuild data_stage1_00.p8 from itself (preserving __map__, we can throw
# away the __gff__ since flags are taken from builtin data) and data_start_cinematic.p8 (__gfx__).
# This means that the data_stage1_00.p8 located in install dirpath (under carts/) is not the same as the data_stage1_00.p8
# located in the project's data folder. We could rename it data_stage1_00_with_start_cinematic_gfx.p8 but that would
# mess up the dynamic region cartridge loading system.
# Note that we've already copied data_stage1_00.p8 with the command above, so this will overwrite it.
echo "Merging data_start_cinematic.p8 __gfx__ with data_stage1_00.p8 __map__ into ${install_dirpath}/data_stage1_00.p8 ..."
build_merged_data_cmd="p8tool build --gfx data/data_start_cinematic.p8 --map data/data_stage1_00.p8 \"${install_dirpath}/data_stage1_00.p8\""
echo "> $build_merged_data_cmd"
bash -c "$build_merged_data_cmd"

# Now remove data_start_cinematic.p8 or it will be copied into ${cartridge_stem}_v${version}_${config}_cartridges folder
# on export, and zipped into the released archive for .p8 cartridges, being redundant with data_stage1_00.p8.
echo "Removing ${install_dirpath}/data_start_cinematic.p8 ..."
rm "${install_dirpath}/data_start_cinematic.p8"
