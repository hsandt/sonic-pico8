require("engine/application/constants")


-- create an enum from a sequence of variant names
function enum(variant_names)
  local t = {}
  local i = 1

  for variant_name in all(variant_names) do
    t[variant_name] = i
    i = i + 1
  end

  return t
end

-- implementation of "map" in other languages (but "map" means something else in pico8)
function transform(t, func)
  local transformed_t = {}
  for value in all(t) do
    add(transformed_t, func(value))
  end
  return transformed_t
end

-- return module members from their names as multiple values
-- use it after require("module") to define
--  local a, b = get_members(module, "a", "b")
--  for more simple access
function get_members(module, ...)
  local member_names = {...}
  return unpack(transform(member_names,
    function(member_name)
      return module[member_name]
    end)
  )
end

-- return true if the table is empty (contrary to #t == 0,
--  it also supports non-sequence tables)
function is_empty(t)
  for k, v in pairs(t) do
    return false
  end
  return true
end

-- return true if t1 and t2 have the same recursive content:
--  - if t1 and t2 are tables, if they have the same keys and values,
--   if compare_raw_content is false, table values with __eq method are compared by ==,
--    but tables without __eq are still compared by content
--   if compare_raw_content is true, tables are compared by pure content, as in busted assert.are_same
--    however, keys are still compared with ==
--    (simply because it's more complicated to check all keys for deep equality, and rarely useful)
--  - else, if they have the same values (if different types, it will return false)
-- if no_deep_raw_content is true, do not pass the compare_raw_content parameter to deeper calls
--  this is useful if you want to compare content at the first level but delegate equality for embedded structs
function are_same(t1, t2, compare_raw_content, no_deep_raw_content)
  -- compare_raw_content and no_deep_raw_content default to false (we count on nil being falsy here)

  if type(t1) ~= 'table' or type(t2) ~= 'table' then
    -- we have at least one non-table argument, compare by equality
    -- if both arguments have different types, it will return false
    return t1 == t2
  end

  -- both arguments are tables, check meta __eq

  local mt1 = getmetatable(t1)
  local mt2 = getmetatable(t2)
  if (mt1 and mt1.__eq or mt2 and mt2.__eq) and not compare_raw_content then
    -- we are not comparing raw content and equality is defined, use it
    return t1 == t2
  end

  -- we must compare keys and values

  -- first iteration: check that all keys of t1 are in t2, with the same value
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil then
      -- t2 misses key k1 that t1 has
      return false
    end
    if not are_same(v1, v2, compare_raw_content and not no_deep_raw_content) then
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

--#if assert
-- return a table reversing keys and values, assuming the original table is injective
-- this is "assert" only because we mostly need it to generate enum-to-string tables
function invert_table(t)
  inverted_t = {}
  for key, value in pairs(t) do
    inverted_t[value] = key
  end
  return inverted_t
end
--#endif

-- alternative to tonum that only works with strings (and numbers
--   thanks to sub converting them implicitly)
-- it fixes the 0x0000.0001 issue on negative number strings
-- UPDATE: expect native tonum to be fixed in 0.1.12
-- https://www.lexaloffle.com/bbs/?pid=63583
function string_tonum(val)
  -- inspired by cheepicus's workaround in
  -- https://www.lexaloffle.com/bbs/?tid=3780
  if sub(val, 1, 1) == '-' then
    local abs_num = tonum(sub(val, 2))
    assert(abs_num, "could not parse absolute part of number: '-"..sub(val, 2).."'")
    return - abs_num
  else
    local num = tonum(val)
    assert(num, "could not parse number: '"..val.."'")
    return num
  end
end

--#if log

function stringify(value)
  if type(value) == 'table' and value._tostring then
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
-- i kept the fact that we don't collapse spaces so 2x, 3x spaces are preserved

-- word wrap (string, char width)
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

-- port of lua string.split(string, separator)
-- separator must be only one character
-- added parameter collapse:
--  if true, collapse consecutive separators into a big one
--  if false or nil, handle each separator separately,
--   adding an empty string between each consecutive pair
-- ex1: strspl("|a||b", "|")       => {"", "a", "", "b"}
-- ex2: strspl("|a||b", "|", true) => {"a", "b"}
function strspl(s,sep,collapse)
  local ret = {}
  local buffer = ""

  for i = 1, #s do
    if sub(s, i, i) == sep then
      if #buffer > 0 or not collapse then
        add(ret, buffer)
        buffer = ""
      end
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
