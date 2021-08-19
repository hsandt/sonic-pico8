--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

local memory = {
  picked_emerald_address = 0x5dff
}

--(game_constants)
--#endif

return memory
