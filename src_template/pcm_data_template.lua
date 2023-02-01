--#if busted
-- picotool listrawlua doesn't support some unicode chars like 0x7f and will replace most glyphs with
-- underscores '_' anyway, so only use this data directly in busted tests, and indirectly in
-- main_generate_gfx_sage_choir_pcm_data.lua via post-process constant symbol replacement
-- (the data itself will be stripped), after minify (which uses p8tool listrawlua).
-- To do so, use replace_strings in postbuild step by passing --game-constant-module-paths-postbuild path/to/pcm_data.lua
-- to build_cartridge.sh
-- Note that this is still only used to store the pcm as gfx data offline, and never used in build.
-- Remember to protect all member names with '_' prefix, so that they are not minified until they are replaced.
-- In theory we should also protect module itself as '_pcm_data', but in practice, since this is stripped from unify build,
-- the pcm_data usage in main_generate_gfx_sage_choir_pcm_data is considered like a global and therefore not minified,
-- so this is not required.
--
-- The data string is filled at pre-build time by running convert_audio_to_pcm_data.sh to convert an audio file
-- into a string, then injected into a template of this file via '$variable' substitution
local pcm_data = {
  _sage_choir = "$sage_choir"
}
--#endif

return pcm_data
