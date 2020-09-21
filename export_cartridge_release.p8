pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- Run this commandline script with:
-- $ pico8 -x export_cartridge.p8

-- It will export .bin and .p8.png for the current game release
-- Make sure to ./build_game release && ./install_cartridges.sh first
-- Note that it will not warn if cartridge is not found.
-- Paths are relative to PICO-8 carts directory.

cd("picosonic/v4.1_release")

-- first, load ingame cartridge just to save the png cartridge
--  before we load something else
-- the metadata label is used automatically
load("picosonic_ingame.p8")
save("picosonic_ingame.p8.png")

-- second, load the entry cartridge (titlemenu)
load("picosonic_titlemenu.p8")

-- save png cartridge
save("picosonic_titlemenu.p8.png")

-- other exports are done via EXPORT, and can use a custom icon
--  instead of the .p8.png label
-- icon is a 16x16 square => -s 2 tiles wide
--  with top-left at sprite 2 => -i 2
--  on pink (color 14) background => -c 14
-- and most importantly we pass ingame as second cartridge
export("picosonic_v4.1_release.bin picosonic_ingame.p8 -i 2 -s 2 -c 14")
export("picosonic_v4.1_release.html picosonic_ingame.p8 -i 2 -s 2 -c 14")
