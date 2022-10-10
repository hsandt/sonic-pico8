local visual = require("resources/visual_common")

local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")

local titlemenu_visual = {
  -- water shimmer animation period
  water_shimmer_period = 1.3,

  -- color swap for water shimmers, index by time step, by original color index
  --  (1 for red, 2 for yellow)
  water_shimmer_color_cycle = {
    {colors.dark_blue, colors.light_gray},
    {colors.indigo, colors.light_gray},
    {colors.light_gray, colors.light_gray},
    {colors.light_gray, colors.indigo},
    {colors.light_gray, colors.dark_blue},
    {colors.light_gray, colors.dark_blue},
    {colors.light_gray, colors.indigo},
    {colors.indigo, colors.indigo},
  },

  -- radius of emeralds rotating in circle (when full circle, not ellipse)
  --  during start cinematic
  start_cinematic_emerald_circle_radius = 30,

  -- time taken by an emerald to make a full rotation around the clock (s)
  start_cinematic_emerald_rotation_period = 1.6,

  -- delay before first emerald entering screen in frames
  --  (it's the last emerald, but the first to enter)
  start_cinematic_first_emerald_enter_delay_frames = 30,
}

-- visuals for titlemenu only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local titlemenu_sprite_data_t = {
  angel_island_bg = sprite_data(sprite_id_location(0, 11), tile_vector(16, 5), nil, colors.pink),

  -- true emerald is located where emerald silhouette is in visual_ingame_addon
  emerald = sprite_data(sprite_id_location(10, 0), nil, vector(3, 2), colors.pink),

  -- CORE TITLE GFX ONLY

  menu_cursor = sprite_data(sprite_id_location(1, 0), tile_vector(2, 1), vector(8, 5), colors.pink),
  menu_cursor_shoe = sprite_data(sprite_id_location(3, 0), tile_vector(2, 1), vector(8, 5), colors.pink),

  spark_fx1 = sprite_data(sprite_id_location(14, 4), nil, vector(1, 1), colors.pink),
  spark_fx2 = sprite_data(sprite_id_location(15, 4), nil, vector(3, 3), colors.pink),
  spark_fx3 = sprite_data(sprite_id_location(14, 5), tile_vector(2, 2), vector(5, 5), colors.pink),

  -- START CINEMATIC GFX ONLY

  -- like angel island flipped on y, after removing the island, so just clouds on the water horizon
  reversed_horizon = sprite_data(sprite_id_location(0, 4), tile_vector(16, 5), nil, colors.pink),

  -- clouds
  cloud_big = sprite_data(sprite_id_location(0, 1), tile_vector(7, 3), vector(0, 11), colors.pink),
  cloud_medium = sprite_data(sprite_id_location(7, 1), tile_vector(4, 2), vector(0, 6), colors.pink),
  cloud_small = sprite_data(sprite_id_location(11, 1), tile_vector(3, 2), vector(0, 4), colors.pink),
  cloud_tiny = sprite_data(sprite_id_location(14, 1), tile_vector(2, 1), vector(0, 4), colors.pink),

  tails_plane1 = sprite_data(sprite_id_location(0, 10), tile_vector(2, 1), vector(6, 2), colors.pink),
  tails_plane2 = sprite_data(sprite_id_location(2, 10), tile_vector(2, 1), vector(6, 2), colors.pink),
  tails_plane3 = sprite_data(sprite_id_location(4, 10), tile_vector(2, 1), vector(6, 2), colors.pink),
  tails_plane4 = sprite_data(sprite_id_location(6, 10), tile_vector(2, 1), vector(6, 2), colors.pink),
  sonic_tiny = sprite_data(sprite_id_location(0, 9), nil, vector(2, 5), colors.pink),
  sonic_spin_tiny = sprite_data(sprite_id_location(1, 9), nil, vector(3, 3), colors.pink),

  star_fx1 = sprite_data(sprite_id_location(2, 9), nil, vector(3, 3), colors.pink),
  star_fx2 = sprite_data(sprite_id_location(3, 9), nil, vector(3, 3), colors.pink),
  star_fx3 = sprite_data(sprite_id_location(4, 9), nil, vector(3, 3), colors.pink),

  -- SPLASH SCREEN GFX ONLY

  splash_screen_logo = sprite_data(sprite_id_location(0, 0), tile_vector(12, 4), vector(0, 32), colors.pink),

  -- cinematic sonic sprite data table: extracted just the run sprites from playercharacter_sprite_data.lua
  --  (note that they are offset by 2 cells up, simply because we only copy the half top of the spritesheet,
  --  so we need to move them to the half top, see splash_screen_state:on_enter)
  cinematic_sonic_sprite_data_table = transform(
    -- anim_name below is not protected since accessed via minified member to define animations more below
    --anim_name        = sprite_data(
    --                    id_loc, span = (2, 2), pivot = (8, 8), transparent_color = colors.pink)
    {
      run1             = {0,  6},
      run2             = {2,  6},
      run3             = {4,  6},
      run4             = {6,  6},
    }, function (raw_data)
      return sprite_data(
        sprite_id_location(raw_data[1], raw_data[2]),  -- id_loc
        tile_vector(2, 2),                             -- span
        vector(8, 8),                                  -- pivot
        colors.pink                                    -- transparent_color
      )
  end)
}

-- shortcut to define animations more easily
local cssdt = titlemenu_sprite_data_t.cinematic_sonic_sprite_data_table

local titlemenu_animated_sprite_data_t = {
  -- used to prepare appearance of title logo as in Sonic 2
  spark_fx = animated_sprite_data(
    {
      -- no anim_loop_modes.ping_pong_clear/single_ping_pong implemented, so just ping-pong manually
      titlemenu_sprite_data_t.spark_fx1,
      titlemenu_sprite_data_t.spark_fx2,
      titlemenu_sprite_data_t.spark_fx3,
      titlemenu_sprite_data_t.spark_fx2,
      titlemenu_sprite_data_t.spark_fx1,
    },
    4,
    anim_loop_modes.clear
  ),

  tails_plane = {
    -- manual construction via sprite direct access appears longer than animated_sprite_data.create in code,
    --  but this will actually be minified and therefore very compact (as names are not protected)
    ["loop"] = animated_sprite_data(
      {
        titlemenu_sprite_data_t.tails_plane1,
        titlemenu_sprite_data_t.tails_plane2,
        titlemenu_sprite_data_t.tails_plane3,
        titlemenu_sprite_data_t.tails_plane4
      },
      6,  -- TUNE
      anim_loop_modes.loop
    )
  },

  -- used for emerald
  star_fx = animated_sprite_data(
    {
      titlemenu_sprite_data_t.star_fx1,
      titlemenu_sprite_data_t.star_fx2,
      titlemenu_sprite_data_t.star_fx3,
    },
    5,
    anim_loop_modes.clear
  ),

  cinematic_sonic = {
    ["run"] = animated_sprite_data(
        {cssdt.run1, cssdt.run2, cssdt.run3, cssdt.run4},
        5,  -- step_frames (note that ingame playercharacter adds modifier self.anim_run_speed = abs(self.ground_speed))
        4   -- anim_loop_modes.loop
    )
  }
}

merge(visual, titlemenu_visual)
merge(visual.sprite_data_t, titlemenu_sprite_data_t)
merge(visual.animated_sprite_data_t, titlemenu_animated_sprite_data_t)
