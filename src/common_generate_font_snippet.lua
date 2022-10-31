-- Require all common generate_font_snippet modules
-- Really, this offline cartridge doesn't need anything, we only define it so we can support unify with
-- ordered_require_ below (but it seems to work even without)

--[[#pico8
--#if unity
-- When doing a unity build, all modules must be concatenated in dependency, with modules relied upon
--  above modules relying on them.

require("ordered_require_generate_font_snippet")

--#endif
--#pico8]]
