require("engine/core/helper")
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test = integrationtest.itest_manager, integrationtest.integration_test

local tile_data = require("game/data/tile_data")
local tilemap = require("engine/data/tilemap")

-- dsl interpretation requirements
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
local pc_data = require("game/data/playercharacter_data")


-- module
local itest_dsl = {}

local value_parsers
local executors
local evaluators

-- struct holding data on a gameplay value for expectations

-- attributes
-- name             string           descriptive name of the gameplay value (to debug failing itests)
-- parsable_type    parsable_type    type of gameplay value (for expected args parsing)
local gameplay_value_data = new_struct()
itest_dsl.gameplay_value_data = gameplay_value_data

function gameplay_value_data:_init(name, parsable_type, eval)
  self.name = name
  self.parsable_type = parsable_type
end


-- optimize tokens: if this is too much, remove proxy function tables
--  altogether and directly access functions via itest_dsl[prefix..type_name]
-- return table containing functions named {prefix}{enum_type_name}
--  inside a module, indexed by enum value
local function generate_function_table(module, enum_types, prefix)
  local t = {}
  for type_name, enum_type in pairs(enum_types) do
    t[enum_type] = module[prefix..type_name]
  end
  return t
end
--#if utest
itest_dsl.generate_function_table = generate_function_table
--#endif

-- type of variables that can be parsed
parsable_types = enum {
  "number",
  "vector",
  "horizontal_dir",
  "motion_state",
  "expect",  -- meta-type meaning we must check the 1st arg (gp_value_type) to know what the rest should be
}

--#if assert
parsable_type_strings = invert_table(parsable_types)
--#endif


-- type of commands available
command_types = enum {
  "warp",   -- warp player character bottom  args: {bottom_position: vector}
  "move",   -- set sticky pc move intention  args: {move_dir: horizontal_dirs}
  -- todo: stop, jump, crouch, spin_dash
  "wait",   -- wait some frames              args: {frames: int}
  "expect",  -- expect a gameplay value       args: {gp_value_type: gp_value_types, expected_args...: matching gp value parsable type}
}

--#if assert
command_type_strings = invert_table(command_types)
--#endif

-- argument types expected after those commands
command_arg_types = {
  [command_types.warp]   = parsable_types.vector,
  [command_types.move]   = parsable_types.horizontal_dir,
  [command_types.wait]   = parsable_types.number,
  [command_types.expect] = parsable_types.expect,
}


-- type of gameplay values available for expectations
gp_value_types = enum {
  "pc_bottom_pos",   -- bottom position of player character
  "pc_velocity",     -- velocity of player character
  "pc_ground_spd",   -- ground speed of player character
  "pc_motion_state", -- motion state of player character
}

--#if assert
gp_value_type_strings = invert_table(gp_value_types)
--#endif

-- data for each gameplay value type
local gp_value_data_t = {
  [gp_value_types.pc_bottom_pos] = gameplay_value_data("player character bottom position", parsable_types.vector),
  [gp_value_types.pc_velocity]   = gameplay_value_data("player character velocity",        parsable_types.vector),
  [gp_value_types.pc_ground_spd] = gameplay_value_data("player character ground speed",    parsable_types.number),
  [gp_value_types.pc_motion_state] = gameplay_value_data("player character motion state",  parsable_types.motion_state),
}


-- parsing functions

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
  local horizontal_dir = horizontal_dirs[arg_strings[1]]
  assert(horizontal_dir, "horizontal_dirs["..arg_strings[1].."] is not defined")
  return horizontal_dir
end

