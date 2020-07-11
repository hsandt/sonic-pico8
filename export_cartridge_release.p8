pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- Run this commandline script with:
-- $ pico8 -x export_cartridge.p8

-- It will export .bin and .p8.png for the current game release
-- Make sure to ./build_game release && ./install_cartridge_linux.sh first
-- Note that it will note warn if cartridge is not found.
-- Paths are relative to PICO-8 carts directory.

cd("picosonic")
load("picosonic_v3.0_release.p8")
-- icon is a 16x16 square => -s 2 tiles wide
-- with top-left at sprite 2 => -i 2
-- on pink (color 14) background => -c 14
export("picosonic_v3.0_release.bin -i 2 -s 2 -c 14")
