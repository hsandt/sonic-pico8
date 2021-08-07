local stage_common_data = require("data/stage_common_data")
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
  self.extended_timer = stage_common_data.spring_extend_duration
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
  local topleft = self.global_loc:to_topleft_position()
  if self.direction == directions.up then
    return topleft + visual.sprite_data_t.spring.pivot
  elseif self.direction == directions.left then
    return topleft + vector(2, 2)
  else  -- self.direction == directions.right then -- (we don't support spring down)
    return topleft + vector(6, 2)
  end
end

function spring:get_render_bounding_corners()
  -- to simplify we won't aim for the minimal bounding box for each direction,
  --  in each state, but for a broad region bounding all possible sprites
  --  in all possible directions and states (normal or extended)
  -- the sprite is always contained within a square of 2x2 tiles, where the global
  --  location is the bottom-left tile, and so its topleft is just on the middle left
  --  of the square; so the bounding corners are 1 tile above that, and 2 tiles to the
  --  right, 1 tile below that
  local topleft = self.global_loc:to_topleft_position()
  return topleft - tile_size * vector(0, 1), topleft + tile_size * vector(2, 1)
end

-- render the spring at its current global location
function spring:render()
  local flip_y = false
  local angle = 0
  local adjusted_pivot = self:get_adjusted_pivot()
  if self.direction == directions.left then
    angle = 0.25
  elseif self.direction == directions.right then
    -- we used to rotate spring to the right, but then lighting was at the bottom and shade at the top
    --  so we should flip the sprite to preserve lighting orientation
    -- however, flip is applied *before* rotation so we need to flip on Y to actually flip on X
    flip_y = true
    angle = 0.25

    -- unfortunately using flip Y has the side effect of messing up visual pivot,
    --  so we must offset adjusted pivot (which is still correct for physics trigger check)
    --  depending on whether sprite is extended or not
    if self.extended_timer > 0 then
      adjusted_pivot.x = adjusted_pivot.x + 4
    else
      adjusted_pivot.x = adjusted_pivot.x - 4  -- 6-4 = 2 so we now got the same adjusted pivot as left
    end
  end

  if self.extended_timer > 0 then
    visual.sprite_data_t.spring_extended:render(adjusted_pivot, false, flip_y, angle)
  else
    visual.sprite_data_t.spring:render(adjusted_pivot, false, flip_y, angle)
  end
end

return spring
