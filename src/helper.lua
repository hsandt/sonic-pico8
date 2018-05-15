require("constants")

-- return true if the table is empty
function is_empty(t)
  for k, v in pairs(t) do
    return false
  end
  return true
end

-- clear a table
function clear_table(t)
 for k in pairs(t) do
  t[k] = nil
 end
end

-- unpack from munpack at https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0
function unpack(t, from, to)
  from = from or 1
  to = to or #t
  if from > to then return end
  return t[from], unpack(t, from+1, to)
end

function tostring(value)
  if type(value) == "table" and value._tostring then
    return value:_tostring()
  else
    return tostr(value)
  end
end

-- concatenate a sequence of strings or stringables with a separator
-- embedded nil values won't be ignored, but nils at the end will be
function joinstr_table(separator, args)
  local n = #args

  local joined_string = ""

  -- iterate by index instead of for all, so we don't skip nil values
  -- and #n (which counts nil values) match the used index
  for index = 1, n do
    joined_string = joined_string..tostring(args[index])
    if index < n then
      joined_string = joined_string..separator
    end
  end

  return joined_string
end

-- variadic version
function joinstr(separator, ...)
  return joinstr_table(separator, {...})
end

-- wait for [time]s. only works if you update your coroutines each frame.
function yield_delay(delay)
  local nb_frames = fps * delay
  -- we want to continue the coroutine as soon as the last frame
  -- has been reached, so we don't want to yield the last time, hence -1
  -- in addition, if nb_frames is fractional we want to wait for the last frame
  -- to be fully completed, hence ceil
  for frame = 1, ceil(nb_frames) - 1 do
    yield()
  end
end
