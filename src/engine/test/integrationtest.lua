require("engine/core/class")

-- integration test runner singleton
integration_test_runner = singleton {
  current_test_instance = nil
}


-- time trigger struct
time_trigger = new_class()

-- parameters
-- time              number (float)      relative time to run callback since last trigger
function time_trigger:_init(time)
 self.time = time
end

function time_trigger:_tostring()
 return "time_trigger("..self.time..")"
end


-- scripted action struct
scripted_action = new_class()

-- parameters
-- trigger           trigger             trigger that will run the callback
-- callback          function            callback called on trigger
-- name              string | nil        optional name for debugging
function scripted_action:_init(trigger, callback, name)
 self.trigger = trigger
 self.callback = callback
 self.name = name or "unnamed"
end

function scripted_action:_tostring()
 return "[scripted_action ".."'"..self.name.."' ".."@ "..self.trigger.."]"
end


-- integration test class
integration_test = new_class()

-- parameters
-- name               string                         test name
-- setup              function                       setup callback - called on test start
-- action_sequence    [scripted_action]              sequence of scripted actions - run during test
-- final_assertion    function () => (bool, string)  assertion function with message called on test end
function integration_test:_init(name)
 self.name = name
 self.setup = nil
 self.action_sequence = {}
 self.final_assertion = nil
end

function integration_test:_tostring()
 return "[integration_test '"..self.name.."']"
end
