-- main entry file for the sandbox cartridge
--  game states: none, it's a custom cartridge just for testing

-- must require at main top, to be used in any required modules from here
require("engine/common")
require("common_sandbox")

require("engine/render/sprite")

require("resources/visual_ingame_addon")

local input = require("engine/input/input")
local visual = require("resources/visual_common")

local codetuner = require("engine/debug/codetuner")

--#if mouse
local mouse = require("engine/ui/mouse")
--#endif

-- caveats

-- (note: must require math for this to work)
-- syntax error: malformed number near 27..d
-- this error will block the output stream, getting picotest stuck!
-- printh(27..vector(11, 45))  -- incorrect
-- correct:
-- printh("27"..vector(11, 45))
-- or
-- printh(tostr(27)..vector(11, 45))

-- s = [[
-- 1

-- 2]]

-- lines = strspl(s, "\n")

-- COMMENT
--[[BLOCk
COMMENT]]
-- for line in all(lines) do
--   print("line: "..line)
-- end

--[[
--]]

-- test spr_r90
-- require("engine/render/sprite_rotate90")
local pc_sprite_data = require("data/playercharacter_sprite_data")

local function draw_sprite()
  spr_r90(12, 8, 64, 64, 2, 2, false, false, 0, 0, 0, 2)
end

local draw_mode = 0
local angle = 0
local scale = 1

function _init()
--#if tuner
  codetuner:show()
  codetuner.active = true
--#endif

--#if mouse
  -- enable mouse devkit
  printh("codetuner.active: "..nice_dump(codetuner.active))
  input:toggle_mouse(true)
  mouse:set_cursor_sprite_data(visual.sprite_data_t.cursor)
--#endif
end

function _update60()
  input:toggle_mouse(true)

  if btnp(button_ids.o) then
    draw_mode = (draw_mode + 1) % 5
  end

  if btnp(button_ids.left) then
    angle = (angle + 0.25) % 1
  end

  if btnp(button_ids.right) then
    angle = (angle - 0.25) % 1
  end

  if btnp(button_ids.down) then
    scale = scale + 0.25
  end

  if btnp(button_ids.up) then
    scale = scale - 0.25
  end

--#if tuner
  codetuner:update_window()
--#endif
end

function _draw()
  cls()

  if draw_mode == 0 then
    visual.sprite_data_t.spring:render(vector(64, 64), false, false, angle)
  elseif draw_mode == 1 then
    -- spring up (stage1 spritesheet)
    spr_r90(10, 4, 64, 64, 2, 1, false, false, tuned("px", 10), tuned("py", 2), angle, 2)
  elseif draw_mode == 2 then
    palt(2)
    spr(4*16 + 10, 64 - tuned("px", 10), 64 - tuned("py", 2), 2, 1, false, false)
    palt()
  elseif draw_mode == 3 then
    spr_r(10, 4, 64, 64, 2, 1, false, false, tuned("px", 10), tuned("py", 2), angle, 2)
  elseif draw_mode == 4 then
    spr_r90(10, 4, 64 + tuned("dx", 0), 64 + tuned("dy", 0), 2, 1, false, false, tuned("px", 10), tuned("py", 2), angle, 2)
  end

  visual.sprite_data_t.spring:render(vector(20, 20), false, false, 0, scale)

  api.print("draw_mode: "..draw_mode, 80, 80, colors.orange)
  api.print("angle: "..angle, 80, 90, colors.orange)

--#if tuner
  codetuner:render_window()
--#endif

--#if mouse
  -- always draw cursor on top of the rest (except for profiling)
  mouse:render()
--#endif
end
