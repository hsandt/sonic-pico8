require("engine/core/helper")

-- helper for unitests executed in pico8, that miss busted assertions

function are_same_with_message(t, passed, compare_raw_content)
  if compare_raw_content == nil then
    compare_raw_content = false
  end
  local result = are_same(t, passed, compare_raw_content)
  if result then
    -- passed is not same as t, return false with does_not_contain message (will appear when using assert(not are_same(...)))
    return true, "Expected objects to not be the same (compare_raw_content: "..tostr(compare_raw_content)..").\nPassed in:\n"..nice_dump(passed).."\nDid not expect:\n"..nice_dump(t)
  else
    return false, "Expected objects to be the same (compare_raw_content: "..tostr(compare_raw_content)..").\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(t)
  end
end
