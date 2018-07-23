--#if log

require("engine/core/class")
require("engine/core/helper")

local logger = singleton {
  level = {
    log = 1,   -- show all messages
    warning = 2,  -- show warnings and errors
    error = 3, -- show errors only
    none = 4,  -- show nothing
  },

  active_categories = {
    default = true,
    flow = true,
    player = true,
    ui = true,
    codetuner = true,
    itest = true
  },

  current_level = nil
}

logger.current_level = logger.level.log

function logger:_tostring()
  return "[logger]"
end

-- print a log message to the console in a category string
function log(message, category)
  category = category or "default"
  if logger.active_categories[category] and logger.current_level <= logger.level.log then
    printh("["..category.."] "..stringify(message))
  end
end

-- print a warning message to the console in a category string
function warn(message, category)
  category = category or "default"
  if logger.active_categories[category] and logger.current_level <= logger.level.warning then
    printh("["..category.."] warning: "..stringify(message))
  end
end

-- print an error message to the console in a category string
function err(message, category)
  category = category or "default"
  if logger.active_categories[category] and logger.current_level <= logger.level.error then
    printh("["..category.."] error: "..stringify(message))
  end
end

logger.dump_max_recursion_level = 2

-- return a precise variable content, including table entries
-- for sequence containing nils, nil is not shown but nil's index will be skipped
-- if as_key is true and t is not a string, surround it with []
-- by default table recursion will stop at a call depth of logger.dump_max_recursion_level
-- however, you can pass a custom number of remaining levels to see more
-- if use_tostring is true, use any implemented _tostring method for tables
function dump(dumped_value, as_key, level, use_tostring)
  as_key = as_key or false
  level = level or logger.dump_max_recursion_level

  local repr

  if type(dumped_value) == "table" then
    if use_tostring and dumped_value._tostring then
      repr = dumped_value:_tostring()
    else
      if level > 0 then
        local entries = {}
        for key, value in pairs(dumped_value) do
          local key_repr = dump(key, true, level - 1, use_tostring)
          local value_repr = dump(value, false, level - 1, use_tostring)
          add(entries, key_repr.." = "..value_repr)
        end
        repr = "{"..joinstr_table(", ", entries).."}"
      else
        -- we already surround with [], so even if as_key, don't add extra []
        return "[table]"
      end
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

function nice_dump(value)
  return dump(value, false, nil, true)
end

return logger

--#endif
