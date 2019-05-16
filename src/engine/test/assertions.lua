--#if log

require("engine/core/math")

function contains(t, searched_value)
  for key, value in pairs(t) do
    if value == searched_value then
      return true
    end
  end
  return false
end

-- custom assertions to extend luaassert in utests and provide assertion with messages in itests

function contains_with_message(sequence, passed)
  local result = contains(sequence, passed)
  if result then
    -- passed is not contained, return false with does_not_contain message (will appear when using assert.is_false(contains_with_message()))
    return true, "Expected object not to be one of the entries of the sequence.\nPassed in:\n"..nice_dump(passed).."\nSequence:\n"..nice_dump(sequence)
  else
    return false, "Expected object to be one of the entries of the sequence.\nPassed in:\n"..nice_dump(passed).."\nSequence:\n"..nice_dump(sequence)
  end
end

-- imitation of busted equality check with message used in assert.are_equal
-- it returns a "inequality expected" message if expected == passed so we can use it to assert inequality as well
function eq_with_message(expected, passed)
  if expected == passed then
    return true, "Expected objects to not be equal.\nPassed in:\n"..nice_dump(passed).."\nDid not expect:\n"..nice_dump(expected)
  else
    return false, "Expected objects to be equal.\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(expected)
  end
end

-- same, but with almost equality
function almost_eq_with_message(expected, passed, eps)
  eps = eps or 0.01
  local result = almost_eq(expected, passed, eps)
  if result then
    return true, "Expected objects to not be almost equal with eps: "..eps..".\nPassed in:\n"..nice_dump(passed).."\nDid not expect:\n"..nice_dump(expected)
  else
    return false, "Expected objects to be almost equal with eps: "..eps..".\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(expected)
  end
end

--#endif
