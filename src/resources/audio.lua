local audio = {}

audio.sfx_ids = {
  -- builtin_data_titlemenu only
  menu_select = 50,
  menu_confirm = 51,

  -- builtin_data_ingame only
  -- because it plays on 4th channel over low-volume bgm,
  --  pick emerald jingle is considered an sfx
  pick_emerald = 57,
  goal_reached = 58,
  jump = 59,
  spring_jump = 60,
  roll = 61,
  brake = 62,
}

audio.jingle_ids = {
  stage_clear = 41,
}

audio.music_ids = {
  -- builtin_data_titlemenu only (overlaps stage bgm in data_bgm1.p8)
  title = 0,
}

return audio
