-- main entry file for the generate_sfx_sage_choir_cartridge cartridge
--  game states: none, it's a custom cartridge run offline to generate a font snippet from a font spritesheet

-- you must first prepare the .wav or .ogg audio file in audio/, then run convert_audio_to_pcm_data.sh

-- then, build and run this cart offline as headless with `pico8 -x` so it can be executed at once and save the result cartridge

-- after running it, the sage choir pcm data will be saved as gfx data in two cartridges:
--  carts/gfx_sage_choir_pcm_data_part_1.p8 and carts/gfx_sage_choir_pcm_data_part_2.p8
--  so you can extract their respective __gfx__ section and save them in pure gfx cartridges in the project
--  (with same name under data/ folder)
--  (we recommend tracking it in VCS even if redundant with pcm data as string for convenience)
-- finally, you can merge it into some existing data cartridge that doesn't need its __gfx__ section
--  (see install_data_cartridges_with_merging.sh)

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")
require("common_generate_gfx_sage_choir_pcm_data")

local pcm_data = require("data/pcm_data")


-- PCM: load digitized audio samples stored as string into gfx memory,
-- splitting data into up to two cartridges for a total capacity of 0x4000 bytes
-- (0x3ffe bytes of pure data after removing header space)

-- addr: content description below

-- 1st cart __gfx__
-- 0x0000-0x0001: [length header]
-- 0x0002-0x1fff: first part of sample: bytes 0x0001-0x1ffe (starting at 1 for use in ord)

-- 2nd cart __gfx__
-- 0x0000-0x1fff: second part of sample: bytes 0x1fff-0x3ffe (starting at 1 for use in ord)

-- Thanks to IMLXH (also carlc27843 and czarlo)
-- https://www.lexaloffle.com/bbs/?tid=45013
-- https://colab.research.google.com/drive/1HyiciemxfCDS9DxE98UCtNXas5TrM-5e?usp=sharing
-- The playing part is done in splash_screen_state:play_pcm

-- load first part of the sample, with length header
-- Format:
-- - first two bytes: pcm sample length
-- - remaining bytes (max total size 0x2000): pcm sample bytes 0x0001-0x1ffe
local function load_pcm_first_part(pcm_sample)
  local l = #pcm_sample

  -- store pcm sample length in the first two bytes (since length can be up to 8192,
  --  so 1 byte is not enough)
  poke2(0x0, l)

  -- save 1st part of sample bytes, skipping the first two bytes reserved to length
  for i = 1, min(0x1ffe, l) do
    -- i starts at 1, so offset by 0x1 so we start at 0x2, just after the length header
    -- the last byte we may reach is 0x1fff
    poke(0x1 + i, ord(pcm_sample, i))
  end
end

-- load second part of the sample (if more than 0x1ffe bytes)
-- Format:
-- - all bytes (max total size 0x2000): pcm sample bytes 0x1fff-0x3ffe
local function load_pcm_second_part(pcm_sample)
  local l = #pcm_sample

  -- here, min is only to avoid poking bad memory in non-assert build
  -- but we recommend to always build and run assert config for this cartridge
  for i = 0x1fff, min(0x3ffe, l) do
    -- it's a new cartridge without any length header, so we must offset the target
    --  address to start at 0, and reach up to 0x1fff
    poke(i - 0x1fff, ord(pcm_sample, i))
  end
end

local pcm_sample = pcm_data._sage_choir
local l = #pcm_sample
assert(2 + l <= 0x4000, "pcm_sample length is "..l.." ("..tostr(l, true).."), expected length <= 16382 (0x4000 - 2) to fit in 2 __gfx__ sections even with 2 extra bytes to store pcm sample length")

-- load audio sample into memory in up to two steps

load_pcm_first_part(pcm_sample)

-- save cartridge for first part (we only care about the __gfx__ section)
save("gfx_sage_choir_pcm_data_part_1.p8")
printh("saved carts/gfx_sage_choir_pcm_data_part_1.p8")

if l > 0x1ffe then
  -- sample is too long to fit in one cart __gfx__, so save a second one
  load_pcm_second_part(pcm_sample)

  -- save cartridge for second part (we only care about the __gfx__ section)
  save("gfx_sage_choir_pcm_data_part_2.p8")
  printh("saved carts/gfx_sage_choir_pcm_data_part_2.p8")
end
