require("engine/core/class")
require("engine/render/color")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local ui = require("engine/ui/ui")
local gamestate = require("game/application/gamestate")

local titlemenu = {}

-- game state
local titlemenustate = singleton(function (self)
  self.type = gamestate.types.titlemenu

  -- parameters

  -- number of items in the menu
  self.items_count = 2

  -- state vars

  -- current cursor index (0: start, 1: credits)
  self.current_cursor_index = 0
end)

function titlemenustate:on_enter()
  self.current_cursor_index = 0
end

function titlemenustate:on_exit()
end

function titlemenustate:update()
  if input:is_just_pressed(button_ids.up) then
    self:move_cursor_up()
  elseif input:is_just_pressed(button_ids.down) then
    self:move_cursor_down()
  elseif input:is_just_pressed(button_ids.x) then
    self:confirm_current_selection()
  end
end

function titlemenustate:render()
  color(colors.white)
  api.print("start", 4*11, 6*12)
  api.print("credits", 4*11, 6*13)
  api.print(">", 4*10, 6*(12+self.current_cursor_index))
end

function titlemenustate:move_cursor_up()
  -- move cursor up, clamped
  self.current_cursor_index = max(self.current_cursor_index - 1, 0)
end

function titlemenustate:move_cursor_down()
  -- move cursor down, clamped
  self.current_cursor_index = min(self.current_cursor_index + 1, self.items_count - 1)
end

function titlemenustate:confirm_current_selection()
  if self.current_cursor_index == 0 then
    flow:query_gamestate_type(gamestate.types.stage)
  else  -- current_cursor_index == 1
    flow:query_gamestate_type(gamestate.types.credits)
  end
end

-- export
titlemenu.state = titlemenustate
return titlemenu
