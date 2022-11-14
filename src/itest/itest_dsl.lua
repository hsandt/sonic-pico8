--[[ itest domain-specific language definition and parser

usage example:

```
itest_dsl_parser.register('debug move right', [[
@stage #
...
###

warp 4 8
move right
wait 30
expect pc_bottom_pos 14. 8.
```

list of commands:

warp x y              warp player character bottom to (x, y)
set_motion_mode mode  set motion mode (do it before warping to avoid
                        unwanted position adjustment on arrival)
move dir              set sticky pc move intention toward [dir]
wait n                wait [n] frames
expect gp_value_type  expect a gameplay value to be equal to (...)
      (value params...)

--]]

local integration_test = require("engine/test/integration_test")
local itest_manager = require("engine/test/itest_manager")
local time_trigger = require("engine/test/time_trigger")

local tilemap = require("engine/data/tilemap")

-- dsl interpretation requirements
local flow = require("engine/application/flow")
local input = require("engine/input/input")

local player_char = require("ingame/playercharacter")

local tile_repr = require("test_data/tile_representation")
--#if busted
local tile_test_data = require("test_data/tile_test_data")
--#endif

-- helper function to access stage_stage quickly if current state
-- is stage, as it is not a singleton anymore
local function get_current_state_as_stage()
  if flow.curr_state then
    if flow.curr_state.type == ':stage' then
      return flow.curr_state
    end
    assert(false, "current state is "..flow.curr_state.type..", expected ':stage'")
  end
  assert(false, "current state is nil, expected stage_state")
end


-- module
local itest_dsl = {}

-- declare local at top-level to ensure there are accessible in methods below
local value_parsers
local executors
local evaluators
local setters

-- struct holding data on a gameplay value for expectations

-- attributes
-- name             string           descriptive name of the gameplay value (to debug failing itests)
-- parsable_type    parsable_type    type of gameplay value (for expected args parsing)
local gameplay_value_data = new_struct()
itest_dsl.gameplay_value_data = gameplay_value_data

function gameplay_value_data:init(name, parsable_type, eval)
  self.name = name
  self.parsable_type = parsable_type
end


-- Type of variables that can be parsed
-- We use enum so names are protected and we can support runtime parsing of
--  parsable types strings.
parsable_types = enum {
  "none",
  "number",
  "vector",
  "horizontal_dir",
  "control_mode",
  "motion_mode",
  "motion_state",
  "button_id",
  "gp_value",  -- meta-type compounded of [gp_value_type, gp_value_args...] where gp_value_args depend on gp_value_type
}

-- Protected enums: map hardcoded strings to members, to support runtime parsing even when member names are minified on the original enums
-- We could also use the enum {} helper as with parsable_types
horizontal_dirs_protected = {
  ["left"] = 1,
  ["right"] = 2
}

control_modes_protected = {
  ["human"] = 1,      -- player controls character
  ["puppet"] = 3,     -- itest script controls character
  ["ai"] = 3,         -- ai controls character
}

motion_modes_protected = {
  ["platformer"] = 1, -- normal in-game
  ["debug"] = 2       -- debug "fly" mode
}

motion_states_protected = {
  ["standing"]     = 1,  -- character is idle or running on the ground
  ["falling"]      = 2,  -- character is falling in the air, but not spinning
  ["air_spin"]     = 3,  -- character is in the air after a jump
  ["rolling"]      = 4,  -- character is rolling on the ground
  ["crouching"]    = 5,  -- character is crouching on the ground
  ["spin_dashing"] = 6,  -- character is charging spin dash
}

button_ids_protected = {
  ["left"] = 0,
  ["right"] = 1,
  ["up"] = 2,
  ["down"] = 3,
  ["o"] = 4,
  ["x"] = 5
}


--#if assert
parsable_type_strings = invert_table(parsable_types)
--#endif


