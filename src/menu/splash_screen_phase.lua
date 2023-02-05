--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

local splash_screen_phase = {
  blank_screen = 0,
  sonic_moves_left = 1,
  logo_appears_in_white = 2,
  left_speed_lines_fade_out = 3,
  sonic_moves_right = 4,
  right_speed_lines_fade_out = 5,
  full_logo = 6,
  fade_out = 7,
}

--(game_constants)
--#endif

return splash_screen_phase
