--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

local memory = {
  -- emerald picked data is now stored in persistent data (dset/dget),
  --  so we start at index 0
  persistent_picked_emerald_index = 0
}

--(game_constants)
--#endif

return memory
