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
local log_msg = new_struct()
logging.log_msg = log_msg

-- level     logging.level  importance level of the message
-- text      string         textual content
-- category  string         category in which the message belongs to (see logger.active_categories)
function log_msg:_init(level, category, text)
  self.level = level
  self.category = category
  self.text = text
end

--#if log
function log_msg:_tostring()
  return "log_msg("..joinstr(", ", self.level, dump(self.category), dump(self.text))..")"
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
-- log         function(self, lm: log_msg)   external callback on log message received
-- on_log      function(self, lm: log_msg)   internal callback on log message received, only called if active
local log_stream = singleton(function (self)
  self.active = true
end)
logging.log_stream = log_stream

function log_stream:log(lm)
  if self.active then
    self:on_log(lm)
  end
end

-- abstract
-- function log_stream:on_log()
-- end


-- console log
console_log_stream = derived_singleton(log_stream)
logging.console_log_stream = console_log_stream

function console_log_stream:on_log(lm)
  printh(logging.compound_message(lm))
end


-- file log
file_log_stream = derived_singleton(log_stream, function (self)
  self.file_prefix = "game"  -- override this to distinguish logs between games and versions
end)
logging.file_log_stream = file_log_stream

function file_log_stream:clear()
  -- clear file by printing nothing while overwriting content
  -- note: this will print an empty line at the beginning of the file
  printh("", self.file_prefix.."_log", true)
end

function file_log_stream:on_log(lm)
  -- pico8 will add .p8l extension
  printh(logging.compound_message(lm), self.file_prefix.."_log")
end


local logger = singleton(function (self)
  self.active_categories = {
    default = true,
    flow = true,
    player = true,
    ui = true,
    codetuner = true,
    itest = true,
    -- trace is considered a category, not a level, so we can toggle it independently from the rest
    trace = false
  }
  self.current_level = logging.level.info
  self.dump_max_recursion_level = 5

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

-- level     logging.level
-- category  str
-- content   str
function logger:_generic_log(level, category, content)
  category = category or "default"
  if logger.active_categories[category] and logger.current_level <= level then
    local lm = log_msg(level, category, stringify(content))
    for stream in all(self._streams) do
      stream:log(lm)
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

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

This is only here to allow dump and nice_dump functions to be deterministic
by dumping elements with sorted keys (with an optional argument, as this is only possible
if the keys are comparable), hence easier to debug and test.

Source: http://lua-users.org/wiki/SortedIteration
Modification:
- updated API for modern Lua (# instead of getn)
]]

local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex)
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex(t)
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

local function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end


--[[
return a precise variable content, including table entries.

for sequence containing nils, nil is not shown but nil's index will be skipped

if as_key is true and t is not a string, surround it with []

by default, table recursion will stop at a call depth of logger.dump_max_recursion_level
however, you can pass a custom number of remaining levels to see more

if use_tostring is true, use any implemented _tostring method for tables
you can also use dump on strings just to surround them with quotes


if sorted_keys is true, dump will try to sort the entries by key
only use this if you are sure that all the keys are comparable
(e.g. only numeric or only strings)
--]]
function dump(dumped_value, as_key, level, use_tostring, sorted_keys)
  if as_key == nil then
    as_key = false
  end

  level = level or logger.dump_max_recursion_level

  if use_tostring == nil then
    use_tostring = false
  end

  if sorted_keys == nil then
    sorted_keys = false
  end

  local repr

  if type(dumped_value) == "table" then
    if use_tostring and dumped_value._tostring then
      repr = dumped_value:_tostring()
    else
      if level > 0 then
        local entries = {}
        local pairs_callback = sorted_keys and orderedPairs or pairs
        for key, value in pairs_callback(dumped_value) do
          local key_repr = dump(key, true, level - 1, use_tostring, sorted_keys)
          local value_repr = dump(value, false, level - 1, use_tostring, sorted_keys)
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
function nice_dump(value, sorted_keys)
  return dump(value, false, nil, true, sorted_keys)
end

return logging

--#endif
