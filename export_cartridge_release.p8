pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- Run this commandline script with:
-- $ pico8 -x export_cartridge.p8

-- It will export .bin and .p8.png for the current game release
-- Make sure to ./build_game release && ./install_cartridges.sh first
-- Note that it will not warn if cartridge is not found.
-- Paths are relative to PICO-8 carts directory.

cd("picosonic/v5.0_release")

local entry_cartridge = "picosonic_titlemenu.p8"

local additional_cartridges_list = {
  "picosonic_ingame.p8",
  "picosonic_stage_clear.p8",
  "data_bgm1.p8",
  "data_stage1_00.p8", "data_stage1_10.p8", "data_stage1_20.p8",
  "data_stage1_01.p8", "data_stage1_11.p8", "data_stage1_21.p8",
  "data_stage1_runtime.p8"
}

-- prepare folder for png cartridges
mkdir("picosonic_v5.0_release.png")

-- load each additional cartridge to save it as png cartridge
--  in folder created above
-- the metadata label is used automatically for each
for cartridge_name in all(additional_cartridges_list) do
  load(cartridge_name)

  cd("picosonic_v5.0_release.png")
  save(cartridge_name..".png")
  cd("..")
end

-- load the entry cartridge (titlemenu) last, since we're going to use it for export
--  just after
load(entry_cartridge)

-- save as png cartridge
cd("picosonic_v5.0_release.png")
save(entry_cartridge..".png")
cd("..")

-- concatenate cartridge names with space separator with a very simplified version
--  of string.lua > joinstr_table that doesn't mind about adding an initial space
local additional_cartridges_string = ""
for cartridge_name in all(additional_cartridges_list) do
  additional_cartridges_string = additional_cartridges_string.." "..cartridge_name
end

-- exports are done via EXPORT, and can use a custom icon
--  instead of the .p8.png label
-- icon is a 16x16 square => -s 2 tiles wide
--  with top-left at sprite 160 (run1) => -i 160
--  on pink (color 14) background => -c 14
-- and most importantly we pass ingame, stage_clear and data files as additional cartridges
export("picosonic_v5.0_release.bin "..additional_cartridges_string.." -i 160 -s 2 -c 14")

mkdir("picosonic_v5.0_release.web")
cd("picosonic_v5.0_release.web")
export("picosonic_v5.0_release.html "..additional_cartridges_string.." -i 160 -s 2 -c 14")
cd("..")
