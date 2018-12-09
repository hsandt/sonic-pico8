require("engine/core/helper")
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test = integrationtest.itest_manager, integrationtest.integration_test

-- we exceptionally require if for pico8 as well, as we need tile_symbol_to_ids
local tile_test_data = require("game/test_data/tile_test_data")
local tilemap = require("engine/data/tilemap")

-- dsl interpretation requirements
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
local pc_data = require("game/data/playercharacter_data")

-- itest dsl parser singleton, with parser context state
-- _itest               integration_test  current integration test in construction
-- _last_time_trigger   time_trigger      last time trigger registered with wait command
local itest_dsl = singleton(function (self)
  self._itest = nil
  self._last_time_trigger = nil
end)


-- type of commands available
itest_dsl_command_types = {
  spawn  = 1,   -- spawn player character bottom  args: {bottom position: vector}
  move   = 2,   -- set sticky pc move intention   args: {move_dir: horizontal_dirs}
  wait   = 11,  --
  expect = 21
}

-- type of gameplay values available for expectations
itest_dsl_gp_value_types = {
  pc_bottom_pos = 1
}

-- string mapping for itest messages
local value_type_strings = {
  "player character bottom position"
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


-- dsl itest struct

-- attributes
-- gamestate_type  string             gamestate type to start test in (also the only active gamestate)
-- stage_name      string|nil         stage name to play if gamestate type is 'stage', nil else
-- map_data        tile_map_data|nil  tilemap data if gamestate type is 'stage', nil else
-- commands        {commands}         sequence of commands to apply
local dsl_itest = new_struct()
itest_dsl.dsl_itest = dsl_itest

function dsl_itest:_init()
  -- all attributes are initially nil or empty
end


-- parse, create and register itest from dsl
function itest_dsl.register(name, dsli_source)
  local dsli = itest_dsl.parse(dsli_source)
  local test = itest_dsl.create_itest(name, dsli)
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
-- spawn 4 8                    < initial setup (it's an action like any other)
-- move right                   < more actions...
-- wait 30                      < wait delays the next action (here, the nil action)
-- expect pc_bottom_pos 14. 8.  < expectation (only final assertion is supported)
-- ]]
function itest_dsl.parse(dsli_source)
  -- create dsl itest
  local dsli = dsl_itest()

  -- split source lines (do not collapse \n so we can use blank lines as separator)
  local lines = strspl(dsli_source, '\n')

  -- parse in 2 steps: gamestate and action sequence
  local next_line_index
  dsli.gamestate_type, dsli.stage_name, dsli.map_data, next_line_index = itest_dsl.parse_gamestate_definition(lines)
  dsli.commands = itest_dsl.parse_action_sequence(lines, next_line_index)

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
function itest_dsl.parse_gamestate_definition(lines)
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

  local map_data = nil
  local next_line_index = 3
  if stage_name == '#' then
    -- we are defining a custom tilemap, let's parse it
    map_data, next_line_index = itest_dsl.parse_tilemap(lines)
  end

  return gamestate_type, stage_name, map_data, next_line_index
end

