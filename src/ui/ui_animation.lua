local ui_animation = {}

-- tween methods

function ui_animation.lerp(a, b, alpha)
  return a + (b-a) * alpha
end

function ui_animation.lerp_clamped(a, b, alpha)
  return a + (b-a) * mid(alpha, 0, 1)
end

function ui_animation.ease_in(a, b, alpha)
  -- take lerp, and replace alpha => alpha * alpha:
  --  (1 - alpha * alpha) * a + alpha * alpha * b
  -- or shorter, start from a, and add the difference with factor alpha * alpha:
  return a + (b-a) * alpha * alpha
end

function ui_animation.ease_out(a, b, alpha)
  -- take ease in and reverse parameters but also alpha:
  --  ui_animation.ease_in(b, a, 1 - alpha)
  -- or expand this and rewrite for compact expression independent of ease_in:
  --  b + (a-b) * (1 - alpha) * (1 - alpha) or
  return a + (b-a) * (2 - alpha) * alpha
end

function ui_animation.ease_in_out(a, b, alpha)
  -- piecewise ease in, then ease out
  if alpha <= 0.5 then
    -- make sure to 2* alpha back so 0.5 => 1
    return ui_animation.ease_in(a, (a + b) / 2, 2 * alpha)
  else
    -- make sure to lerp alpha back so 0.5 => 0 and 1 => 1
    -- 2 * (alpha - 0.5) = 2 * alpha - 1
    return ui_animation.ease_out((a + b) / 2, b, 2 * alpha - 1)
  end
end

-- helper: move drawable {position: vector, draw: function (recommended)} linearly along coord ("x" or "y")
--  from a to b over n frames
-- coord_offsets allow to offset drawables relatively to a and b while keeping drawable motions in sync
--  (coord_offsets list is indexed by index of drawable in drawables)
function ui_animation.move_drawables_on_coord_async(coord, drawables, coord_offsets, a, b, n)
  assert(#drawables > 0, "expected at least 1 drawable, but drawables is empty")
  for frame = 1, n do
    -- note that alpha starts at 1 / n, not 0
    -- this is because we expect our drawable to be drawn at the start position first,
    --  so when we run the motion interpolation, we can immediately move to the next position
    -- if moving a drawable into the screen, better set start position completely outside screen
    --  so you can see the drawable enter gradually
    local alpha = frame / n
    for i, dr in ipairs(drawables) do
      dr.position:set(coord, ui_animation.lerp(a, b, alpha) + coord_offsets[i])
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
      dr.position:copy_assign(ui_animation.lerp(from, to, alpha))
    end
    yield()
  end
end

return ui_animation
