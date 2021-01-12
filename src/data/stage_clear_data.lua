local stage_clear_data = {

  -- stage clear sequence timing

  -- duration of stage clear jingle (frames)
  --  (actual notes length is 357, added one note = 7 frames to reach half of 3rd column)
  stage_clear_duration = 364,

  -- delay between emerald assessment animation has ended, and fade out to retry screen starts (s)
  show_emerald_assessment_duration = 2.0,

  -- duration of zigzag fadeout (frames)
  zigzag_fadeout_duration = 18,

  -- delay after zigzag fade out, before showing retry screen content (s)
  delay_after_zigzag_fadeout = 1.0,
}

return stage_clear_data
