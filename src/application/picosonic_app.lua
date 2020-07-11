-- custom game application
-- used by main and itest_main

require("engine/application/constants")
local gameapp = require("engine/application/gameapp")
require("engine/core/class")
local input = require("engine/input/input")

--#if tuner
local codetuner = require("engine/debug/codetuner")
--#endif

--#if log
local logging = require("engine/debug/logging")
--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
--#endif

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
--#endif

--#if mouse
local ui = require("engine/ui/ui")
--#endif

local titlemenu = require("menu/titlemenu")
local credits = require("menu/credits")
local stage_state = require("ingame/stage_state")
local visual = require("resources/visual")

local picosonic_app = derived_class(gameapp)

function picosonic_app:_init()
  gameapp._init(self, fps60)
end

function picosonic_app:instantiate_gamestates() -- override
  return {titlemenu(), credits(), stage_state()}
end

--#if mouse
function picosonic_app:on_post_start() -- override
  -- enable mouse devkit
  input:toggle_mouse(true)
  ui:set_cursor_sprite_data(visual.sprite_data_t.cursor)
end
--#endif

function picosonic_app:on_reset() -- override
--#if mouse
  ui:set_cursor_sprite_data(nil)
--#endif
end

function picosonic_app:on_update() -- override
--#if profiler
  profiler.window:update()
--#endif

--#if visual_logger
  vlogger.window:update()
--#endif

--#if tuner
  codetuner:update_window()
--#endif
end

function picosonic_app:on_render() -- override
--#if profiler
  profiler.window:render()
--#endif

--#if visual_logger
  vlogger.window:render()
--#endif

--#if tuner
  codetuner:render_window()
--#endif

--#if mouse
  -- always draw cursor on top
  ui:render_mouse()
--#endif
end

return picosonic_app
