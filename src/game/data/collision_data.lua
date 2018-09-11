sprite_flags = {
  collision = 0
}

return {

  -- table mapping tile sprite id to tile collision mask
  -- this will be completed as tiles are added, adding extra information
  --  such as "mirror_y: true" for upside-down tiles
  -- for readability we also indice the sprite id location in comment
  sprite_id_to_collision_mask_id_locations = {
    [64] = sprite_id_location(0, 5),  -- 64 @ (0, 4)
    [65] = sprite_id_location(1, 5),  -- 65 @ (1, 4)
    [66] = sprite_id_location(2, 5),  -- 66 @ (2, 4)
    [67] = sprite_id_location(3, 5),  -- 67 @ (3, 4)
    [68] = sprite_id_location(4, 5),  -- 68 @ (4, 4)
    [69] = sprite_id_location(5, 5),  -- 69 @ (5, 4)
    [70] = sprite_id_location(6, 5),  -- 70 @ (6, 4)
    [71] = sprite_id_location(7, 5),  -- 71 @ (7, 4)
    [72] = sprite_id_location(8, 5),  -- 72 @ (8, 4)
    [73] = sprite_id_location(9, 5),  -- 73 @ (9, 4)
    [74] = sprite_id_location(10, 5), -- 74 @ (10, 4)
  }

}
