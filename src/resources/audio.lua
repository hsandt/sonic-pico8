--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

-- audio usage ranges
-- menu
-- kinda freestyle, but currently:
-- use 8-31 for music tracks (in practice, stops at 26)
-- use 32-63 for sound effects
-- ingame
-- use 8-53 for music tracks
-- use 54-63 for sound effects
-- stage clear
-- use 8-15 for music tracks
-- use 16-63 for sound effects

local audio = {}

-- OPTIMIZE CHARS: we can split menu, stage clear and ingame sound data to reduce size of ingame cartridge

audio.sfx_ids = {

  -- builtin_data_titlemenu and builtin_data_stage_clear only
  emerald_fly = 49,  -- inspired by super emerald sound B8 in Sonic 3 & K
  menu_select = 50,  -- currently no sound, as Sonic 3 didn't have one either
  menu_confirm = 51,

  -- builtin_data_stage_clear only
  menu_swipe = 52,
  got_all_emeralds = 56,

  -- builtin_data_ingame only
  jump = 55,
  spring_jump = 56,
  roll = 57,
  brake = 58,
  -- because it plays on 4th channel over low-volume bgm,
  --  pick emerald jingle is considered an sfx
  pick_emerald = 59,
  goal_reached = 60,
  spin_dash_rev = 61,
  spin_dash_release = 62
}

audio.jingle_ids = {
  -- builtin_data_stage_clear only (overlaps stage bgm in builtin_data_ingame.p8)
  stage_clear = 0,
}

audio.music_ids = {
  -- builtin_data_titlemenu only (overlaps stage bgm in builtin_data_ingame.p8)
  title = 0,
}

--(game_constants)
--#endif

return audio
