-- TODO OPTIMIZE CHARS: strip unless #game_constants since these will be substituted
-- in addition, we now have an automatic namespace constant parsing system,
--  so can be removed from game_substitute_table.py in exchange for adding this file to
--  game_constant_module_paths_string in build_single_cartridge.sh

sprite_flags = {
  collision = 0,           -- collision flag set on VISUAL sprite (and MASK sprite for testing with proto tiles)
  oneway = 1,              -- one-way collision flag set on VISUAL sprite
  ignore_loop_layer = 2,   -- never ignore collision due to being in loop entrance/exit
                           --  (added to avoid entering ground near entrance)
  -- unused3 = 3,
  waterfall = 4,           -- any tile normally on midground but containing animated waterfall parts via color swapping
                           --  when setting this flag, do *not* also set the midground flag so we can render them separately
  spring = 5,              -- spring
  midground = 6,           -- midground sprite (should be drawn after programmatical background, and includes tilemap BG)
  foreground = 7,          -- foreground sprite (should be drawn last)
}

sprite_masks = {
  collision = 1,          -- 1 << 0
  oneway = 2,             -- 1 << 1
  ignore_loop_layer = 4,  -- 1 << 2
  -- unused3 = 8,         -- 1 << 3
  waterfall = 16,         -- 1 << 4
  spring = 32,            -- 1 << 5
  midground = 64,         -- 1 << 6
  foreground = 128,       -- 1 << 7
}
