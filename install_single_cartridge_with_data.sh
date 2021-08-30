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

"$game_scripts_path/install_single_cartridge.sh" "$cartridge_suffix" "$config" $options

"$game_scripts_path/install_data_cartridges_with_merging.sh" "$config"
