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


-- type of commands available
itest_dsl_command_types = {
  warp   =  1,  -- warp player character bottom  args: {bottom position: vector}
  move   =  2,  -- set sticky pc move intention   args: {move_dir: horizontal_dirs}
  wait   = 11,  --
  expect = 21,
}

-- type of gameplay values available for expectations
itest_dsl_gp_value_types = {
  pc_bottom_pos =  1,
  pc_velocity   = 11,
  pc_ground_spd = 12,
}

-- string mapping for itest messages (to debug failing itests)
local value_type_strings = {
  [1] = "player character bottom position",
  [11] = "player character velocity",
  [12] = "player character ground speed",
}


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
-- gp_value_type  itest_dsl_gp_value_types       type of gameplay value to compare
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
  -- all attributes are initially nil or empty
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
-- warp 4 8                    < initial setup (it's an action like any other)
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
      local cmd_type = itest_dsl_command_types[cmd_type_str]
      local parse_fn_name = '_parse_args_'..cmd_type_str
      assert(itest_dsl_parser[parse_fn_name], "parse function '"..parse_fn_name.."' is not defined")
      local args = {itest_dsl_parser[parse_fn_name](arg_strings)}
      add(commands, command(cmd_type, args))
    end
  end
  return commands
end

-- convert string args to vector
function itest_dsl_parser._parse_args_warp(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))  -- bottom position
end

-- convert string args to vector
function itest_dsl_parser._parse_args_move(args)
  assert(#args == 1, "got "..#args.." args")
  return horizontal_dirs[args[1]]                -- move intention
end

-- convert string args to vector
function itest_dsl_parser._parse_args_wait(args)
  assert(#args == 1, "got "..#args.." args")
  return tonum(args[1])                          -- frames to wait
end

-- convert string args to vector
function itest_dsl_parser._parse_args_expect(args)
  assert(#args > 1, "got "..#args.." args")
  -- same principle as itest_dsl_parser.parse, the type of the first arg
  --  determines how we parse the rest of the args, named "value components"
  local value_type_str = args[1]
  -- gather all the value components as strings (e.g. {"3", "4"} for vector(3, 4))
  local expected_value_comps = {}
  for i = 2, #args do
    add(expected_value_comps, args[i])
  end
  -- determine the type of value reference tested for comparison (e.g. pc position)
  local value_type = itest_dsl_gp_value_types[value_type_str]
  -- parse the value components to semantical type (e.g. vector)
  local parse_fn_name = '_parse_value_'..value_type_str
  assert(itest_dsl_parser[parse_fn_name], "parse function '"..parse_fn_name.."' is not defined")
  local expected_value = itest_dsl_parser[parse_fn_name](expected_value_comps)
  return value_type, expected_value
end

-- convert string args to vector
function itest_dsl_parser._parse_value_pc_bottom_pos(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))
end

-- convert string args to vector
function itest_dsl_parser._parse_value_pc_velocity(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))
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
    if cmd.type == itest_dsl_command_types.warp then
      itest_dsl_parser:_act(function ()
        stage.state.player_char:warp_bottom_to(vector(cmd.args[1].x, cmd.args[1].y))
      end)
    elseif cmd.type == itest_dsl_command_types.move then
      itest_dsl_parser:_act(function ()
        stage.state.player_char.move_intention = horizontal_dir_vectors[cmd.args[1]]
      end)
    elseif cmd.type == itest_dsl_command_types.wait then
      itest_dsl_parser:_wait(cmd.args[1])
    elseif cmd.type == itest_dsl_command_types.expect then
      -- we currently don't support live assertions, only final assertion
      itest_dsl_parser:_add_final_expectation(unpack(cmd.args))
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

-- add final expectation to sequence, for future evaluation
function itest_dsl_parser:_add_final_expectation(gp_value_type, expected_gp_value)
  add(self._final_expectations, expectation(gp_value_type, expected_gp_value))
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
      local gp_value = self._evaluate(exp.gp_value_type)
      if gp_value ~= exp.expected_value then
        success = false
        local gp_value_name = value_type_strings[exp.gp_value_type]
        assert(gp_value_name, "value_type_strings["..exp.gp_value_type.."] is not defined")
        local message = "Passed gameplay value '"..gp_value_name.."':\n"..
          gp_value.."\n"..
          "Expected:\n"..
          exp.expected_value
        full_message = full_message..message.."\n"
      end
    end

    return success, full_message
  end
end

-- evaluate gameplay value. it is important to call this at expect
--  time, not when defining the test, to get the actual runtime value
function itest_dsl_parser._evaluate(gp_value_type)
  if gp_value_type == itest_dsl_gp_value_types.pc_bottom_pos then
    return stage.state.player_char:get_bottom_center()
  elseif gp_value_type == itest_dsl_gp_value_types.pc_velocity then
    return stage.state.player_char.velocity
  else
    assert(false, "unknown gameplay value: "..gp_value_type)
  end
end

return itest_dsl
