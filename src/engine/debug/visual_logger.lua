--#if visual_logger

require("engine/core/class")
require("engine/core/datastruct")
require("engine/render/color")
local debug_window = require("engine/debug/debug_window")
local logging = require("engine/debug/logging")
local wtk = require("engine/wtk/pico8wtk")

local visual_logger = {
  buffer_size = 5
}

visual_logger.window = derived_singleton(debug_window, function (self)
  -- fixed size queue of logger messages
  self._message_queue = circular_buffer(visual_logger.buffer_size)
  -- vertical layout of log messages
  self.v_layout = wtk.vertical_layout.new(10, colors.dark_blue)
  self.gui:add_child(self.v_layout, 0, 98)
end)

-- push a log_message lm to the visual log
-- caveat: the queue has a fixed size of messages rather than lines
--  so when the queue is full, full multiline messages will pop out although
--  in a normal console log, we would expect the lines to go out of view 1 by 1
function visual_logger.window:push_message(lm)
  local has_replaced = self._message_queue:push(logging.log_message(lm.level, lm.category, lm.text))

  self:_on_message_pushed(lm)
  if has_replaced then
    self:_on_message_popped()
  end
end

-- add a new label to the vertical layout
function visual_logger.window:_on_message_pushed(lm)
  local wrapped_text = wwrap(lm.text, 32)
  local log_label = wtk.label.new(wrapped_text, colors.white)
  self.v_layout:add_child(log_label)
end

-- remove the oldest label of the vertical layout
function visual_logger.window:_on_message_popped()
  assert(#self.v_layout.children >= 1, "visual_logger.window:_on_message_popped: no children in window.v_layout")
  self.v_layout:remove_child(self.v_layout.children[1])
end

local visual_log_stream = derived_singleton(logging.log_stream)
visual_logger.visual_log_stream = visual_log_stream

function visual_log_stream:on_log(lm)
  visual_logger.window:push_message(lm)
end

return visual_logger

--#endif
