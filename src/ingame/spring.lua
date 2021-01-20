local stage_data = require("data/stage_data")
local world = require("platformer/world")
-- visual requires ingame add-on to have access to spring sprite data
local visual = require("resources/visual_common")

local spring = new_class()

-- direction       directions     direction of the spring (where character should bounce)
-- location        tile_location  global location of the spring on the map
-- extended_timer  float          > 0 if the spring is currently extended
--                                time until the extension ends (seconds)
function spring:init(direction, global_loc)
  self.direction = direction
  self.global_loc = global_loc
  self.extended_timer = 0
end

--#if tostring
function spring:_tostring()
 return "spring("..joinstr(', ', self.direction, self.global_loc)..")"
end
--#endif

function spring:extend()
  -- if spring was already extended, simply reset the timer
  -- collision mask doesn't change anyway
  self.extended_timer = stage_data.spring_extend_duration
end

function spring:update()
  -- update timer
  -- no need to do anything else, other methods will check if timer > 0
  --  to know if spring is extended or not
  if self.extended_timer > 0 then
    self.extended_timer = self.extended_timer - delta_time60
    if self.extended_timer <= 0 then
      self.extended_timer = 0
    end
  end
end

-- unfortunately the spring objects are never quite where the spring tiles
--  would put them with a unique pivot, if we want the springs to stick to walls
-- so this method allows use to get adjusted pivot for rendering and detection trigger
--  (I rotated the sprites in Aseprite to locate the wanted pivot for each oriented spring)
-- keep using the standard sprite pivot for actual sprite rotation in render() though
function spring:get_adjusted_pivot()
  if self.direction == directions.up then
    return self.global_loc:to_topleft_position() + visual.sprite_data_t.spring.pivot
  elseif self.direction == directions.left then
    return self.global_loc:to_topleft_position() + vector(2, 2)
  else  -- self.direction == directions.right then -- (we don't support spring down)
    return self.global_loc:to_topleft_position() + vector(5, 2)
  end
end

-- render the spring at its current global location
function spring:render()
  -- the "quadrant" (ground direction) of the spring is the opposite
  --  of its faced direction (self.direction), so oppose it then you
  --  can get the angle to need to rotate it by for rendering
  local angle = world.quadrant_to_right_angle(oppose_dir(self.direction))
  local adjusted_pivot = self:get_adjusted_pivot()

  if self.extended_timer > 0 then
    visual.sprite_data_t.spring_extended:render(adjusted_pivot, false, false, angle)
  else
    visual.sprite_data_t.spring:render(adjusted_pivot, false, false, angle)
  end
end

return spring
