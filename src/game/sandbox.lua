require("engine/debug/debug")
require("engine/core/helper")
require("engine/core/math")
require("engine/core/class")
require("engine/core/coroutine")

function test_fun_async_with_args(var1, var2)
end

printh('joinstr("", nil, 5, "at") : '..joinstr("", nil, 5, "at") )

local dummy_class = new_class()

function dummy_class:_init(value)
self.value = value
end

function dummy_class:_tostring(value)
return "dummy:"..self.value
end

function dummy_class.__eq(lhs, rhs)
return lhs.value == rhs.value
end

function dummy_class:get_incremented_value()
return self.value + 1
end

local dummy = dummy_class(3)

printh(dummy_class(12):_tostring())

printh(dummy_class(11).."str")
printh(dummy_class(11)..true)
printh(dummy_class(11)..24)
-- caveats

-- syntax error: malformed number near 27..d
-- this error will block the output stream, getting picotest stuck!
-- correct:
printh("27"..dummy_class(11))

local dummy_derived_class = derived_class(dummy_class)

function dummy_derived_class:_init(value, value2)
  dummy_class:_init(value)
  self.value2 = value2
end

function dummy_derived_class:_tostring()
  return "dummy derived:"..self.value..","..self.value2
end

function dummy_derived_class.__eq(lhs, rhs)
  return lhs.value == rhs.value and lhs.value2 == rhs.value2
end

printh("dummy_derived_class(11, 45)..\"str\": "..dummy_derived_class(11, 45).."str")

printh("dummy_derived_class(11, 45)..true: "..dummy_derived_class(11, 45)..true)

local immutable_dummy_class = immutable_class(dummy_class)

printh("immutable_dummy_class(12):_tostring(): "..immutable_dummy_class(12):_tostring())
printh("immutable_dummy_class(11)..\"str\": "..immutable_dummy_class(11).."str")

-- caveats

-- syntax error: malformed number near 27..d
-- this error will block the output stream, getting picotest stuck!
-- printh(27..vector(11, 45))
-- correct:
printh("27"..vector(11, 45))
-- or
printh(tostr(27)..vector(11, 45))
