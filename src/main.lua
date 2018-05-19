require("debug")
local flow = require("flow")
local titlemenu = require("titlemenu")
local credits = require("credits")
local stage = require("stage")
local input = require("input")
local profiler = require("profiler")

-- config
profiler.active = true

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  input.toggle_mouse(true)

  flow:add_gamestate(titlemenu.state)
  flow:add_gamestate(credits.state)
  flow:add_gamestate(stage.state)
  flow:query_gamestate_type(titlemenu.state.type)
end

function _update60()
  flow:update()
end

function _draw()
  cls()
  flow.current_gamestate:render()

  if profiler.active then
    profiler:render()
  end
end
