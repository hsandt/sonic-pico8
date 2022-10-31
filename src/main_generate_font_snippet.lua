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
  print("the quick brown")
  print("fox jumps over ")
  print("the lazy dog.")
  print("")
  print("THE QUICK BROWN")
  print("FOX JUMPS OVER")
  print("THE LAZY DOG?")
  print("")
  print("0123456789 +-*/")
  print("█▒🐱⬇️░✽●♥☉웃⌂⬅️😐")
  print("♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥")
  poke(0x5f58,0)
  color(13)
  print(" [snippet copied to clipboard]",0,120)
  cursor()
end
