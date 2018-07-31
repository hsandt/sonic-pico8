--#if log

require("engine/core/class")
require("engine/core/helper")

local logging = {
  level = {
    info = 1,     -- show all messages
    warning = 2,  -- show warnings and errors
    error = 3,    -- show errors only
    none = 4,     -- show nothing
  }
}

-- log message struct
local log_message = new_struct()
logging.log_message = log_message

-- level     logging.level  importance level of the message
-- text      string         textual content
-- category  string         category in which the message belongs to (see logger.active_categories)
function log_message:_init(level, category, text)
  self.level = level
  self.category = category
  self.text = text
end

--#if log
function log_message:_tostring()
  return "log_message("..joinstr(", ", self.level, dump(self.category), dump(self.text))..")"
end
--#endif

function logging.compound_message(lm)
  if lm.level == logging.level.warning then
    prefix = "warning: "
  elseif lm.level == logging.level.error then
    prefix = "error: "
  else
    prefix = ""
  end
  return "["..lm.category.."] "..prefix..lm.text
end

-- log stream abstract singleton
-- active      boolean                           is the stream active? is false, all output is muted
-- on_log      function(self, lm: log_message)   callback on log message received
local log_stream = singleton(function (self)
  self.active = true
end)
logging.log_stream = log_stream

-- abstract
-- function log_stream:on_log()
-- end

console_log_stream = derived_singleton(log_stream)
logging.console_log_stream = console_log_stream

function console_log_stream:on_log(lm)
  printh(logging.compound_message(lm))
end

local logger = singleton(function (self)
  self.active_categories = {
    default = true,
    flow = true,
    player = true,
    ui = true,
    codetuner = true,
    itest = true
  }
  self.current_level = logging.level.info
  self.dump_max_recursion_level = 2

  -- streams to log to
  self._streams = {}
end)

-- export
logging.logger = logger

-- set all categories active flag to false to mute logging
function logger:deactivate_all_categories()
  for category, _ in pairs(self.active_categories) do
    self.active_categories[category] = false
  end
end

-- register a stream toward which logging will be sent (console, file...)
function logger:register_stream(stream)
  assert(stream, "logger:register_stream: passed stream is nil")
  assert(type(stream.on_log) == "function" or type(stream.on_log) == "table" and getmetatable(stream.on_log).__call, "logger:register_stream: passed stream is invalid: on_log member is nil or not a callable")
  add(self._streams, stream)
end

function logger:_generic_log(level, category, content)
  category = category or "default"
  if logger.active_categories[category] and logger.current_level <= level then
    local lm = log_message(level, category, stringify(content))
    for stream in all(self._streams) do
      stream:on_log(lm)
    end
  end
end

-- print an info content to the console in a category string
function log(content, category)
  logger:_generic_log(logging.level.info, category, content)
end

-- print a warning content to the console in a category string
function warn(content, category)
  logger:_generic_log(logging.level.warning, category, content)
end

-- print an error content to the console in a category string
function err(content, category)
  logger:_generic_log(logging.level.error, category, content)
end

-- return a precise variable content, including table entries
-- for sequence containing nils, nil is not shown but nil's index will be skipped
-- if as_key is true and t is not a string, surround it with []
-- by default table recursion will stop at a call depth of logger.dump_max_recursion_level
-- however, you can pass a custom number of remaining levels to see more
-- if use_tostring is true, use any implemented _tostring method for tables
-- you can also use dump on strings just to surround them with quotes
function dump(dumped_value, as_key, level, use_tostring)
  as_key = as_key or false
  level = level or logger.dump_max_recursion_level
  use_tostring = use_tostring or false

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

-- dump using _tostring method when possible
function nice_dump(value)
  return dump(value, false, nil, true)
end

return logging

--#endif
