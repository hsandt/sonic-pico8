local ui_animation = {}

local coords = {'x', 'y'}

-- helper: move drawable {position: vector, draw: function (recommended)} linearly along coord ("x" or "y")
--  from a to b over n frames
-- coord_offsets allow to offset drawables relatively to a and b while keeping drawable motions in sync
--  (coord_offsets list is indexed by index of drawable in drawables)
function ui_animation.move_drawables_on_coord_async(coord, drawables, coord_offsets, a, b, n)
  for frame = 1, n do
    -- note that alpha starts at 1 / n, not 0
    -- this is because we expect our drawable to be drawn at the start position first,
    --  so when we run the motion interpolation, we can immediately move to the next position
    -- if moving a drawable into the screen, better set start position completely outside screen
    --  so you can see the drawable enter gradually
    local alpha = frame / n
    for i, dr in ipairs(drawables) do
      dr.position:set(coord, (1 - alpha) * a + alpha * b + coord_offsets[i])
    end
    yield()
  end
end

-- helper: move drawable {position: vector, draw: function (recommended)} linearly along the 2D space
--  from vector `from` to vector `to` over n frames
function ui_animation.move_drawables_async(drawables, from, to, n)
  for frame = 1, n do
    -- same remark as in move_drawables_on_coord_async
    local alpha = frame / n
    for i, dr in ipairs(drawables) do
      for coord in all(coords) do
        dr.position:set(coord, (1 - alpha) * from:get(coord) + alpha * to:get(coord))
      end
    end
    yield()
  end
end

return ui_animation
