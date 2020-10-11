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
  -- duration of goal plate rotating before stage clear (results sub-state) starts (frames)
  goal_rotating_anim_duration = 120,
  -- duration of stage clear jingle, including blank at the end (frames)
  stage_clear_duration = 448,
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

      -- dimensions in tiles (128 * number of chained maps per row, 32 * number of chained maps per column,
      --  extra tiles on width for goal area)
      -- they will be divided by 128 or 32 and ceiled to deduce the extended map grid to load
      tile_width = 128 * 3 + 48,
      tile_height = 32 * 2,

      -- where the player character spawns on stage start (region (0, 1))
      -- ! structs are still accessed by ref in Lua, OK but make sure to always copy
      -- or apply a conversion method, never assign them directly to a variable that may change
      spawn_location = location(7, 32+15),

      -- the x to reach to finish the stage
      -- remove it with new goal soon
      goal_x = (3*128 + 48)*8,  -- after 3 regions of 128 tiles, in the middle of the partial final region

      -- bgm id
      -- with the new dynamic bgm cartridge reload system,
      --  we have separate cartridges containing the bgm
      --  and it always starts at 0, covering not more than patterns 0-49
      --  (to guarantee space for SFX)
      bgm_id = 0,

      -- camera data

      -- camera bottom limit margin piecewise constant curve keypoints
      -- it is made of horizontal segments defined by key points at their *end*,
      --  and mostly useful because we don't want the camera to show too much of the bottom at some places,
      --  so the player can see more of the top and feel that they have reached the (local) bottom of the stage
      -- keypoint X represents the tile i coordinate that camera X must reach (must * tile_size)
      -- because it is simpler to count tiles from the bottom, we define keypoint Y as the number of tiles
      --  from the real stage bottom, that are hidden and from where the camera will be clamped
      -- (note that they are only hidden in the middle of the segments they belong to; crouching, if implemented, just on the left/right
      --  of a keypoint would reveal suddenly more or less tiles, but we don't mind because the sudden changes
      --  are done when the ground is at a high level, so they can't be experienced when running normally)
      -- keypoints must be defined in order, from left to right, at each segment end
      --  a keypoint = vector(camera_x, camera_bottom_limit_offset)
      -- they have been deduced from playing Sonic 3 (& K) and crouching to see how far I can look down
      camera_bottom_limit_margin_keypoints = {
        vector(47, 11),
        vector(104, 8),
        -- normal stage bottom limit from tile 104
        -- there is actually yet another level in the original game, but it is to reveal the water area
        --  and since we cut the bottom of it for our adaptation, the last bottom limit, which matches
        --  our lowest region bottom exactly, is the ultimate limit for us
      },

      -- layer data
      -- all tile locations are global

      loop_exit_areas = {
        -- lower loop (read in region (1, 1))
        location_rect(128 + 94, 32 + 12, 128 + 100, 32 + 22),
        -- upper loop 1 (read in region (2, 0))
        location_rect(256 + 81, 20, 256 + 87, 30),
        -- upper loop 2 (read in region (2, 0) and (2, 1))
        location_rect(256 + 105, 28, 256 + 111, 32 + 5),
      },

      loop_entrance_areas = {
        -- small loop (read in region (1, 1))
        location_rect(128 + 101, 32 + 12, 128 + 106, 32 + 22),
        -- upper loop 1 (read in region (2, 0))
        location_rect(256 + 88, 20, 256 + 93, 30),
        -- upper loop 2 (read in region (2, 0) and (2, 1))
        location_rect(256 + 112, 28, 256 + 117, 32 + 5),
      }
    }

  }

}
