#!/bin/bash
# Install a specific cartridge and data cartridges to the default
#  PICO-8 carts location
# This is required if you changed data or build for the first time for a given config,
#  as install_single_cartridge.sh will not copy data along and is not reliable alone.

# Usage: install_single_cartridge_with_data.sh config [--itest]
#   cartridge_suffix  see data/cartridges.txt for the list of cartridge names
#   config            build config (e.g. 'debug' or 'release'. Default: 'debug')
#   -i, --itest       pass this option to build an itest instead of a normal game cartridge

# Currently only supported on Linux

# Configuration: paths
game_scripts_path="$(dirname "$0")"
data_path="$(dirname "$0")/data"

# check that source and output paths have been provided
if ! [[ $# -ge 1 &&  $# -le 3 ]] ; then
    echo "install_single_cartridge_with_data.sh takes 1 or 3 params + option value, provided $#:
    \$1: cartridge_suffix (see data/cartridges.txt for the list of cartridge names)
    \$2: config ('debug', 'release', etc. Default: 'debug')
    -i, --itest:  Pass this option to build an itest instead of a normal game cartridge."

    exit 1
fi

# Configuration: cartridge
version=`cat "$data_path/version.txt"`
cartridge_suffix="$1"; shift
config="$1"; shift
# ! This is a short version for the usual while-case syntax, but in counterpart
# ! it doesn't support reordering (--itest must be after config)
if [[ $1 == '-i' || $1 == '--itest' ]]; then
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

# note that we don't add the data/data_stage*.p8 cartridges because
# install_single_cartridge.sh for ingame will install all data cartridges anyway
# (and said script is really meant for built cartridges as it refers to build path)
"$game_scripts_path/install_single_cartridge.sh" "$cartridge_suffix" "$config" $options

# recompute same install dirpath as used in install_single_cartridge.sh
# (no need to mkdir -p "${install_dirpath}", it must have been created in said script)
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/picosonic/v${version}_${config}"

# Also copy data cartridges
echo "Copying data cartridges data/data_*.p8 in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp data/data_*.p8 "${install_dirpath}/"
