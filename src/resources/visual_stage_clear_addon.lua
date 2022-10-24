local visual = require("resources/visual_common")

local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")
local sspr_data = require("engine/render/sspr_data")

local stage_clear_visual = {
  fadeout_zigzag_width = 11,  -- doesn't include pixel 0, so actually count +1 pixel in total
  picked_emeralds_radius = 15,
  juggled_emeralds_radius = 22
}

-- visuals for stage_clear only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local stage_clear_sprite_data_t = {
  -- stage clear spritesheet is pretty busy as it must contain stage tiles, so we had to move menu cursor
  --  sprites to a different location than in titlemenu, that we define in this stage_clear-specific add-on
  menu_cursor = sprite_data(sprite_id_location(10, 0), tile_vector(2, 1), vector(8, 5), colors.pink),

  -- eggman parts
  -- note that body will move up/down via code
  -- note that we exceptionally have a character with a central axis going through
  --  an actual pixel (the red nose is made of 1px, so an odd number), which means an integer
  --  pivot will be placed between 4 pixels and result in a flip X offset of one, effectively
  --  moving Eggman's body on every flip. To avoid this, we place the pivot X to match the actual
  --  center of the nose, using a fraction .5. Also do this for legs to sync them, and even for arm,
  --  so we can consistently place them at -13 along X from body, and flip X to +13 and automatically
  --  benefit from the mirror adjustment (instead of -14 and 13)
  eggman_body = sspr_data(31, 48, 38, 34, vector(13.5, 33), colors.pink),
  eggman_arm_up = sspr_data(17, 48, 13, 16, vector(12.5, 15), colors.pink),
  eggman_arm_down = sspr_data(16, 65, 14, 10, vector(13.5, 8), colors.pink),
  eggman_legs_down = sspr_data(70, 60, 35, 9, vector(17.5, 8), colors.pink),
  eggman_legs_up = sspr_data(70, 70, 35, 10, vector(17.5, 9), colors.pink),
}

local stage_clear_animated_sprite_data_t = {
  eggman_arm = {
    ["once"] = animated_sprite_data(
      {
        stage_clear_sprite_data_t.eggman_arm_up,
        stage_clear_sprite_data_t.eggman_arm_down,
      },
      110,
      anim_loop_modes.freeze_last
    )
  },
  eggman_legs = {
    ["once"] = animated_sprite_data(
      {
        stage_clear_sprite_data_t.eggman_legs_up,
        stage_clear_sprite_data_t.eggman_legs_down,
      },
      110,
      anim_loop_modes.freeze_last
    )
  },
}

merge(visual, stage_clear_visual)
merge(visual.sprite_data_t, stage_clear_sprite_data_t)
merge(visual.animated_sprite_data_t, stage_clear_animated_sprite_data_t)
