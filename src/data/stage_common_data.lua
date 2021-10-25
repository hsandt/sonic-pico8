--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

local stage_common_data = {

  -- Gameplay

  emerald_pick_radius = 8,


  -- Region reload

  -- distance of camera center from region edge at which we start reloading the neighbouring region
  -- map_region_tile_height = 32 so it must be at least 16 * tile_size
  transition_margin = 64,  -- 8 * tile_size


  -- Visual

  -- duration of goal plate rotating before stage clear (results sub-state) starts (frames)
  goal_rotating_anim_duration = 120,

  -- spring extension duration (tiles use custom animation via async instead of animated_sprite)
  spring_extend_duration = 0.15,


  -- Audio

  -- bgm id
  -- with the new dynamic bgm cartridge reload system,
  --  we have separate cartridges containing the bgm
  --  and it always starts at 0, covering not more than patterns 0-49
  --  (to guarantee space for SFX)
  bgm_id = 0,

  -- duration of bgm fade out after reaching goal (s)
  bgm_fade_out_duration = 1.0,
}

--(game_constants)
--#endif

return stage_common_data