function itest_dsl.parse_tilemap(lines)
  -- tilemap should always start at line 2
  -- first line will give the tilemap width
  assert(#lines >= 2, "only "..#lines.." line(s), need at least 2")
  local width = #lines[2]
  assert(width > 0)

  local content = {}

  for i = 2, #lines do
    local line_str = lines[i]
    if #line_str == 0 then
      -- we reached the end of tilemap definition
      break
    end

    -- ensure that width is consistent
    assert(#line_str == width, "inconsistent line length: "..#line_str.." vs "..width)

    local current_row = {}

    for j = 1, width do
      local tile_symbol = sub(line_str, j, j)
      local tile_id = tile_symbol_to_ids[tile_symbol]
      assert(tile_id, "unknown tile symbol: "..tile_symbol)
      add(current_row, tile_id)
    end

    add(content, current_row)
  end

  -- return tilemap, next line = initial line index + nb rows + 1
  return tilemap(content), 2 + #content + 1
end


function itest_dsl.parse_action_sequence(lines, next_line_index)
  local commands = {}
  for i = next_line_index, #lines do
    words = strspl(lines[i], ' ', true)
    -- if there are no words, the line is empty, so continue
    if #words > 0 then
      local cmd_type_str = words[1]
      local args_str = {}
      for j = 2, #words do
        add(args_str, words[j])
      end
      local cmd_type = itest_dsl_command_types[cmd_type_str]
      local parse_fn_name = '_parse_args_'..cmd_type_str
      assert(itest_dsl[parse_fn_name], "parse function '"..parse_fn_name.."' is not defined")
      local args = {itest_dsl[parse_fn_name](args_str)}
      add(commands, command(cmd_type, args))
    end
  end
  return commands
end

-- convert string args to vector
function itest_dsl._parse_args_spawn(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))  -- bottom position
end

-- convert string args to vector
function itest_dsl._parse_args_move(args)
  assert(#args == 1, "got "..#args.." args")
  return horizontal_dirs[args[1]]                -- move intention
end

-- convert string args to vector
function itest_dsl._parse_args_wait(args)
  assert(#args == 1, "got "..#args.." args")
  return tonum(args[1])                          -- frames to wait
end

-- convert string args to vector
function itest_dsl._parse_args_expect(args)
  assert(#args > 1, "got "..#args.." args")
  -- same principle as itest_dsl.parse, the type of the first arg
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
  assert(itest_dsl[parse_fn_name], "parse function '"..parse_fn_name.."' is not defined")
  local expected_value = itest_dsl[parse_fn_name](expected_value_comps)
  return value_type, expected_value
end

-- convert string args to vector
function itest_dsl._parse_value_pc_bottom_pos(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))
end

-- create and return an itest from a dsli, providing a name
function itest_dsl.create_itest(name, dsli)
  itest_dsl._itest = integration_test(name, {dsli.gamestate_type})
  itest_dsl._itest.setup = function ()
    flow:change_gamestate_by_type(dsli.gamestate_type)
    if dsli.gamestate_type == "stage" then
      assert(dsli.stage_name)
      -- load stage by name when api is ready
    end
  end

  for cmd in all(dsli.commands) do
    if cmd.type == itest_dsl_command_types.spawn then
      itest_dsl:_act(function ()
        stage.state.player_char:spawn_bottom_at(vector(cmd.args[1].x, cmd.args[1].y))
      end)
    elseif cmd.type == itest_dsl_command_types.move then
      itest_dsl:_act(function ()
        stage.state.player_char.move_intention = horizontal_dir_vectors[cmd.args[1]]
      end)
    elseif cmd.type == itest_dsl_command_types.wait then
      itest_dsl:_wait(cmd.args[1])
    elseif cmd.type == itest_dsl_command_types.expect then
      -- we currently don't support live assertions, only final assertion
      itest_dsl:_final_assert(unpack(cmd.args))

    end
  end

  -- if we finished with a wait (with or without final assertion),
  --  we need to close the itest with a wait-action
  if itest_dsl._last_time_trigger then
    itest_dsl._itest:add_action(itest_dsl._last_time_trigger, nil)
  end

  local test = itest_dsl._itest

  -- cleanup
  itest_dsl._itest = nil
  itest_dsl._last_time_trigger = nil

  return test
end

function itest_dsl:_act(callback)
  if self._last_time_trigger then
    self._itest:add_action(self._last_time_trigger, callback)
    self._last_time_trigger = nil  -- consume so we know no final wait-action is needed
  else
    -- no wait since last action (or this is the first action), so use immediate trigger
    self._itest:add_action(integrationtest.immediate_trigger, callback)
  end
end

function itest_dsl:_wait(interval)
  if self._last_time_trigger then
    -- we were already waiting, so finish last wait with empty action
    self._itest:add_action(self._last_time_trigger, nil)
  end
  -- we only support frame unit in the dsl
  self._last_time_trigger = integrationtest.time_trigger(interval, true)
end

function itest_dsl:_final_assert(gp_value_type, expected_gp_value)
  local gp_value_name = value_type_strings[gp_value_type]
  assert(gp_value_name, "invalid gp_value_type: "..gp_value_type)
  self._itest.final_assertion = function ()
    local gp_value = self._evaluate(gp_value_type)
    return gp_value == expected_gp_value,
      "Passed gameplay value '"..gp_value_name.."':\n"..
      gp_value.."\n"..
      "Expected:\n"..
      expected_gp_value
  end
end

-- evaluate gameplay value. it is important to call this at expect
--  time, not when defining the test, to get the actual runtime value
function itest_dsl._evaluate(gp_value_type)
  if gp_value_type == itest_dsl_gp_value_types.pc_bottom_pos then
    return stage.state.player_char:get_bottom_center()
  else
    assert(false, "unknown gameplay value: "..gp_value_type)
  end
end

return itest_dsl