function itest_dsl.parse_motion_state(arg_strings)
  assert(#arg_strings == 1, "parse_motion_state: got "..#arg_strings.." args, expected 1")
  local motion_state = motion_states[arg_strings[1]]
  assert(motion_state, "motion_states["..arg_strings[1].."] is not defined")
  return motion_states[arg_strings[1]]
end

-- convert string args to vector
function itest_dsl.parse_expect(arg_strings)
  assert(#arg_strings > 1, "parse_expect: got "..#arg_strings.." args, expected at least 2")
  -- same principle as itest_dsl_parser.parse, the type of the first arg
  --  determines how we parse the rest of the args, named "value components"
  local gp_value_type_str = arg_strings[1]
  -- gather all the value components as strings (e.g. {"3", "4"} for vector(3, 4))
  local expected_value_comps = {}
  for i = 2, #arg_strings do
    add(expected_value_comps, arg_strings[i])
  end
  -- determine the type of value reference tested for comparison (e.g. pc position)
  local gp_value_type = gp_value_types[gp_value_type_str]
  assert(gp_value_type, "gp_value_types['"..gp_value_type_str.."'] is not defined")
  -- parse the value components to semantical type (e.g. vector)
  local gp_value_data = gp_value_data_t[gp_value_type]
  assert(gp_value_data, "gp_value_data_t["..gp_value_type.."] (for '"..gp_value_type_str.."') is not defined")
  local expected_value_parser = value_parsers[gp_value_data.parsable_type]
  assert(expected_value_parser, "no value parser defined for gp value type '"..parsable_type_strings[gp_value_data.parsable_type].."'")
  local expected_value = expected_value_parser(expected_value_comps)

  return gp_value_type, expected_value
end

-- table of parsers for command args and gameplay values, indexed by parsed type
value_parsers = generate_function_table(itest_dsl, parsable_types, "parse_")
itest_dsl.value_parsers = value_parsers


-- functions to execute dsl commands. they take the dsl parser as 1st parameter
-- so they can update its state if needed

function itest_dsl.execute_warp(args)
  stage.state.player_char:warp_bottom_to(args[1])
end

function itest_dsl.execute_move(args)
      stage.state.player_char.move_intention = horizontal_dir_vectors[args[1]]
end

-- wait and expect are not timed actions and will be handled as special cases

-- table of functions to call when applying a command with args, indexed by command type
executors = generate_function_table(itest_dsl, command_types, "execute_")
itest_dsl.executors = executors


-- gameplay value evaluation functions

function itest_dsl.eval_pc_bottom_pos()
  return stage.state.player_char:get_bottom_center()
end

function itest_dsl.eval_pc_velocity()
  return stage.state.player_char.velocity
end

function itest_dsl.eval_pc_ground_spd()
  return stage.state.player_char.ground_speed
end

function itest_dsl.eval_pc_motion_state()
  return stage.state.player_char.motion_state
end

-- table of functions used to evaluate and returns the gameplay value in current game state
evaluators = generate_function_table(itest_dsl, gp_value_types, "eval_")
itest_dsl.evaluators = evaluators

-- command struct

-- attributes
-- type  command_types  type of command invoked
-- args  {*}            sequence of arguments
local command = new_struct()
itest_dsl.command = command

function command:_init(cmd_type, args)
  self.type = cmd_type
  self.args = args
end


-- expectation struct

-- attributes
-- gp_value_type  gp_value_types       type of gameplay value to compare
-- expected_value {type used for gp_value_type}  expected gameplay value
local expectation = new_struct()
itest_dsl.expectation = expectation

function expectation:_init(gp_value_type, expected_value)
  self.gp_value_type = gp_value_type
  self.expected_value = expected_value
end


-- dsl itest struct

-- attributes
-- gamestate_type  string         gamestate type to start test in (also the only active gamestate)
-- stage_name      string|nil     stage name to play if gamestate type is 'stage', nil else
-- tilemap        tilemap|nil     tilemap data if gamestate type is 'stage', nil else
-- commands        {command}      sequence of commands to apply
local dsl_itest = new_struct()
itest_dsl.dsl_itest = dsl_itest

function dsl_itest:_init()
  -- all attributes are initially nil (even commands, as we construct the table during parsing)
end


-- itest dsl parser singleton, with parser context state
-- _itest               integration_test  current integration test in construction
-- _last_time_trigger   time_trigger      last time trigger registered with wait command
-- _final_expectations  {expectation}     sequence of expectations to verify
local itest_dsl_parser = singleton(function (self)
  self._itest = nil
  self._last_time_trigger = nil
  self._final_expectations = {}
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
-- @stage #                     < gamestate 'stage' with tag '#' for custom
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
  local lines = strspl(dsli_source, '\n')

  -- parse in 2 steps: gamestate and action sequence
  local next_line_index
  dsli.gamestate_type, dsli.stage_name, dsli.tilemap, next_line_index = itest_dsl_parser.parse_gamestate_definition(lines)
  dsli.commands = itest_dsl_parser.parse_action_sequence(lines, next_line_index)

  return dsli
end

-- return gamestate type, stage_name, tilemap data and index of next line to parse so we can chain parsing
-- the format of the gamestate definition is:
-- @[gamestate] (stage_name|#)?   < 2nd part only if gamestate == 'stage', '#' for custom tilemap
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
  local gamestate_type = sub(header_parts[1], 2)
  local stage_name = nil
  if gamestate_type == 'stage' then
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
      local tile_id = tile_symbol_to_ids[tile_symbol]
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
  itest_dsl_parser._itest = integration_test(name, {dsli.gamestate_type})

  itest_dsl_parser._itest.setup = function ()
    flow:change_gamestate_by_type(dsli.gamestate_type)
    if dsli.gamestate_type == "stage" then
      -- puppet control
      stage.state.player_char.control_mode = control_modes.puppet
      if dsli.stage_name == '#' then
        -- load tilemap data and build it from ascii
        setup_map_data()
        dsli.tilemap:load()
      else
        -- load stage by name when api is ready
      end
    end
  end

  itest_dsl_parser._itest.teardown = function ()
    flow:change_gamestate_by_type(dsli.gamestate_type)
    if dsli.gamestate_type == "stage" then
      if dsli.stage_name == '#' then
        -- clear tilemap and unload tilemap data
        clear_map()
        teardown_map_data()
      end
    end
  end

  for cmd in all(dsli.commands) do
    if cmd.type == command_types.wait then
      itest_dsl_parser:_wait(cmd.args[1])

    elseif cmd.type == command_types.expect then
      -- we currently don't support live assertions, but we support multiple
      -- final expectations
      add(itest_dsl_parser._final_expectations, expectation(cmd.args[1], cmd.args[2]))

    else
      -- common action, store callback for execution during
      itest_dsl_parser:_act(function ()
        executors[cmd.type](cmd.args)
      end)
    end
  end

  -- if we finished with a wait (with or without final assertion),
  --  we need to close the itest with a wait-action
  if itest_dsl_parser._last_time_trigger then
    itest_dsl_parser._itest:add_action(itest_dsl_parser._last_time_trigger, nil)
    itest_dsl_parser._last_time_trigger = nil  -- consume and cleanup for next itest
  end

  -- glue code to remain retro-compatible with function-based final assertion
  itest_dsl_parser:_define_final_assertion()

  local test = itest_dsl_parser._itest
  itest_dsl_parser._itest = nil  -- consume and cleanup for next itest

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
function itest_dsl_parser:_act(callback)
  if self._last_time_trigger then
    self._itest:add_action(self._last_time_trigger, callback)
    self._last_time_trigger = nil  -- consume so we know no final wait-action is needed
  else
    -- no wait since last action (or this is the first action), so use immediate trigger
    self._itest:add_action(integrationtest.immediate_trigger, callback)
  end
end

function itest_dsl_parser:_wait(interval)
  if self._last_time_trigger then
    -- we were already waiting, so finish last wait with empty action
    self._itest:add_action(self._last_time_trigger, nil)
  end
  -- we only support frame unit in the dsl
  self._last_time_trigger = integrationtest.time_trigger(interval, true)
end


-- define final assertion based on sequence of final expectations
-- this is a glue method to make it retro-compatible with the function-based final assertion
-- eventually, the itest will only hold expectations (possibly predefined functions for currying)
--  to avoid creating lambda
function itest_dsl_parser:_define_final_assertion()
  -- define an intermediate local variable to avoid the "local variable closure issue"
  --  i.e. if we access "self._final_expectations" directly from inside the function
  --  constructed below, it would get the actual value of self._final_expectations
  --  at evaluation time (too late, the temporary table reference would have been lost
  --  and the table gc-ed). So we either need to copy the table content (then clear table)
  --  or store the reference in an intermediate variable like this one (then create new table)
  local final_expectations_proxy = self._final_expectations
  self._final_expectations = {}  -- consume and cleanup for next itest

  self._itest.final_assertion = function ()
    local success = true
    local full_message = ""

    -- check each expectation one by one
    for exp in all(final_expectations_proxy) do
      local evaluator = evaluators[exp.gp_value_type]
      assert(evaluator, "evaluators["..exp.gp_value_type.."] (for '"..gp_value_type_strings[exp.gp_value_type].."') is not defined")
      local gp_value = evaluator()
      if gp_value ~= exp.expected_value then
        success = false
        local gp_value_data = gp_value_data_t[exp.gp_value_type]
        assert(gp_value_data, "gp_value_data_t["..exp.gp_value_type.."] is not defined")
        local gp_value_name = gp_value_data.name
        local message = "\nPassed gameplay value '"..gp_value_name.."':\n"..
          gp_value.."\n"..
          "Expected:\n"..
          exp.expected_value
        full_message = full_message..message.."\n"
      end
    end

    return success, full_message
  end
end


return itest_dsl
