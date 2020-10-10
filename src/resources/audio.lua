local audio = {}

local sfx_ids = {
  pick_emerald = 57,
  goal_reached = 58,
  jump = 59,
  spring_jump = 60,
  roll = 61,
  brake = 62,
  -- menu_select = ??,
  -- menu_confirm = ??,
}

local jingle_ids = {
  pick_emerald = 40,  -- unused
  stage_clear = 41,
}

audio.sfx_ids = sfx_ids
audio.jingle_ids = jingle_ids

return audio
