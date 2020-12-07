local audio = {}

audio.sfx_ids = {
  -- builtin_data_titlemenu only
  menu_select = 50,
  menu_confirm = 51,

  -- builtin_data_ingame only
  -- pick_emerald = 57,  -- unused
  goal_reached = 58,
  jump = 59,
  spring_jump = 60,
  roll = 61,
  brake = 62,
}

audio.jingle_ids = {
  pick_emerald = 40,
  stage_clear = 41,
}

audio.music_ids = {
  -- builtin_data_titlemenu only (overlaps stage bgm in data_bgm1.p8)
  title = 0,
}

return audio
