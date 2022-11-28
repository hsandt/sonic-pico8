-- main entry file for the generate_sfx_sage_choir_cartridge cartridge
--  game states: none, it's a custom cartridge run offline to generate a font snippet from a font spritesheet

-- this must be run offline as headless with `pico8 -x` so it can be executed at once and save the result cartridge

-- after running it, the sage choir pcm data will be saved as gfx data in cartridge carts/gfx_sage_choir_pcm_data.p8
--  so you can extract the __gfx__ section and save a pure gfx cartridge in the project
--  (we recommend tracking it in VCS even if redundant with pcm data as string for convenience)
-- finally, you can merge it into some existing data cartridge that doesn't need its __gfx__ section
--  (see install_data_cartridges_with_merging.sh)

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_generate_gfx_sage_choir_pcm_data")

local pcm_data = require("data/pcm_data")


-- PCM: load digitized audio samples stored as string into gfx memory
-- Format:
-- - first two bytes: pcm sample length
-- - remaining bytes (max total size 0x2000): pcm sample bytes
-- Thanks to IMLXH (also carlc27843 and czarlo)
-- https://www.lexaloffle.com/bbs/?tid=45013
-- https://colab.research.google.com/drive/1HyiciemxfCDS9DxE98UCtNXas5TrM-5e?usp=sharing
-- The playing part is done in splash_screen_state:play_pcm
local function load_pcm(pcm_sample)
  local l = #pcm_sample
  assert(2 + l <= 0x2000, "pcm_sample length is "..l.." ("..tostr(l, true).."), expected length <= 8190 (0x2000 - 2) to fix in __gfx__ section even with 2 extra bytes to store pcm sample length")

  -- store pcm sample length in the first two bytes (since length can be up to 8192,
  --  so 1 byte is not enough)
  poke2(0x0, l)

  for i = 0, l - 1 do
    -- save sample bytes, skipping the first two bytes reserved to length
    poke(0x2 + i, ord(pcm_sample, i))
  end
end

-- load audio sample into memory
load_pcm(pcm_data._sage_choir)

-- save cartridge (we only care about the __gfx__ section)
save("gfx_sage_choir_pcm_data.p8")

-- log action, although generally not visible for long since terminal tends to close
--  at the end
printh("saved carts/gfx_sage_choir_pcm_data.p8")
