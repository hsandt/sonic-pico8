-- TODO OPTIMIZE CHARS: strip unless #game_constants since these will be substituted
-- in addition, we now have an automatic namespace constant parsing system,
--  so can be removed from game_substitute_table.py in exchange for adding this file to
--  game_constant_module_paths_string in build_single_cartridge.sh

-- enum for character control
control_modes = {
  human = 1,      -- player controls character
  puppet = 2     -- external code controls character (stop updating and use the last intentions set)
--#if itest
, ai = 3          -- ai controls character (precise behavior, currently unused and only referred to in tests)
--#endif
}

-- motion_modes and motion_states are accessed dynamically via variant name in itest_dsl
--  so we don't strip them away from pico8 builds
-- it is only used for debug and expectations, though, so it could be #if cheat/test only,
--  but the dsl may be used for attract mode later (dsl) so unless we distinguish
--  parsable types like motion_states that are only used for expectations (and cheat actions)
--  as opposed to actions, we should keep this in the release build

--#if cheat
-- enum for character motion mode
motion_modes = {
  platformer = 1, -- normal in-game
  debug = 2       -- debug "fly" mode
}
--#endif

-- enum for character motion state in platformer mode
motion_states = {
  standing     = 1,  -- character is idle or running on the ground
  falling      = 2,  -- character is falling in the air, but not spinning
  air_spin     = 3,  -- character is in the air after a jump
  rolling      = 4,  -- character is rolling on the ground
  crouching    = 5,  -- character is crouching on the ground
  spin_dashing = 6,  -- character is charging spin dash
}
