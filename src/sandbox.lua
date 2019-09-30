require("engine/core/math")
require("engine/core/helper")

-- caveats

-- syntax error: malformed number near 27..d
-- this error will block the output stream, getting picotest stuck!
-- printh(27..vector(11, 45))  -- incorrect
-- correct:
printh("27"..vector(11, 45))
-- or
-- printh(tostr(27)..vector(11, 45))

s = [[
1

2]]

lines = strspl(s, "\n")

-- COMMENT
--[[BLOCk
COMMENT]]
for line in all(lines) do
  print("line: "..line)
end

--[[
--]]
