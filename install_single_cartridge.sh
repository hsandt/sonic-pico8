#!/bin/bash
# Install a specific cartridge for the game to the default
#  PICO-8 carts location
# This is required if you need to play with multiple carts,
#  as other carts will only be loaded in PICO-8 carts location
# ! This does not install data and is not useful on its own,
#  make sure to use install_single_cartridge_with_data.sh or
#  to manually copy data cartridges after this.

# Usage: install_single_cartridge.sh cartridge_suffix config [--itest]
#   cartridge_suffix  see data/cartridges.txt for the list of cartridge names
#   config            build config (e.g. 'debug' or 'release'. Default: 'debug')
#   -i, --itest       pass this option to build an itest instead of a normal game cartridge

# Currently only supported on Linux

# Configuration: paths
data_path="$(dirname "$0")/data"

# check that source and output paths have been provided
if ! [[ $# -ge 1 &&  $# -le 4 ]] ; then
    echo "install_single_cartridge.sh takes 1 to 3 params + option value, provided $#:
    \$1: cartridge_suffix (see data/cartridges.txt for the list of cartridge names)
    \$2: config ('debug', 'release', etc. Default: 'debug')
    -i, --itest:  Pass this option to build an itest instead of a normal game cartridge."
    exit 1
fi

# Configuration: cartridge
cartridge_stem="picosonic"
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
  cartridge_extra_suffix='itest_all_'
else
  cartridge_extra_suffix=''
fi

output_path="build/v${version}_${config}"
cartridge_filepath="${output_path}/${cartridge_stem}_${cartridge_extra_suffix}${cartridge_suffix}.p8${suffix}"
# Linux only
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/${cartridge_stem}/v${version}_${config}"

if [[ ! -f "${cartridge_filepath}" ]]; then
  echo "File ${cartridge_filepath} could not be found, cannot install. Make sure you built it first."
  exit 1
fi

mkdir -p "${install_dirpath}"

echo "Installing ${cartridge_filepath} in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp "${cartridge_filepath}" "${install_dirpath}/"

echo "Done."
