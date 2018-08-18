-- required module for all tests
require("pico8api")
require("engine/test/assertions")

-- mute all messages during tests, unless told otherwise during the tests
local logging = require("engine/debug/logging")
logging.console_log_stream.active = false

-- return the current file line in the format "{file}:{line}" to make it easy to navigate there from the printed message
-- if you call this function from an intermediate helper function, add an extra level for each intermediate step
function get_file_line(extra_level)
  -- level 0 is the C getinfo function
  -- level 1 is this line, which is useless
  -- level 2 is the line calling get_file_line, which often interests us
  -- if an intermediate function calls get_file_line, we add extra levels to reach the first function of interest (non-helper)
  extra_level = extra_level or 0
  local debug_info = debug.getinfo(2 + extra_level)
  return debug_info.source..":"..debug_info.currentline
end

function print_at_line(message)
  print(get_file_line(1)..": "..message)
end

-- utest history prefix symbol explanations
-- in order to track the efficiency of my utests, I add symbols in the it('...') to remember what effect they had on development
-- for every occurrence, I add an extra symbol
-- -    the test was hard to write, but didn't help me to spot bug during implementation
-- ?    the test passed, but later I realized it was wrong, and passed because both the code and expected were wrong but matching (no big loss of time though)
-- +    the test helped me identify potential bugs and tricky cases during implementation
-- *    the test revealed a regression later during development (very useful)
