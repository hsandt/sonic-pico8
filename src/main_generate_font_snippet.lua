-- main entry file for the generate_font_snippet cartridge
--  game states: none, it's a custom cartridge run offline to generate a font snippet from a font spritesheet

-- USAGE
-- 1. Edit spritesheets/picosonic_custom_font.png
-- 2. Run
-- $ ./copy_spritesheet_for_import.sh picosonic_custom_font && pico8 -run data/builtin_data_generate_font_snippet.p8
-- (Sublime Text command: "Game: edit data (gfx only): custom font")
-- to let it import the spritesheet
-- 3. Save the cart
-- 4. Run (we recommend assert config)
-- $ ./build_and_install_single_cartridge_with_data.sh generate_font_snippet assert && ./run_cartridge.sh generate_font_snippet assert
-- (Sublime Text command: "Game: build and run generate_font_snippet (offline)")
-- You will see a message stating that the font snippet was saved in the clipboard
-- 6. Open the source file that needs the custom font (stage_clear_state.lua) and paste the font snippet under #custom_font
-- 7. Locate char_width_table under #custom_font_width, and fill it as necessary (for characters not using default_char_width)

-- must require at main top, to be used in any required modules from here
require("engine/common")
require("common_generate_font_snippet")

require("engine/ui/font_snippet")

local text_helper = require("engine/ui/text_helper")


-- this must match value in stage_clear_state.lua
local default_char_width = 5


function _init()
  memset(0x5600,0,0x800)
  -- most characters have width 4, so 5 with space
  -- we'll still need to use text codes to adjust width individually for thinner/wider characters
  local s=load_from_sprites(default_char_width)
  printh(s,"@clip")
end

function _draw()
  cls(1)

  poke(0x5f58,0x81)
  color(7)
  -- in real game, we should replace the characters as part of some pre-build string replacement
  -- to inject the proper custom character width codes
  -- (see stage_clear_state.lua > default_char_width, char_width_table, to_custom_font
  -- which itself uses font_helper.to_custom_font_with_adjusted_char_width)
  api.print("\^x4t\^x5he \^x9q\^x5u\^x2i\^x5ck \^x6br\^x9o\^x8w\^x6n")
  api.print("fox jumps over ")
  api.print("the lazy dog.")
  api.print("")
  api.print("THE QUICK BROWN")
  api.print("FOX JUMPS OVER")
  api.print("THE LAZY DOG?")
  api.print("")
  api.print("0123456789 +-*/")

  -- uncomment to test glyphs
  -- api.print("█▒🐱⬇️░✽●♥☉웃⌂⬅️😐")
  -- api.print("♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥")

  poke(0x5f58,0)

  -- test multi-line (we made sure to clear permanent use custom font byte above
  -- so \14 is required on each line)
  text_helper.print_aligned("\14hello\n\14world!", 64, 100, alignments.center, colors.blue, nil, true)

  color(13)
  api.print(" [snippet copied to clipboard]",0,120)
  cursor()
end