-- Note: enums below have protected string keys to support aggressive minification
-- When done everywhere though, it makes more sense to just use strings
-- Keeping the enums around allows to track the list of supported values,
-- but consider using direct strings and listing possible values in comment.
-- The only benefit is to index other tables with enum values (so integers) rather than strings,
-- but if we have a table with string keys we do some hashing at some point anyway.

-- type of commands available
-- those names are parsed at runtime for DSL, so we don't want to minify them
--  and using enum {} is fine
command_types = enum {
  "warp",             -- warp player character bottom  args: {bottom_position: vector}
  "set",              -- set gameplay value            args: {gp_value_type_str: string, new_value_args...: matching gp value parsable type}
  "set_control_mode", -- set control mode              args: {control_mode_str: control_modes key}
  "set_motion_mode",  -- set motion mode               args: {motion_mode_str: motion_modes key}
  "move",             -- set sticky pc move intention  args: {move_dir_str: horizontal_dirs key}
  "stop",             -- stop moving horizontally      args: {}
  "jump",             -- start and hold jump           args: {}
  "stop_jump",        -- stop any jump intention       args: {}
  "crouch",           -- set sticky pc move intention y to 1
                      --                               args: {}
  "stop_crouch",      -- clear move intention y        args: {}
  "press",            -- press and hold button         args: {button_id_str: button_ids key}
  "release",          -- release button                args: {button_id_str: button_ids key}
  "wait",             -- wait some frames              args: {frames: int}
  "expect",           -- expect a gameplay value       args: {gp_value_type: gp_value_types, expected_args...: matching gp value parsable type}
}

--#if assert
command_type_strings = invert_table(command_types)
--#endif

-- argument types expected after those commands, indexed by command type
command_arg_types = {
  --[[warp]]             parsable_types["vector"],
  --[[set]]              parsable_types["gp_value"],
  --[[set_control_mode]] parsable_types["control_mode"],
  --[[set_motion_mode]]  parsable_types["motion_mode"],
  --[[move]]             parsable_types["horizontal_dir"],
  --[[stop]]             parsable_types["none"],
  --[[jump]]             parsable_types["none"],
  --[[stop_jump]]        parsable_types["none"],
  --[[crouch]]           parsable_types["none"],
  --[[stop_crouch]]      parsable_types["none"],
  --[[press]]            parsable_types["button_id"],
  --[[release]]          parsable_types["button_id"],
  --[[wait]]             parsable_types["number"],
  --[[expect]]           parsable_types["gp_value"],
}


-- type of gameplay values available for expectations
gp_value_types = enum {
  "pc_bottom_pos",   -- bottom position of player character
  "pc_velocity",     -- velocity of player character
  "pc_velocity_y",   -- y component of velocity of player character
  "pc_ground_spd",   -- ground speed of player character
  "pc_motion_state", -- motion state of player character
  "pc_slope",        -- current slope on which player character is grounded
}


-- data for each gameplay value type
local gp_value_data_t = {
  [gp_value_types["pc_bottom_pos"]]   = gameplay_value_data("player character bottom position", parsable_types["vector"]),
  [gp_value_types["pc_velocity"]]     = gameplay_value_data("player character velocity",        parsable_types["vector"]),
  [gp_value_types["pc_velocity_y"]]   = gameplay_value_data("player character velocity y",      parsable_types["number"]),
  [gp_value_types["pc_ground_spd"]]   = gameplay_value_data("player character ground speed",    parsable_types["number"]),
  [gp_value_types["pc_motion_state"]] = gameplay_value_data("player character motion state",    parsable_types["motion_state"]),
  [gp_value_types["pc_slope"]]        = gameplay_value_data("player character slope",           parsable_types["number"]),
}


-- parsing functions (start with _ to protect against member name minification)

