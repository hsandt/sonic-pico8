pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- picosonic gfx-only data:
-- custom font by leyn

-- This data is never used directly by the game, it is instead built into the offline generate_font_snippet cartridge,
--  which is itself run to generate a font snippet saved in clipboard, and pasted by developer in the script that loads
--  the custom font.

-- Import latest font spritesheet. Open data with pico8 -run for it to run automatically on launch.
import "picosonic_custom_font.png"

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777700000000000000000000000000000000000000000000000000000000000777770000000000770007700000000000000000000000000000000000000000
77777700000000000000000000000000000000000000000000007700770000000770000000000000077077000000000000000000000000000000000000700000
77777700777777007777770077007700770077007700770000777700777700000770000000007700007770000000000000000000000000000707000007070000
77777700777777007700770000770000000000007700770077777700777777000770000000007700077777000007700000000000000000000707000000700000
77777700777777007777770077007700770077007700770000777700777700000770000000007700000700000000000000000000000000000000000000000000
77777700000000000000000000000000000000000000000000007700770000000000000000007700077777000000000000770000007700000000000000000000
77777700000000000000000000000000000000000000000000000000000000000000000007777700000700000000000000077000007700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007700000000000000000000000700000000000007770000007700000007700000770000000000000000000000000000000000000000000000000700
00000000007700000770770007707700077777007700770077077000007700000077000000077000077077000077000000000000000000000000000000007700
00000000007700000770770077777770770700000007700077077000000000000770000000007700007770000077000000000000000000000000000000077000
00000000007700000000000007707700077777000077000007770770000000000770000000007700777777707777770000000000077777000000000000770000
00000000007700000000000007707700000707700770000077077700000000000770000000007700007770000077000000000000000000000000000007700000
00000000000000000000000077777770077777007700770077077700000000000077000000077000077077000077000000770000000000000077000077000000
00000000007700000000000007707700000700000000000007770770000000000007700000770000000000000000000000770000000000000077000070000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000
07777700000770007777770077777700770077007777777007777700777777700777770007777700000000000000000000007700000000000770000007777000
77000770007770000000077000000770770077007700000077000000000007707700077077000770000000000000000000077000000000000077000077007700
77007770000770000000077000000770770077007700000077000000000077007700077077000770007700000077000000770000077770000007700000007700
77070770000770000777770000777700077777707777770077777700000770000777770007777770000000000000000007700000000000000000770000077000
77700770000770007700000000000770000077000000077077000770007700007700077000000770000000000000000000770000077770000007700000770000
77000770000770007700000000000770000077000000077077000770007700007700077000000770007700000077000000077000000000000077000000000000
07777700007777007777777077777700000077007777770007777700007700000777770007777700000000000770000000007700000000000770000000770000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007700000000000000000007700000000000777770000000007700000000000000000077007700000000770000000000000000000000000000
07777000000000007700000000000000000007700000000007700000000000007700000000077000000000007700000000770000000000000000000000000000
77007700077777007777770007777700077777700777770007700000077777707777770000000000000777007700770000770000770007707777770007777700
77077700000007707700077077000770770007707700077077777700770007707700077000777000000077007707700000770000777077707700077077000770
77077700077777707700077077000000770007707777777007700000770007707700077000077000000077007777000000770000777777707700077077000770
77000000770007707700077077000770770007707700000007700000077777707700077000077000000077007707700000770000770707707700077077000770
07777000077777707777770007777700077777700777770007700000000007707700077000777700770077007700770000077700770007707700077007777700
00000000000000000000000000000000000000000000000000000000077777000000000000000000077770000000000000000000000000000000000000000000
00000000000000000000000000000000007700000000000000000000000000000000000000000000000000000777770070000000077777000077000000000000
00000000000000000000000000000000007700000000000000000000000000000000000000000000000000000770000077000000000077000777700000000000
77777700077777700777770007777700077777007700077077000770770007707700077077000770777777700770000007700000000077000700700000000000
77000770770007707700077077000000007700007700077077000770770007700770770077000770000077700770000000770000000077000000000000000000
77000770770007707700000007777700007700007700077007000700770707700077700077000770007770000770000000077000000077000000000000000000
77777700077777707700000000000770007700007700077007707700777777700770770007777770777000000770000000007700000077000000000000000000
77000000000007707700000007777700000777000777777000777000077077007700077000000770777777700777770000000700077777000000000007777000
77000000000007700000000000000000000000000000000000000000000000000000000007777700000000000000000000000000000000000000000000000000
00770000007770007777770007777700777770007777777077777770077777007700077077777700777777707700077077000000770007707700077007777700
00077000077077007700077077000770770077007700000077000000770000007700077000770000000770007700770077000000777077707770077077000770
00000000770007707700077077000000770007707700000077000000770000007700077000770000000770007707700077000000777777707777077077000770
00000000770007707777770077000000770007707777770077777700770077707777777000770000000770007777000077000000770707707707077077000770
00000000777777707700077077000000770007707700000077000000770007707700077000770000000770007707700077000000770007707707777077000770
00000000770007707700077077000770770077007700000077000000770007707700077000770000000770007700770077000000770007707700777077000770
00000000770007707777770007777700777770007777777077000000077777707700077077777700777700007700077077777770770007707700077007777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777700077777007777770007777700777777007700077077000770770007707700077077000770777777700007770000070000077700000000000000000000
77000770770007707700077077000770007700007700077077000770770007707700077077000770000007700077000000070000000770000000000000000000
77000770770007707700077077000000007700007700077077000770770007700770770077000770000077000077000000070000000770000777077000000000
77777700770007707777770007777700007700007700077077000770770707700077700007777770007770007770000000000000000077707707770000000000
77000000770007707707700000000770007700007700077007707700777777700770770000000770077000000077000000070000000770000000000000000000
77000000770077007700770077000770007700007700077000777000777077707700077000000770770000000077000000070000000770000000000000000000
77000000077707707700077007777700007700000777770000070000770007707700077077777700777777700007770000070000077700000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777770707070707000007007777700700070000070000000777000070007000707070000777000000700000777770007777700000770000777770000070000
77777770070707007700077077000770007000700077000007700700777077700077700000777000007770007770077077777770000777707700077000707000
77777770707070707777777077000770700070000077777077777070777777700770770007777700077777007700077070777070000700007707077007070700
77777770070707007077707077707770007000700777770077777070777777707770777070777070777777707770077070777070000700007700077070777070
77777770707070707077707007777700700070007777700077777770077777000770770000777000077777000777770077777770000700000777770007070700
77777770070707007770777070000070007000700007700007777700007770000077700000707000070707007000007077000770777700007000007000707000
77777770707070700777770007777700700070000000700000777000000700000707070000707000070777000777770007777700777000000777770000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777000007000077777770077777000000000070007000077777007777777070707070000000000000000000000000000000000000000000000000
00000000770077700077700007000700777077700707000007070700770707700000000070707070000000000000000000000000000000000000000000000000
00000000770007707777777000707000770007700070000000700070777077707777777070707070000000000000000000000000000000000000000000000000
70707070770077700077700000070000770007700000000000000000770707700000000070707070000000000000000000000000000000000000000000000000
00000000077777000770770000707000077777000000707070007000077777007777777070707070000000000000000000000000000000000000000000000000
00000000700000700700070007000700700000700000070007070700700000700000000070707070000000000000000000000000000000000000000000000000
00000000077777000000000077777770077777000000000000700070077777007777777070707070000000000000000000000000000000000000000000000000