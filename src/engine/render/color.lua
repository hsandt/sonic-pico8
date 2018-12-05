-- default pico-8 colors

--#ifn pico8
colors = {
  black = 0,
  dark_blue = 1,
  dark_purple = 2,
  dark_green = 3,
  brown = 4,
  dark_gray = 5,
  light_gray = 6,
  white = 7,
  red = 8,
  orange = 9,
  yellow = 10,
  green = 11,
  blue = 12,
  indigo = 13,
  pink = 14,
  peach = 15
}
--#endif

--#if log
color_strings = {
  [0] = "black",
  "dark_blue",
  "dark_purple",
  "dark_green",
  "brown",
  "dark_gray",
  "light_gray",
  "white",
  "red",
  "orange",
  "yellow",
  "green",
  "blue",
  "indigo",
  "pink",
  "peach"
}

function color_tostring(colour)
  return color_strings[colour] or "unknown color"
end
--#endif

-- set colour as the only transparent color
function set_unique_transparency(colour)
  -- reset any previous transparency change
  palt()
  -- default color (black) is not transparent anymore
  palt(0, false)
  -- new transparency
  palt(colour, true)
end