function itest_dsl.parse_none(arg_strings)
  assert(#arg_strings == 0, "parse_none: got "..#arg_strings.." args, expected 0")
  return nil
end

function itest_dsl.parse_number(arg_strings)
  assert(#arg_strings == 1, "parse_number: got "..#arg_strings.." args, expected 1")
  return tonum(arg_strings[1])
end

function itest_dsl.parse_vector(arg_strings)
  assert(#arg_strings == 2, "parse_vector: got "..#arg_strings.." args, expected 2")
  return vector(tonum(arg_strings[1]), tonum(arg_strings[2]))
end

function itest_dsl.parse_horizontal_dir(arg_strings)
  assert(#arg_strings == 1, "parse_horizontal_dir: got "..#arg_strings.." args, expected 1")
  local horizontal_dir = horizontal_dirs_protected[arg_strings[1]]
  assert(horizontal_dir, "horizontal_dirs_protected["..arg_strings[1].."] is not defined")
  return horizontal_dir
end

function itest_dsl.parse_control_mode(arg_strings)
  assert(#arg_strings == 1, "parse_control_mode: got "..#arg_strings.." args, expected 1")
  local control_mode = control_modes_protected[arg_strings[1]]
  assert(control_mode, "control_modes_protected["..arg_strings[1].."] is not defined")
  return control_mode
end

function itest_dsl.parse_motion_mode(arg_strings)
  assert(#arg_strings == 1, "parse_motion_mode: got "..#arg_strings.." args, expected 1")
  local motion_mode = motion_modes_protected[arg_strings[1]]
  assert(motion_mode, "motion_modes_protected["..arg_strings[1].."] is not defined")
  return motion_mode
end

function itest_dsl.parse_motion_state(arg_strings)
  assert(#arg_strings == 1, "parse_motion_state: got "..#arg_strings.." args, expected 1")
  local motion_state = motion_states_protected[arg_strings[1]]
  assert(motion_state, "motion_states_protected["..arg_strings[1].."] is not defined")
  return motion_state
end

function itest_dsl.parse_button_id(arg_strings)
  assert(#arg_strings == 1, "parse_button_id: got "..#arg_strings.." args, expected 1")
  local button_id = button_ids_protected[arg_strings[1]]
  assert(button_id, "button_ids_protected["..arg_strings[1].."] is not defined")
  return button_id
end

function itest_dsl.parse_gp_value(arg_strings)
  assert(#arg_strings > 1, "parse_gp_value: got "..#arg_strings.." args, expected at least 2")
  -- same principle as itest_dsl_parser.parse, the type of the first arg
  --  determines how we parse the rest of the args, named "value components"
  local gp_value_type_str = arg_strings[1]
  -- gather all the value components as strings (e.g. {"3", "4"} for vector(3, 4))
  local gp_value_comps = {}
  for i = 2, #arg_strings do
    add(gp_value_comps, arg_strings[i])
  end
  -- determine the type of value reference tested for comparison (e.g. pc position)
  local gp_value_type = gp_value_types[gp_value_type_str]
  assert(gp_value_type, "gp_value_types['"..gp_value_type_str.."'] is not defined")
  -- parse the value components to semantical type (e.g. vector)
  local gp_value_data = gp_value_data_t[gp_value_type]
  assert(gp_value_data, "gp_value_data_t["..gp_value_type.."] (for '"..gp_value_type_str.."') is not defined")
  local gp_value_parser = value_parsers[gp_value_data.parsable_type]
  assert(gp_value_parser, "no value parser defined for gp value type '"..parsable_type_strings[gp_value_data.parsable_type].."'")
  local gp_value = gp_value_parser(gp_value_comps)
  return gp_value_type_str, gp_value
end

-- table of parsers for command args and gameplay values, indexed by parsable type
-- local, but declared at top of module
value_parsers = {
  itest_dsl.parse_none,
  itest_dsl.parse_number,
  itest_dsl.parse_vector,
  itest_dsl.parse_horizontal_dir,
  itest_dsl.parse_control_mode,
  itest_dsl.parse_motion_mode,
  itest_dsl.parse_motion_state,
  itest_dsl.parse_button_id,
  itest_dsl.parse_gp_value
}

-- functions to execute dsl commands. they take the dsl parser as 1st parameter
-- so they can update its state if needed

function itest_dsl.execute_warp(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char:warp_bottom_to(args[1])

  -- immediately move camera to player (don't rely on update_camera which may have smoothing later)
  --  and reload map region there
  -- this trick is needed for itests that last only 1 frame (like spring bounce),
  --  so the colliders in the warp region are correctly set and ground reactions work
  local new_cam_pos_x = mid(screen_width / 2, current_stage_state.player_char.position.x, current_stage_state.curr_stage_data.tile_width * tile_size - screen_width / 2)
  local new_cam_pos_y = mid(screen_height / 2, current_stage_state.player_char.position.y, current_stage_state.curr_stage_data.tile_height * tile_size - screen_height / 2)
  current_stage_state.camera:init_position(vector(new_cam_pos_x, new_cam_pos_y))

  current_stage_state:check_reload_map_region()
end

function itest_dsl.execute_set(args)
  local gp_value_type_str, new_gp_value = unpack(args)
  local gp_value_type = gp_value_types[gp_value_type_str]
  assert(gp_value_type, "gp_value_types["..gp_value_type_str.."] is not defined")
  local setter = setters[gp_value_type]
  assert(setter, "setter for "..gp_value_type_str.." is not defined")
  setter(new_gp_value)
end

function itest_dsl.execute_set_control_mode(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.control_mode = args[1]
end

function itest_dsl.execute_set_motion_mode(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char:set_motion_mode(args[1])
end

function itest_dsl.execute_move(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.move_intention = horizontal_dir_vectors[args[1]]
end

function itest_dsl.execute_stop(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.move_intention = vector.zero()
end

function itest_dsl.execute_jump(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.jump_intention = true  -- will be consumed
  current_stage_state.player_char.hold_jump_intention = true
end

function itest_dsl.execute_stop_jump(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.hold_jump_intention = false
end

function itest_dsl.execute_crouch(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.move_intention.y = 1
end

function itest_dsl.execute_stop_crouch(args)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.move_intention.y = 0
end

function itest_dsl.execute_press(args)
  -- simulate sticky press for player 0
  input.simulated_buttons_down[0][args[1]] = true
end

function itest_dsl.execute_release(args)
  -- simulate release for player 0
  input.simulated_buttons_down[0][args[1]] = false
end

-- wait and expect are not timed actions and will be handled as special cases

-- executor table, indexed by command type
-- contains one entry per command, except special commands wait and expect
-- local, but declared at top of module
executors = {
  itest_dsl.execute_warp,
  itest_dsl.execute_set,
  itest_dsl.execute_set_control_mode,
  itest_dsl.execute_set_motion_mode,
  itest_dsl.execute_move,
  itest_dsl.execute_stop,
  itest_dsl.execute_jump,
  itest_dsl.execute_stop_jump,
  itest_dsl.execute_crouch,
  itest_dsl.execute_stop_crouch,
  itest_dsl.execute_press,
  itest_dsl.execute_release
}


-- gameplay value evaluation functions

function itest_dsl.eval_pc_bottom_pos()
  local current_stage_state = get_current_state_as_stage()
  return current_stage_state.player_char:get_bottom_center()
end

function itest_dsl.eval_pc_velocity()
  local current_stage_state = get_current_state_as_stage()
  return current_stage_state.player_char.velocity
end

function itest_dsl.eval_pc_velocity_y()
  local current_stage_state = get_current_state_as_stage()
  return current_stage_state.player_char.velocity.y
end

function itest_dsl.eval_pc_ground_spd()
  local current_stage_state = get_current_state_as_stage()
  return current_stage_state.player_char.ground_speed
end

function itest_dsl.eval_pc_motion_state()
  local current_stage_state = get_current_state_as_stage()
  return current_stage_state.player_char.motion_state
end

function itest_dsl.eval_pc_slope()
  local current_stage_state = get_current_state_as_stage()
  return current_stage_state.player_char.slope_angle
end

-- evaluator table, indexed by gameplay value type
-- local, but declared at top of module
evaluators = {
  itest_dsl.eval_pc_bottom_pos,
  itest_dsl.eval_pc_velocity,
  itest_dsl.eval_pc_velocity_y,
  itest_dsl.eval_pc_ground_spd,
  itest_dsl.eval_pc_motion_state,
  itest_dsl.eval_pc_slope
}

--#if busted
-- only for define_final_assertion utest
itest_dsl.evaluators = evaluators
--#endif

-- gameplay value setters (only when setting value directly makes sense and is used by some itests)

function itest_dsl.set_pc_velocity(value)
  local current_stage_state = get_current_state_as_stage()
  -- value comes directly from the itest definition, make sure to copy assign
  --  or you will modify the value to set on further itests with actual pc velocity!
  current_stage_state.player_char.velocity:copy_assign(value)
end

function itest_dsl.set_pc_velocity_y(value)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.velocity.y = value
end

function itest_dsl.set_pc_ground_spd(value)
  local current_stage_state = get_current_state_as_stage()
  current_stage_state.player_char.ground_speed = value
end


-- type of gameplay values available for expectations
gp_value_types = enum {
  "pc_bottom_pos",   -- bottom position of player character
  "pc_velocity",     -- velocity of player character
  "pc_velocity_y",   -- y component of velocity of player character
  "pc_ground_spd",   -- ground speed of player character
  "pc_motion_state", -- motion state of player character
  "pc_slope",        -- current slope on which player character is grounded
}

-- setter table, indexed by gameplay value type
-- some setters are not used and therefore not implemented
-- local, but declared at top of module
setters = {
  nil,  -- pc_bottom_pos
  itest_dsl.set_pc_velocity,
  itest_dsl.set_pc_velocity_y,
  itest_dsl.set_pc_ground_spd,
  nil,  -- pc_motion_state
  nil,  -- pc_slope
}

-- command struct

-- attributes
-- type  command_types  type of command invoked
-- args  {*}            sequence of arguments
local command = new_struct()
itest_dsl.command = command

function command:init(cmd_type, args)
  self.type = cmd_type
  self.args = args
end


-- expectation struct

-- attributes
-- gp_value_type_str  string                             name of gameplay value to compare
-- expected_value     {type used for gp_value_type_str}  expected gameplay value
local expectation = new_struct()
itest_dsl.expectation = expectation

function expectation:init(gp_value_type_str, expected_value)
  self.gp_value_type_str = gp_value_type_str
  self.expected_value = expected_value
end


-- dsl itest struct

-- attributes
-- gamestate_type  string         gamestate type to start test in (also the only active gamestate)
-- stage_name      string|nil     stage name to play if gamestate type is ':stage', nil else
-- tilemap        tilemap|nil     tilemap data if gamestate type is ':stage', nil else
-- commands        {command}      sequence of commands to apply
local dsl_itest = new_struct()
itest_dsl.dsl_itest = dsl_itest

function dsl_itest:init()
  -- all attributes are initially nil (even commands, as we construct the table during parsing)
end


-- itest dsl parser singleton, with parser context state
-- itest               integration_test  current integration test in construction
-- last_time_trigger   time_trigger      last time trigger registered with wait command
-- final_expectations  {expectation}     sequence of expectations to verify
local itest_dsl_parser = singleton(function (self)
  self.itest = nil
  self.last_time_trigger = nil
  self.final_expectations = {}
end)
itest_dsl.itest_dsl_parser = itest_dsl_parser

-- parse, create and register itest from dsl
function itest_dsl_parser.register(name, dsli_source)
  local dsli = itest_dsl_parser.parse(dsli_source)
  local test = itest_dsl_parser.create_itest(name, dsli)
  itest_manager:register(test)
end

-- parse a dsl itest source and return a dsl itest
-- an itest is defined by a scenario and expectations
-- a dsl itest is split into 2 parts:
--  1. gamestate definition
--  2. action sequence and expectations
-- ex:
-- [[
-- @stage #                     < gamestate ':stage' with tag '#' for custom
-- ...                          < for custom stage, provide the tilemap in ascii
-- ###                          < . for empty tile, # for full tile, etc.
--                              < blank after tilemap to mark the end
-- warp 4 8                     < initial setup (it's an action like any other)
-- move right                   < more actions...
-- wait 30                      < wait delays the next action (here, the nil action)
-- expect pc_bottom_pos 14. 8.  < expectation (only final assertion is supported)
-- ]]
function itest_dsl_parser.parse(dsli_source)
  -- create dsl itest
  local dsli = dsl_itest()

  -- split source lines (do not collapse \n so we can use blank lines as separator)
  local lines = split(dsli_source, '\n', --[[convert_numbers:]] false)

  -- parse in 2 steps: gamestate and action sequence
  local next_line_index
  dsli.gamestate_type, dsli.stage_name, dsli.tilemap, next_line_index = itest_dsl_parser.parse_gamestate_definition(lines)
  dsli.commands = itest_dsl_parser.parse_action_sequence(lines, next_line_index)

  return dsli
end

-- return gamestate type, stage_name, tilemap data and index of next line to parse so we can chain parsing
-- the format of the gamestate definition is:
-- @[gamestate] (stage_name|#)?   < 2nd part only if gamestate == ':stage', '#' for custom tilemap
-- [tilemap row 1]                < only for custom tilemap
-- ...
-- [tilemap row n]
--                                < blank after tilemap (or one-line gamestate definition) to mark the end
-- ?                              < we don't check what's after, just return this line's index
function itest_dsl_parser.parse_gamestate_definition(lines)
  -- parse first line to get state and optional stage
  local gamestate_header = lines[1]
  assert(sub(gamestate_header, 1, 1) == '@', "gamestate_header '"..gamestate_header.."' doesn't start with @")
  local header_parts = strspl(gamestate_header, ' ', true)
  local gamestate_type = ':'..sub(header_parts[1], 2)
  local stage_name = nil
  if gamestate_type == ':stage' then
    assert(#header_parts == 2)
    stage_name = header_parts[2]
  end

  local tm = nil
  local next_line_index = 3
  if stage_name == '#' then
    -- we are defining a custom tilemap, let's parse it
    tm, next_line_index = itest_dsl_parser.parse_tilemap(lines)
  end

  return gamestate_type, stage_name, tm, next_line_index
end

function itest_dsl_parser.parse_tilemap(lines)
  -- tilemap should always start at line 2
  -- first line will give the tilemap width
  assert(#lines >= 2, "only "..#lines.." line(s), need at least 2")

  local content = {}  -- sequence of sequence of tilemap symbols
  local width = 0     -- number of symbols per tilemap row

  for i = 2, #lines do
    local line_str = lines[i]

    -- ensure that line is either empty or made of one block of symbols with no spaces
    -- this step will also trim any extra space (e.g. from "   \" used to chain lines)
    local line_blocks = strspl(line_str, ' ', true)
    if #line_blocks == 0 then
      -- we reached the end of tilemap definition
      break
    end

    assert(#line_blocks == 1, "too many blocks: "..#line_blocks..", expected 1")
    local trimmed_line_str = line_blocks[1]
    if width == 0 then
      -- no width defined on first line (i == 2), store it now
       width = #trimmed_line_str
    else
      -- on further lines, check consistency
      assert(#trimmed_line_str == width, "inconsistent line length: "..#trimmed_line_str.." vs "..width)
    end


    local current_row = {}

    for j = 1, width do
      local tile_symbol = sub(trimmed_line_str, j, j)
      local tile_id = tile_repr.tile_symbol_to_ids[tile_symbol]
      assert(tile_id, "unknown tile symbol: "..tile_symbol)
      add(current_row, tile_id)
    end

    add(content, current_row)
  end

  -- return tilemap, next line = initial line index + nb rows + 1
  return tilemap(content), 2 + #content + 1
end


-- return a sequence of commands read in lines, starting at next_line_index
function itest_dsl_parser.parse_action_sequence(lines, next_line_index)
  local commands = {}
  for i = next_line_index, #lines do
    words = strspl(lines[i], ' ', true)
    -- if there are no words, the line is empty, so continue
    if #words > 0 then
      local cmd_type_str = words[1]
      local arg_strings = {}
      for j = 2, #words do
        add(arg_strings, words[j])
      end
      local cmd_type = command_types[cmd_type_str]
      assert(cmd_type, "no command type named '"..cmd_type_str.."'")
      local arg_parsable_type = command_arg_types[cmd_type]
      assert(arg_parsable_type, "no command arg type defined for command '"..command_type_strings[cmd_type].."'")
      local arg_parser = value_parsers[arg_parsable_type]
      assert(arg_parser, "no value parser defined for arg type '"..parsable_type_strings[arg_parsable_type].."'")
      local args = {arg_parser(arg_strings)}
      add(commands, command(cmd_type, args))
    end
  end
  return commands
end


-- create and return an itest from a dsli, providing a name
function itest_dsl_parser.create_itest(name, dsli)
  itest_dsl_parser.itest = integration_test(name, {dsli.gamestate_type})

  itest_dsl_parser.itest.setup = function (app)
    -- disable object scan + spawn as it's very slow to iterate on the whole map
    --  at the beginning of each test
    -- if later you add a test to specifically test objects, just add a flag in the DSL
    --  like @stage #with_objects to still enable object scan + spawn
    -- note that we do this even if dsli.gamestate_type is not stage,
    --  as itests in titlemenu may enter stage and we don't want to waste time
    --  when entering stage state at the end of the itest
    flow.gamestates[':stage'].enable_spawn_objects = false

    flow:change_gamestate_by_type(dsli.gamestate_type)
    if dsli.gamestate_type == ':stage' then
      -- puppet control
      local current_stage_state = get_current_state_as_stage()
      current_stage_state.player_char.control_mode = control_modes.puppet
      if dsli.stage_name == '#' then
        -- load tilemap data and build it from ascii
--#if busted
        tile_test_data.setup()
--#endif
        dsli.tilemap:load()
      else
        -- load stage by name when api is ready
      end
    end
  end

  itest_dsl_parser.itest.teardown = function ()
    -- clear map
    -- no need to "unload" the game state, the next test will reset the flow anyway
    if dsli.gamestate_type == ':stage' then
      if dsli.stage_name == '#' then
        -- clear tilemap and unload tilemap data
        tilemap.clear_map()
--#if busted
        tile_test_data.teardown()
--#endif
      end
    end
  end

  for cmd in all(dsli.commands) do
    if cmd.type == command_types["wait"] then
      itest_dsl_parser:wait(cmd.args[1])

    elseif cmd.type == command_types["expect"] then
      -- we currently don't support live assertions, but we support multiple
      -- final expectations
      add(itest_dsl_parser.final_expectations, expectation(cmd.args[1], cmd.args[2]))

    else
      -- common action, store callback for execution during
      itest_dsl_parser:act(function ()
        -- in Lua the cmd below is really the cmd for this iteration, don't worry about it
        --  changing in the loop as it won't affect the one of the callback when called later
        local executor = executors[cmd.type]
        assert(executor, "executors["..cmd.type.."] (for '"..command_type_strings[cmd.type].."') is not defined")
        executor(cmd.args)
      end)
    end
  end

  -- if we finished with a wait (with or without final assertion),
  --  we need to close the itest with a wait-action
  if itest_dsl_parser.last_time_trigger then
    itest_dsl_parser.itest:add_action(itest_dsl_parser.last_time_trigger, nil)
    itest_dsl_parser.last_time_trigger = nil  -- consume and cleanup for next itest
  end

  -- glue code to remain retro-compatible with function-based final assertion
  itest_dsl_parser:define_final_assertion()

  local test = itest_dsl_parser.itest
  itest_dsl_parser.itest = nil  -- consume and cleanup for next itest

  return test
end

-- glue code for old callback-based system
-- the time trigger system makes actions and waiting asymmetrical,
--  as waiting is not an action but adds a parameter to the next action,
--  and requires nil actions to chain waiting (they don't even merge)
-- prefer a flat sequence of generic actions that can be actual gameplay
--  changes or waiting. when waiting, just skip frames until waiting ends,
--  at which point you can apply all further actions immediately, until
--  a new wait action is found.
function itest_dsl_parser:act(callback)
  if self.last_time_trigger then
    self.itest:add_action(self.last_time_trigger, callback)
    self.last_time_trigger = nil  -- consume so we know no final wait-action is needed
  else
    -- no wait since last action (or this is the first action), so use immediate trigger
    self.itest:add_action(time_trigger.immediate(), callback)
  end
end

function itest_dsl_parser:wait(interval)
  if self.last_time_trigger then
    -- we were already waiting, so finish last wait with empty action
    self.itest:add_action(self.last_time_trigger, nil)
  end
  -- we only support frame unit in the dsl
  self.last_time_trigger = time_trigger(interval, true)
end


-- define final assertion based on sequence of final expectations
-- this is a glue method to make it retro-compatible with the function-based final assertion
-- eventually, the itest will only hold expectations (possibly predefined functions for currying)
--  to avoid creating lambda
function itest_dsl_parser:define_final_assertion()
  -- define an intermediate local variable to avoid the "local variable closure issue"
  --  i.e. if we access "self.final_expectations" directly from inside the function
  --  constructed below, it would get the actual value of self.final_expectations
  --  at evaluation time (too late, the temporary table reference would have been lost
  --  and the table gc-ed). So we either need to copy the table content (then clear table)
  --  or store the reference in an intermediate variable like this one (then create new table)
  local final_expectations_proxy = self.final_expectations
  self.final_expectations = {}  -- consume and cleanup for next itest

  self.itest.final_assertion = function ()
    local success = true
    local full_message = ""

    -- check each expectation one by one
    for exp in all(final_expectations_proxy) do
      local gp_value_type = gp_value_types[exp.gp_value_type_str]
      assert(gp_value_type, "gp_value_types["..exp.gp_value_type_str.."] is not defined")
      local evaluator = evaluators[gp_value_type]
      assert(evaluator, "evaluators["..gp_value_type.."] (for '"..exp.gp_value_type_str.."') is not defined")
      local gp_value = evaluator()
--[[#pico8
      -- in pico8, we use fixed point precision, which is what we expect as final values
      -- however, precomputing 16.16 fixed precision values by hand is very hard,
      --  so I may end up using the same approx as with busted below
      local value_success, value_eq_message = eq_with_message(exp.expected_value, gp_value)
--#pico8]]
--#if busted
      -- with busted, we use float point precision, which gives us slightly different values
      -- unfortunately, the error accumulates over time, and position integrates from speed from accel,
      --  so depending on the simulation time and the gameplay value type, the error threshold will vary
      -- to be safe, we use 1/64 (0.015) although 1/256 is often enough)
      -- with the new to_fixed_point() function however, try to use it when busted may differ from PICO-8
      --  so ultimately we don't even need almost_eq and just use eq_with_message
      local value_success, value_eq_message = almost_eq_with_message(exp.expected_value, gp_value, 1/64)
--#endif
      if not value_success then
        success = false
        local gp_value_data = gp_value_data_t[gp_value_type]
        assert(gp_value_data, "gp_value_data_t["..gp_value_type.."] is not defined")
        local gp_value_name = gp_value_data.name
        local value_message = "\nFor gameplay value '"..gp_value_name.."':\n"..value_eq_message
        full_message = full_message..value_message.."\n"
      end
    end

    return success, full_message
  end
end

return itest_dsl
