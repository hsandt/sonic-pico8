require("engine/core/helper")

debug_level = {
 log = 1,   -- show all messages
 warning = 2,  -- show warnings and errors
 error = 3, -- show errors only
 none = 4,  -- show nothing
}

active_debug_categories = {
 default = true,
 flow = true,
 player = true,
 ui = true,
 codetuner = true
}

current_debug_level = debug_level.log

-- print a log message to the console in a category string
function log(message, category)
  category = category or "default"
  if active_debug_categories[category] and current_debug_level <= debug_level.log then
    printh("["..category.."] "..tostring(message))
  end
end

-- print a warning message to the console in a category string
function warn(message, category)
  category = category or "default"
  if active_debug_categories[category] and current_debug_level <= debug_level.warning then
    printh("["..category.."] warning: "..tostring(message))
  end
end

-- print an error message to the console in a category string
function err(message, category)
  category = category or "default"
  if active_debug_categories[category] and current_debug_level <= debug_level.error then
    printh("["..category.."] error: "..tostring(message))
  end
end

-- return a precise variable content, including table entries
-- for sequence containing nils, nil not not shown but nil's index will be skipped
-- if as_key is true and t is not a string, surround it with []
-- stop recursion after 2 levels
function dump(dumped_value, as_key, level)
  as_key = as_key or false
  level = level or 0

  local repr

  if type(dumped_value) == "table" then
    if level < 2 then
      local entries = {}
      for key, value in pairs(dumped_value) do
        local key_repr = dump(key, true, level + 1)
        local value_repr = dump(value, false, level + 1)
        add(entries, key_repr.." = "..value_repr)
      end
      repr = "{"..joinstr_table(", ", entries).."}"
    else
      -- we already surround with [], so even if as_key, don't add extra []
      return "[table]"
    end
  else
    -- for most types
    repr = tostr(dumped_value)
  end

  -- non-string keys must be surrounded with [] (only once), string values with ""
  if as_key and type(dumped_value) ~= "string" and sub(repr, 1, 1) ~= "[" then
    repr = "["..repr.."]"
  elseif not as_key and type(dumped_value) == "string" then
    repr = "\""..repr.."\""
  end

  return repr
end
