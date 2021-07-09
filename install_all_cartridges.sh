#!/bin/bash
# Install all cartridges for the game, including data cartridges, to the default
#  PICO-8 carts location
# This is required if you need to play with multiple carts,
#  as other carts will only be loaded in PICO-8 carts location

# Usage: install_all_cartridges.sh config [--itest]
#   config            build config (e.g. 'debug' or 'release')
#   -i, --itest       pass this option to build an itest instead of a normal game cartridge

# Currently only supported on Linux

# Configuration: paths
game_scripts_path="$(dirname "$0")"
data_path="$(dirname "$0")/data"

# check that source and output paths have been provided
if ! [[ $# -ge 1 &&  $# -le 2 ]] ; then
    echo "build.sh takes 1 or 2 params, provided $#:
    \$1: config ('debug', 'release', etc.)
    -i, --itest:  Pass this option to build an itest instead of a normal game cartridge."
    exit 1
fi

# Configuration: cartridge
cartridge_stem="picosonic"
version=`cat "$data_path/version.txt"`
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
  options='--itest'
else
  options=''
fi

# cartridges.txt lists cartridge names, one line per cartridge
# newlines act like separators for iteration just like spaces,
# so this is equivalent to `cartridge_list="titlemenu stage_intro ..."`
cartridge_list=`cat "$data_path/cartridges.txt"`

for cartridge in $cartridge_list; do
  "$game_scripts_path/install_single_cartridge.sh" "$cartridge" "$config" "$suffix" $options
done

# recompute same install dirpath as used in install_single_cartridge.sh
# (no need to mkdir -p "${install_dirpath}", it must have been created in said script)
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/${cartridge_stem}/v${version}_${config}"

# Also copy data cartridges
echo "Copying data cartridges data/data_*.p8 in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp data/data_*.p8 "${install_dirpath}/"
