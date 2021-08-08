-- base class for custom game application
-- derive it for each cartridge

local gameapp = require("engine/application/gameapp")
local input = require("engine/input/input")

--#if tuner
local codetuner = require("engine/debug/codetuner")
--#endif

--#if profiler
local profiler = require("engine/debug/profiler")
--#endif

--#if visual_logger
local vlogger = require("engine/debug/visual_logger")
--#endif

--#if mouse
local mouse = require("engine/ui/mouse")
--#endif

--#if profiler_lightweight
local outline = require("engine/ui/outline")
--#endif

local visual = require("resources/visual_common")

local picosonic_app_base = derived_class(gameapp)

function picosonic_app_base:init()
  gameapp.init(self, fps60)
end

function picosonic_app_base:on_post_start() -- override
  extcmd("set_title","Pico Sonic")

  -- disable input auto-repeat (this is to be cleaner, as input module barely uses btnp anyway,
  --  and simply detects state changes using btn; if too many compressed chars, strip that first)
  poke(0x5f5c, -1)

--#if mouse
  -- enable mouse devkit
  input:toggle_mouse(true)
  mouse:set_cursor_sprite_data(visual.sprite_data_t.cursor)
--#endif
end

--#if itest
function picosonic_app_base:on_reset() -- override
--#if mouse
  mouse:set_cursor_sprite_data(nil)
--#endif
end
--#endif

-- TODO OPTIMIZE CHARS: support N || operations in preprocess.py (using manual parsing)
-- then add --#if profiler || visual_logger || tuner around the whole definition to strip it
-- completely from release
-- Same for on_render below
function picosonic_app_base:on_update() -- override
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

function picosonic_app_base:on_render() -- override
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
  -- always draw cursor on top of the rest (except for profiling)
  mouse:render()
--#endif

--#if profiler_lightweight
  -- when profiler is too heavy due to the whole UI module it uses, use this
  -- it is drawn after the rest so it can take mouse render into account if used in real game
  -- print total CPU
  outline.print_with_outline("cpu: "..stat(1), 2, 10, colors.orange, colors. black)
--#endif
end

return picosonic_app_base
