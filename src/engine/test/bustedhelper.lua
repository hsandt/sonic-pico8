-- required module for all tests
require("engine/test/pico8api")
require("engine/test/assertions")

-- mute all messages during tests, unless told otherwise during the tests
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
logging.logger:register_stream(logging.file_log_stream)
logging.logger:deactivate_all_categories()  -- headless itests will restore "itest" and sometimes "trace"

-- clear log file on new utest session
logging.file_log_stream:clear()

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
-- I also use the symbols for pico8 utests and Python tests
-- from worst to best case:
-- -    the test was hard to write, but didn't help me to spot bug during implementation
-- ~    the test didn't take long to write but it adds a lot of time to the test run and didn't help find bugs
-- ?    the test passed, but later I realized it was wrong, and passed because both the code and expected were wrong but matching (no big loss of time though)
-- ??   same, but big loss of time, as the bug later appeared in a failed itest with unexpected behavior
-- .    the test failed because the test itself was wrong, so I fixed it
-- ..   the test used to pass but failed at some point because of behavior subtleties requiring a more precise test
-- R    the test revealed the same bug/regression as another test, being redundant while not helping to discover another bug
-- <    the test was incomplete, but by examining the code I spotted suspicious cases that I could verify by improving the test, then fix the cases
-- ^    the test was incomplete, so when I stumbled on a special case bug, I improved the test to make sure I fixed it and avoid regression later
-- /    the test was missing at first, but when I spotted missing cases I added them, although the test passed immediately anyway
-- _    the test was missing at first, but by examining the code I spotted suspicious cases that I could verify by adding a new test, then fix the cases
-- =    the test was missing at first so when I stumbled on a new bug, I wrote that test to make sure I fixed it and avoid regression later
-- +    the test helped me identify potential bugs and tricky cases during implementation of the function using the test
-- !    the test failed, revealing a bug hidden in another function indirectly used by the test but not developed at the same time
-- *    the test revealed a regression/feature change later during development (very useful)

-- Note about testing with was_called and was_called_with
-- I reported this issue: assert.spy().was_called_with(...) doesn't provide helpful information on failure #578
-- on https://github.com/Olivine-Labs/busted/issues/578
-- When debugging arguments actually called, use this workaround:
-- print(nice_dump(spy/stub.calls[i].refs/vals)), e.g. print(nice_dump(stub.calls[1].vals))
