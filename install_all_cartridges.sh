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
if ! [[ $# -ge 1 &&  $# -le 3 ]] ; then
    echo "install_all_cartridges.sh takes 1 or 2 params + option value, provided $#:
    \$1: config ('debug', 'release', etc.)
    -i, --itest:  Pass this option to build an itest instead of a normal game cartridge."
    exit 1
fi

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

# cartridges.txt lists cartridge names, one line per cartridge
# newlines act like separators for iteration just like spaces,
# so this is equivalent to `cartridge_list="titlemenu stage_intro ..."`
cartridge_list=`cat "$data_path/cartridges.txt"`

for cartridge in $cartridge_list; do
  "$game_scripts_path/install_single_cartridge.sh" "$cartridge" "$config" $options
done

"$game_scripts_path/install_data_cartridges_with_merging.sh" "$config"
