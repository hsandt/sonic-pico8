--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

-- audio usage ranges
-- menu
-- kinda freestyle, but currently:
-- use 8-31 for music tracks (in practice, stops at 26)
-- use 32-63 for sound effects
-- stage intro
-- use 8-31 for music tracks (including fall wind, which is a looping sound)
-- use 32-63 for sound effects
-- ingame
-- use 8-53 for music tracks
-- use 54-63 for sound effects
-- stage clear
-- use 0-15 for music tracks (stage clear didn't need 0-7 for custom instruments so far)
-- use 16-63 for sound effects

local audio = {}

-- Note: we put all game sounds for all cartridges here, potentially with some overlap
-- But it's no issue for cardridge size, because all those contants are substituted anyway.

audio.sfx_ids = {
  -- builtin_data_titlemenu and builtin_data_stage_clear only
  -- inspired by super emerald sound B8 in Sonic 3 & K, now unused (use emerald_flying music for looped SFX)
  -- emerald_fly = 49,
  menu_select = 50,  -- currently no sound, as Sonic 3 didn't have one either
  menu_confirm = 51,
  spark = 58,  -- v2 with custom instrument 6

  -- builtin_data_stage_clear only
  menu_swipe = 52,
  got_all_emeralds = 56,

  -- builtin_data_stage_intro only
  landing = 54,

  -- exceptionally builtin_data_titlemenu and builtin_data_ingame
  --  because there is a jump in the start cinematic, although vol -4 and detuned
  jump = 55,
  -- builtin_data_ingame only
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
  -- titlemenu only (overlaps stage bgm in builtin_data_ingame.p8)
  title = 0,
  -- more like looping SFX, but allows intro-loop (first part has higher volume)
  emerald_flying = 8,
  -- stage_intro only
  fall_wind = 0,
  fall_leaves = 1,
  -- stage_clear only
  staff_roll = 2
  -- note: stage_common_data contains the bgm_id for the stage (always 0)
}

--(game_constants)
--#endif

return audio
