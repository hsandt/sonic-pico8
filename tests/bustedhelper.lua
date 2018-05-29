-- required module for all tests
require("pico8api")

-- mute all messages during tests
local debug = require("engine/debug/debug")
debug.current_level = debug.level.none

local lua_debug = require("debug")

-- luaassert extensions

function almost_eq_with_message(expected, passed, eps)
  eps = eps or 0.01
  return almost_eq(expected, passed, eps), "Expected objects to be almost equal with eps: "..eps..".\nPassed in:\n"..stringify(passed).."\nExpected:\n"..stringify(expected)
end

-- return the current file line in the format "{file}:{line}" to make it easy to navigate there from the printed message
-- if you call this function from an intermediate helper function, add an extra level for each intermediate step
function get_file_line(extra_level)
  -- level 0 is the C getinfo function
  -- level 1 is this line, which is useless
  -- level 2 is the line calling get_file_line, which often interests us
  -- if an intermediate function calls get_file_line, we add extra levels to reach the first function of interest (non-helper)
  extra_level = extra_level or 0
  local debug_info = lua_debug.getinfo(2 + extra_level)
  return debug_info.source..":"..debug_info.currentline
end

function print_at_line(message)
  print(get_file_line(1)..": "..message)
end
