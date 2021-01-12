local animated_sprite = require("engine/render/animated_sprite")

local visual = require("resources/visual_common")
-- we should require ingameadd-on in main

-- goal plate object, spawned when a goal plate base tile has been scanned
--  it adds goal plate rotating behavior and actually only draws the upper part,
--  since the base tile will be drawn on the stage as part of the tilemap
local goal_plate = new_class()

-- global_loc  location  global location in the stage
function goal_plate:init(global_loc)
  self.global_loc = global_loc
  self.anim_spr = animated_sprite(visual.animated_sprite_data_t.goal_plate)
  self.anim_spr:play("goal")
end

--#if tostring
function goal_plate:_tostring()
 return "goal_plate("..self.global_loc..")"
end
--#endif

function goal_plate:update()
  self.anim_spr:update()
end

-- render the emerald at its current location
function goal_plate:render()
  -- The representative tile, the goal plate base, is attached to the goal plate body (rotating panel)
  --  at (4, 0). All plate body sprites have their pivot located at the attachment point
  --  (technically one pixel below their own tile span, so at y = 16), so we can draw them directly
  --  at this point.
  self.anim_spr:render(self.global_loc:to_topleft_position() + vector(4, 0))
end

return goal_plate
