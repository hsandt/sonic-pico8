local itest_dsl = {}

-- type of commands available
itest_dsl.command_types = {

}

-- type of values available for expectations
itest_dsl.values = {
  pc_pos = 1
}


-- command struct

-- attributes
-- cmd_type  command_types  type of command invoked
-- args      {*}            sequence of arguments
local command = new_struct()
itest_dsl.command = command

function command:_init(cmd_type, args)
  self.cmd_type = cmd_type
  self.args = args
end


-- dsl itest struct

-- attributes
-- gamestate   string      gamestate to start test in (also the only active gamestate)
-- stage       string|nil  stage to play in, else if gamestate is not 'stage'
-- commands    {commands}  sequence of commands to apply
local dsl_itest = new_struct()
itest_dsl.dsl_itest = dsl_itest

function dsl_itest:_init()
  -- all attributes are initially nil
end


-- parse a dsl itest source and return a dsl itest
function itest_dsl.parse(dsli_source)
  return nil
end


-- create and return an itest from a dsli, providing a name
function itest_dsl.create_itest(name, dsli)
  return nil
end


return itest_dsl
