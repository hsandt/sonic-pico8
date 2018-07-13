local debug = require("engine/debug/debug")

-- custom assertions to extend luaassert in utests and provide assertion with messages in itests

function contains(t, searched_value)
  for key, value in pairs(t) do
    if value == searched_value then
      return true
    end
  end
  return false
end

function contains_with_message(sequence, passed)
  local result = contains(sequence, passed)
  if result then
    -- passed is not contained, return false with does_not_contain message (will appear when using assert.is_false(contains_with_message()))
    return true, "Expected object not to be one of the entries of the sequence.\nPassed in:\n"..nice_dump(passed).."\nSequence:\n"..nice_dump(sequence).."\n--- Ignore below ---"
  else
    return false, "Expected object to be one of the entries of the sequence.\nPassed in:\n"..nice_dump(passed).."\nSequence:\n"..nice_dump(sequence).."\n--- Ignore below ---"
  end
end

function almost_eq_with_message(expected, passed, eps)
  eps = eps or 0.01
  local result = almost_eq(expected, passed, eps)
  if result then
    return true, "Expected objects not to be almost equal with eps: "..eps..".\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(expected).."\n--- Ignore below ---"
  else
    return false, "Expected objects to be almost equal with eps: "..eps..".\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(expected).."\n--- Ignore below ---"
  end
end
