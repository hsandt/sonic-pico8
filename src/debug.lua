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
}

current_debug_level = debug_level.log

-- print a log message to the console in a category string
function log(message, category)
  category = category or "default"
  if active_debug_categories[category] and current_debug_level <= debug_level.log then
    printh("["..category.."] "..message)
  end
end

-- print a warning message to the console in a category string
function warn(message, category)
  category = category or "default"
  if active_debug_categories[category] and current_debug_level <= debug_level.warning then
    printh("["..category.."] "..message)
  end
end

-- print an error message to the console in a category string
function err(message, category)
  category = category or "default"
  if active_debug_categories[category] and current_debug_level <= debug_level.error then
    printh("["..category.."] "..message)
  end
end
