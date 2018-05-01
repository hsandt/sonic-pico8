#!/bin/bash
mkdir -p build
p8tool build --lua src/main.lua --gfx data/data.p8 --gff data/data.p8 --map data/data.p8 --sfx data/data.p8 --music data/data.p8 build/game.p8
