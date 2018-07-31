require("engine/application/constants")

-- return true if the table is empty
function is_empty(t)
  for k, v in pairs(t) do
    return false
  end
  return true
end

-- return true if both tables have the same keys and values
-- keys and values are compared by usual equality, which may be shallow or deep depending on __eq override
-- metatables are not checked
function are_same(t1, t2)
  -- first iteration: check that all keys of t1 are in t2, with the same value
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil then
      -- t2 misses key k1 that t1 has
      return false
    end
    if v1 ~= v2 then
      return false
    end
  end
  -- second iteration: check that all keys of t2 are in t1. don't check values, it has already been done
  for k2, _ in pairs(t2) do
    if t1[k2] == nil then
      -- t1 misses key k2 that t2 has
      return false
    end
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

--#if log

function stringify(value)
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
    joined_string = joined_string..stringify(args[index])
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
--#endif

-- https://pastebin.com/NS8rxMwH
-- converted to clean lua, adapted coding style
-- changed behavior:
-- - avoid adding next line if first word of line is too long
-- - don't add trailing space at end of line
-- - don't add eol at the end of the last line
-- - count the extra separator before next word in the line length prediction test

--word wrap (string, char width)
function wwrap(s,w)
  local retstr = ""
  local lines = strspl(s, "\n")
  local nb_lines = count(lines)

  for i = 1, nb_lines do
    local linelen = 0
    local words = strspl(lines[i], " ")
    local nb_words = count(words)

    for k = 1, nb_words do
      local wrd = words[k]
      local should_wrap = false

      if k > 1 then
        -- predict length after adding 1 separator + next word
        if linelen + 1 + #wrd > w then
          -- wrap
          retstr = retstr.."\n"
          linelen = 0
          should_wrap = true
        else
          -- don't wrap, so add space after previous word if not the first one
          retstr = retstr.." "
          linelen = linelen + 1
        end
      end

      retstr = retstr..wrd
      linelen = linelen + #wrd

      if k < nb_words and not should_wrap then
      end
    end

    -- wrap following \n already there
    if i < nb_lines then
      retstr = retstr.."\n"
    end
  end

  return retstr
end

--string split(string, separator)
function strspl(s,sep)
  local ret = {}
  local buffer = ""

  for i = 1, #s do
    if sub(s, i, i) == sep then
      add(ret, buffer)
      buffer = ""
    else
      buffer = buffer..sub(s,i,i)
    end
  end
  if buffer ~= "" then
    add(ret, buffer)
  end
  return ret
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
