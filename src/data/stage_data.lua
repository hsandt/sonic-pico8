local location_rect = require("engine/core/location_rect")
local sprite_data = require("engine/render/sprite_data")

local audio = require("resources/audio")

return {

  -- common data

  -- gameplay

  emerald_pick_radius = 8,

  -- UI

  -- delay between stage enter and showing stage title (s)
  show_stage_title_delay = 4.0,
  -- delay between reaching goal and going back to title menu (s)
  back_to_titlemenu_delay = 1.0,
  -- duration of bgm fade out after reaching goal (s)
  bgm_fade_out_duration = 1.0,

  -- other visuals

  -- spring extension duration (tiles use custom animation via async instead of animated_sprite)
  spring_extend_duration = 0.15,

  -- stage-specific data, per id

  for_stage = {

    [1] = {
      -- stage title
      title = "angel island",

      -- dimensions in tiles (128 * number of chained maps per row, 32 * number of chained maps per column)
      -- they will be divided by 128 or 32 and ceiled to deduce the extended map grid to load
      tile_width = 128 * 3,
      tile_height = 32 * 2,

      -- where the player character spawns on stage start (region (0, 1))
      spawn_location = location(7, 32+15),

      -- the x to reach to finish the stage
      goal_x = 3*128*8,  -- 3072, after 3 regions of 128 tiles (goal is at stage right edge unlike classic Sonic)

      -- bgm id
      -- with the new dynamic bgm cartridge reload system,
      --  we have separate cartridges containing the bgm
      --  and it always starts at 0, covering not more than patterns 0-49
      --  (to guarantee space for SFX)
      bgm_id = 0,

      -- layer data
      -- all tile locations are global

      loop_exit_areas = {
        -- lower loop (read in region (1, 1))
        location_rect(128 + 94, 32 + 12, 128 + 100, 32 + 22),
        -- upper loop 1 (read in region (2, 0))
        location_rect(256 + 81, 20, 256 + 87, 30),
        -- upper loop 2 (read in region (2, 0) and (2, 1))
        location_rect(256 + 105, 30, 256 + 111, 32 + 7),
      },

      loop_entrance_areas = {
        -- small loop (read in region (1, 1))
        location_rect(128 + 101, 32 + 12, 128 + 106, 32 + 22),
        -- upper loop 1 (read in region (2, 0))
        location_rect(256 + 88, 20, 256 + 93, 30),
        -- upper loop 2 (read in region (2, 0) and (2, 1))
        location_rect(256 + 112, 30, 256 + 117, 32 + 7),
      }
    }

  }

}
