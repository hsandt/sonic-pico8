-- main entry file for the generate_font_snippet cartridge
--  game states: none, it's a custom cartridge run offline to generate a font snippet from a font spritesheet
-- after running it, the font snippet will be saved in the clipboard, just paste it in the script that needs it

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_generate_font_snippet")

require("ui/font_snippet")

function _init()
  memset(0x5600,0,0x800)
  local s=load_from_sprites()
  printh(s,"@clip")
end

function _draw()
  cls(1)

  poke(0x5f58,0x81)
  color(7)
  api.print("the quick brown")
  api.print("fox jumps over ")
  api.print("the lazy dog.")
  api.print("")
  api.print("THE QUICK BROWN")
  api.print("FOX JUMPS OVER")
  api.print("THE LAZY DOG?")
  api.print("")
  api.print("0123456789 +-*/")
  api.print("█▒🐱⬇️░✽●♥☉웃⌂⬅️😐")
  api.print("♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥")
  poke(0x5f58,0)
  color(13)
  api.print(" [snippet copied to clipboard]",0,120)
  cursor()
end
