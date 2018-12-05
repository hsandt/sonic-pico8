--#if visual_logger

require("engine/core/class")
require("engine/core/datastruct")
require("engine/render/color")
local debug_window = require("engine/debug/debug_window")
local logging = require("engine/debug/logging")
local wtk = require("engine/wtk/pico8wtk")

local vlogger = {
  buffer_size = 5
}

vlogger.window = derived_singleton(debug_window, function (self)
  -- fixed size queue of logger messages
  self._msg_queue = circular_buffer(vlogger.buffer_size)
  -- vertical layout of log messages
  self.v_layout = wtk.vertical_layout.new(10, colors.dark_blue)
  self.gui:add_child(self.v_layout, 0, 98)
end)

-- push a log_msg lm to the visual log
-- caveat: the queue has a fixed size of messages rather than lines
--  so when the queue is full, full multiline messages will pop out although
--  in a normal console log, we would expect the lines to go out of view 1 by 1
function vlogger.window:push_msg(lm)
  local has_replaced = self._msg_queue:push(logging.log_msg(lm.level, lm.category, lm.text))

  self:_on_msg_pushed(lm)
  if has_replaced then
    self:_on_msg_popped()
  end
end

-- add a new label to the vertical layout
function vlogger.window:_on_msg_pushed(lm)
  local wrapped_text = wwrap(lm.text, 32)
  local log_label = wtk.label.new(wrapped_text, colors.white)
  self.v_layout:add_child(log_label)
end

-- remove the oldest label of the vertical layout
function vlogger.window:_on_msg_popped()
  assert(#self.v_layout.children >= 1, "vlogger.window:_on_msg_popped: no children in window.v_layout")
  self.v_layout:remove_child(self.v_layout.children[1])
end

local vlog_stream = derived_singleton(logging.log_stream)
vlogger.vlog_stream = vlog_stream

function vlog_stream:on_log(lm)
  vlogger.window:push_msg(lm)
end

return vlogger

--#endif
