local stage_clear_data = {

  -- stage clear sequence timing

  -- duration of stage clear jingle (frames)
  --  (actual notes length is 357, added one note = 7 frames to reach half of 3rd column)
  stage_clear_duration = 364,

  -- delay between showing "sonic got all emeralds" and got all emeralds SFX (s)
  got_all_emeralds_sfx_delay_s = 1.0,

  -- estimated duration of got all emeralds SFX (with some margin) to finish playing it before next phase (s)
  got_all_emeralds_sfx_duration_s = 2.0,

  -- delay between emeralds assessment and fade-out (s)
  fadeout_delay_s = 1.0,

  -- duration of zigzag fadeout (frames)
  zigzag_fadeout_duration = 18,

  -- delay after zigzag fade out, before showing retry screen content (s)
  delay_after_zigzag_fadeout = 1.0,
}

return stage_clear_data
