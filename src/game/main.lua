local gameapp = require("game/application/gameapp")
local profiler = require("engine/debug/profiler")
local codetuner = require("engine/debug/codetuner")

--#if debug
profiler:show()
codetuner:show()
codetuner.active = true
--#endif

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  gameapp.init()
end

function _update60()
  gameapp.update()
end

function _draw()
  gameapp.draw()
end
