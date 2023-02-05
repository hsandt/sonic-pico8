#!/bin/bash
# Open metadata.p8 for edit and save
# We exceptionally use a more advanced version of PICO-8 than officially supported
# so we can use the new `import -l` syntax
pico8_0.2.5e -run data/metadata.p8 $@
