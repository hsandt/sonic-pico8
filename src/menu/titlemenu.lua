local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local animated_sprite = require("engine/render/animated_sprite")
local sprite_object = require("engine/render/sprite_object")
local text_helper = require("engine/ui/text_helper")

local postprocess = require("engine/render/postprocess")
-- it's called ingame, but actually shared with menu
local emerald_fx = require("ingame/emerald_fx")
local emerald_cinematic = require("menu/emerald_cinematic")
local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")
local emerald_common = require("render/emerald_common")
local audio = require("resources/audio")
local visual = require("resources/visual_common")  -- we should require visual_titlemenu add-on in main
local ui_animation = require("ui/ui_animation")

local titlemenu = derived_class(gamestate)

titlemenu.type = ':titlemenu'

-- parameters data

-- sequence of menu items to display, with their target states
local menu_item_params = {
  {"start", function(app)
    local curr_stage_state = flow.curr_state
    assert(curr_stage_state.type == titlemenu.type)
    curr_stage_state:play_start_cinematic()
  end},
  {"credits", function(app)
    flow:query_gamestate_type(':credits')
  end},
}

-- CONSTANTS (outside visual files)

-- let's define parameters to guide us in the camera motion
--  (in outer scope so all methods can access them)

-- if we unroll a vertical line tracing what the screen center looks at on the horizon sphere,
--  we get a band of a certain length, which is the vertical period of the camera
--  (that is, after that many pixels of motion upward, we can see the island again at exactly the
--  same position)
local full_loop_height = 1296 -- + tuned("full loop dy x16", 0) * 16
-- angel island is at the bottom of the screen, so actually to have the water horizon exactly
--  at screen center, by looking at the sprite, we see we should move camera down by 52
local camera_y0 = 52
-- but that's to place the camera center, at y=64 on the horizon line, so actual objects
--  should use object y0 = 64 + 52 = 116 aka "perfect horizon y"
local perfect_horizon_y = 64 + camera_y0

-- we're going to rotate the camera pitch from 0, upward with full turn 360 degrees
-- we're gonna place milestones using the fact that angle is proportional to distance on the horizon
--  sphere, and make the assumption that islands and clouds are on that sphere
--  (in reality clouds must be farther, but that should help)

-- first batch of clouds are located around 1/6 of the circle (60 degrees)
local front_clouds_base_y = perfect_horizon_y - full_loop_height / 6

-- angel island is initially at y = 88, so remove full height to see it again when moving camera
--  up by full loop height
local island_full_loop_new_y = 88 - full_loop_height

local clouds_data = {
  -- {size (1: big, 2: medium, 3: small, 4: tiny), initial position}
  {1, vector(2, front_clouds_base_y + 9)},
  {1, vector(62, front_clouds_base_y + 22)},
  {1, vector(120, front_clouds_base_y + 32)},
  {2, vector(8, front_clouds_base_y + 41)},
  {2, vector(49, front_clouds_base_y + 50)},
  {2, vector(82, front_clouds_base_y + 56)},
  {2, vector(131, front_clouds_base_y + 62)},
  {3, vector(50, front_clouds_base_y + 70)},
  {3, vector(100, front_clouds_base_y + 76)},
  {4, vector(10, front_clouds_base_y + 72)},
  {4, vector(80, front_clouds_base_y + 84)},
}

local cloud_sprites_per_size_category = {
  visual.sprite_data_t.cloud_big,
  visual.sprite_data_t.cloud_medium,
  visual.sprite_data_t.cloud_small,
  visual.sprite_data_t.cloud_tiny,
}

-- parameters:
-- items                        {menu_item}    sequence of menu items that the menu should display

-- state:
-- title_logo_drawable          sprite_object   drawable for title logo sprite motion interpolation
-- drawables_sea                {sprite_object} island and reverse horizon, drawn following camera motion
--                                              and using color palette swap for water shimmers
-- cinematic_drawables_world    {sprite_object} all other drawables for the start cinematic seen via camera motion
-- cinematic_drawables_screen   {sprite_object} all other drawables for the start cinematic seen independently from camera
-- emeralds                     {emerald_cinematic} emerald cinematic sprites (drawable), stored for manual handling
-- cinematic_emeralds_on_circle {int}           number of all emeralds rotating on a circle/ellipse
-- ellipsis_y_scalable          {scale: number} scalable applied to emerald circle to get ellipsis (shrink on y)
-- emerald_landing_fxs          {fxs}           emerald landing fx (animated star)
-- clouds                       {sprite_object} sequence of clouds to draw, kept reference for motion
-- tails_plane                  animated_sprite tails plane animated sprite
-- tails_plane_position         vector          tails plane position
-- is_sonic_on_plane            bool            if true, draw Sonic standing on plane
-- jumping_sonic                sprite_object   reference to jumping sonic to update its position (but drawn via cinematic_drawables_screen)
-- jumping_sonic_vy             number          jumping sonic speed on y to simulate a simple gravity
-- menu                         menu            title menu showing items (only created when it must be shown)
-- frames_before_showing_menu   int             number of frames before showing menu. Ignored if 0.
-- start_pressed_time           number          time (t()) when start button was confirmed, used for cinematic
-- should_start_attract_mode    bool            should we enter attract mode now?
-- is_playing_start_cinematic   bool            are we playing the start cinematic?
-- is_fading_out_for_stage_intro  bool          are we fading out, preparing to load stage intro?
-- camera_y                     number          camera top y used to draw world elements
-- postproc                     postprocess     postprocess for fade out

-- there are more members during the start cinematic, but they will be created when it starts
function titlemenu:init()
  -- sequence of menu items to display, with their target states
  -- this could be static, but defining in init allows us to avoid
  --  outer scope definition, so we don't need to declare local menu_item
  --  at source top for unity build
  self.items = transform(menu_item_params, unpacking(menu_item))
  self.title_logo_drawable = sprite_object(visual.sprite_data_t.title_logo)
  -- prepare angel island and reverse horizon as drawables for sea (they use color palette swap)
  self.drawables_sea = {sprite_object(visual.sprite_data_t.angel_island_bg), sprite_object(visual.sprite_data_t.reversed_horizon)}
  self.cinematic_drawables_world = {}
  self.cinematic_drawables_screen = {}
  self.emeralds = {}
  self.cinematic_emeralds_on_circle = {}
  self.ellipsis_y_scalable = {scale = 1}  -- table is just to allow usage of tween_scalable_async
  self.emerald_landing_fxs = {}
  self.clouds = {}
  -- self.tails_plane = nil
  -- self.tails_plane_position = nil
  self.is_sonic_on_plane = false
  -- self.jumping_sonic = nil
  self.jumping_sonic_vy = 0

  -- self.menu = nil  -- commented out to spare characters

  -- defined in on_enter anyway, but we still define it to allow utests to handle that
  --  without simulating on_enter (and titlemenu cartridge has enough space)
  self.frames_before_showing_menu = 0
  -- self.start_pressed_time = nil
  self.should_start_attract_mode = false
  self.is_playing_start_cinematic = false
  self.is_fading_out_for_stage_intro = false
  self.camera_y = 0

  -- postprocessing for fade out effect
  self.postproc = postprocess()
end

function titlemenu:on_enter()
--#if tuner
  -- only during testing, reload original spritesheet to verify how logo leaves
  --  screen and that we reload clouds, etc. properly
  reload(0x0, 0x0, 0x2000)
--#endif

  self.app:start_coroutine(self.play_opening_music_async, self)

  -- show menu after short intro of 2 columns
  -- we assume play_opening_music_async was started at the same time
  -- title bgm is at SPD 12 so that makes
  --   12 SPD * 4 frames/SPD/column * 2 columns = 96 frames
  self.frames_before_showing_menu = 96
  self.should_start_attract_mode = false
  self.is_playing_start_cinematic = false
  self.is_fading_out_for_stage_intro = false

  -- logo should be initially placed 1 tile to the right, 3 tiles to the bottom,
  --  with its pivot at top-left
  self.title_logo_drawable.position = vector(8, 16)
  self.title_logo_drawable.visible = true
  -- place angel island at the bottom of the screen
  self.drawables_sea[1].position = vector(0, 88)
  -- hide reverse horizon for now
  self.drawables_sea[2].visible = false
end

function titlemenu:play_opening_music_async()
  -- start title BGM
  music(audio.music_ids.title)

  -- fade out current bgm during the last half-measure (we have a decreasing volume
  --   in the music itself but there is still a gap between volume 1 and 0 in PICO-8
  --   and using a custom instrument just to decrease volume is cumbersome, hence the
  --   additional fade-out by code)
  -- the fast piano track ends with SFX 16 after 4 patterns (repeating one of the SFX once)
  -- and 2 columns, over 1 columns, which makes the fade out start at:
  --   12 SPD * 4 frames/SPD/column * (4 patterns * 4 columns + 2 columns) = 864 frames
  -- and lasts:
  --   12 SPD * 4 frames/SPD/column * 1 column = 48 frames = 48 * 1000 / 60 = 800 ms
  yield_delay_frames(864)
  music(-1, 800)

  -- wait for music fade out to finish (48 frames), then wait a little more before
  --   starting attract mode (1s = 60 frames), similarly to Sonic 3
  yield_delay_frames(108)

  self.should_start_attract_mode = true
end

function titlemenu:show_menu()
  self.menu = menu(self.app--[[, 2]], alignments.left, 3, colors.white--[[skip prev_page_arrow_offset]], visual.sprite_data_t.menu_cursor_shoe, 7)
  self.menu:show_items(self.items)
end

-- this is called when entering credits
function titlemenu:on_exit()
  -- clear menu completely (will call GC, but fine)
  self.menu = nil

  clear_table(self.cinematic_drawables_world)
  clear_table(self.cinematic_drawables_screen)
  clear_table(self.emeralds)
  clear_table(self.cinematic_emeralds_on_circle)
  clear_table(self.emerald_landing_fxs)
  clear_table(self.clouds)
  self.tails_plane = nil
  self.tails_plane_position = nil
  self.is_sonic_on_plane = false
  self.jumping_sonic = nil
  self.jumping_sonic_vy = 0

  -- stop all coroutines, this is important to prevent play_opening_music_async from continuing in the background
  --  while reading credits, and fading out music earlier than expected after coming back to title
  self.app:stop_all_coroutines()
end

function titlemenu:update()
  if self.is_playing_start_cinematic then
    if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
      -- immediately start fade out in parallel with existing animations to keep things smooth
      -- they should not collide, worst case we were already at the end of the start cinematic
      --  and the other coroutine will try to call fade_out_and_load_stage_intro_async
      --  but the flag will prevent conflicting fade out
      self.app:start_coroutine(self.fade_out_and_load_stage_intro_async, self)
    end

    self:update_clouds()
    self:update_fx()

    if self.tails_plane_position then
      -- tune plane speed here
      self.tails_plane_position.x = self.tails_plane_position.x - 0.5 -- - tuned("plane dvx x0.5", 0) * 0.5
    end

    if self.jumping_sonic then
      -- local shrinked_speed_min_factor = 0.5 + tuned("perceived spd factor", 0)

      -- shrink Sonic based on altitude
      local shrink_start_altitude = 76 + tuned("sonic shrink dy", 0)
      if self.jumping_sonic.position.y > shrink_start_altitude then
        local scale = ui_animation.lerp(1, 0.3 + tuned("sonic scale", 0) * 0.1, (self.jumping_sonic.position.y - shrink_start_altitude) / (110 - shrink_start_altitude))
        self.jumping_sonic.scale = min(scale, 1)
      end

      -- tune sonic speed here
      local world_speed_x = 0.35 + tuned("sonic dvx x0.01", 0) * 0.01

      -- when far, we perceive motion slower, like parallax, so scale the perceived speed accordingly
      --  the perceived speed will be used to move the sprite, esp. when shrinked
      local perceived_speed_x = world_speed_x * self.jumping_sonic.scale
      local perceived_speed_y = self.jumping_sonic_vy * self.jumping_sonic.scale
      self.jumping_sonic.position.x = self.jumping_sonic.position.x - perceived_speed_x
      self.jumping_sonic.position.y = self.jumping_sonic.position.y + perceived_speed_y

      -- apply gravity on real world speed (it would be too much on perceived speed when shrinked,
      --  so we must keep working with world speed)
      self.jumping_sonic_vy = self.jumping_sonic_vy + 0.04 + tuned("gravity d x0.01", 0) * 0.01

      -- under certain altitude, make Sonic land (star animation + remove sprite)
      if self.jumping_sonic.position.y > 110 then
        self.app:start_coroutine(self.sonic_landing_star_async, self)
      end
    end

    return
  end

  if self.menu then
    self.menu:update()

    -- attract mode countdown
    if self.should_start_attract_mode then
      self:start_attract_mode()
    end
  else
    -- menu not shown yet, check for immediate show input vs normal countdown

    if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
      -- show menu immediately
      self.frames_before_showing_menu = 0
    else
      -- decrement countdown
      self.frames_before_showing_menu = self.frames_before_showing_menu - 1
    end

    if self.frames_before_showing_menu <= 0 then
      self:show_menu()
    end
  end
end

local cloud_speeds_by_size_category = {
  -0.3,
  -0.2,
  -0.15,
  -0.1,
}

function titlemenu:update_clouds()
  for i = 1, #self.clouds do
    local cloud = self.clouds[i]

    -- remember we added reverse clouds so #self.clouds = 2 * #clouds_data,
    --  so we must apply modulo to get the correct clouds data index
    local data_index = (i - 1) % #clouds_data + 1
    local cloud_data = clouds_data[data_index]
    assert(cloud_data)

    local size_category = cloud_data[1]
    local cloud_speed = cloud_speeds_by_size_category[size_category]

    -- we must also wrap new position with modulo
    -- biggest cloud covers 7 tiles => 7 * 8 = 56 (actually 54 pixels, but to be safe),
    --  so wrap so that when it leaves the screen to the right, it starts reappearing on the left,
    --  so add offset, then retrieve it to allow cloud to move until it leaves screen
    -- (same logic as visual_stage.draw_cloud)
    cloud.position.x = (cloud.position.x + cloud_speed + 56) % (screen_width + 2 * 56) - 56
  end
end

function titlemenu:update_fx()
  local to_delete = {}

  for pfx in all(self.emerald_landing_fxs) do
    pfx:update()

    if not pfx:is_active() then
      add(to_delete, pfx)
    end
  end

  -- normally we should deactivate pfx and reuse it for pooling,
  --  but deleting them was simpler (fewer characters) and single-time operation
  --- so CPU cost is OK
  for pfx in all(to_delete) do
    del(self.emerald_landing_fxs, pfx)
  end
end

function titlemenu:start_attract_mode()
    load('picosonic_attract_mode')
end

function titlemenu:render()
  self:draw_background()

  -- world elements move opposite to camera
  camera(0, self.camera_y)

  self:draw_sea_drawables()

  for drawable in all(self.cinematic_drawables_world) do
    drawable:draw()
  end

  -- reset camera, as title, menu
  camera()

  self:draw_title()

  if not self.is_playing_start_cinematic then
    self:draw_version()
  end

  if self.menu then
    self.menu:draw(55, 101)
  end

  for drawable in all(self.cinematic_drawables_screen) do
    drawable:draw()
  end

  for num in all(self.cinematic_emeralds_on_circle) do
    local draw_position = self:calculate_emerald_position_on_circle(num)
    -- draw at normal brightness
    emerald_common.draw(num, draw_position)
  end

  self:draw_fx()

  if self.tails_plane then
    self.tails_plane:render(self.tails_plane_position)
    if self.is_sonic_on_plane then
      -- we matched Sonic and Tails plane's pivot, so placing Sonic exactly there
      --  will ensure that Sonic is standing at the right position
      visual.sprite_data_t.sonic_tiny:render(self.tails_plane_position)
    end
  end

  self.postproc:apply()
end

function titlemenu:calculate_emerald_position_on_circle(number)
  -- inspired by stage_clear_state:draw_emeralds, adding rotation and elliptical effect
  local radius = visual.start_cinematic_emerald_circle_radius
  local period = visual.start_cinematic_emerald_rotation_period
  local delay_frames = visual.start_cinematic_first_emerald_enter_delay_frames
  -- rotation center at (64, 68) (slightly below screen center)
  -- emeralds rotate clockwise, so negative factor for t()
  -- initial offset is just to make sure to connect emerald entrance and reaching circle tangentially
  -- (number - 1) / 8 is to place emeralds at uniform angular distance on the circle
  local angle = -0.65 - (number - 1) / 8 - (t() - (self.start_pressed_time + (delay_frames + tuned("emerald enter dt", 0)) / 60)) / period
  local draw_position = vector(64 + radius * cos(angle), 68 + self.ellipsis_y_scalable.scale * radius * sin(angle))
  return draw_position
end

function titlemenu:draw_background()
  rectfill(0, 0, 128, 128, colors.dark_blue)
end

function titlemenu:draw_sea_drawables()
  -- water shimmer color cycle (in red and yellow in the original sprite)
  local period = visual.water_shimmer_period
  local ratio = (t() % period) / period
  local step_count = #visual.water_shimmer_color_cycle
  -- compute step from ratio (normally ratio should be < 1
  --  just in case, max to step_count)
  local step = min(flr(ratio * step_count) + 1, step_count)
  local new_colors = visual.water_shimmer_color_cycle[step]
  swap_colors({colors.red, colors.yellow}, new_colors)

  for sea_drawable in all(self.drawables_sea) do
    sea_drawable:draw()
  end

  -- while we're swapping colors for water shimmers, let's also draw all the
  --  non-sprite, procedurally generated shimmers (as in the stage) so they'll
  --  inherit palette swapping

  -- first, only draw shimmers when roughly looking at the bottom (after reverse horizon, before full loop)
  -- mind the comparison sign! camera_y goes toward negative!
  -- add some half screen height to draw them as soon as you watch a bit of water
  --  (minus 12 lines below island sprite horizon line, saw we don't try to draw
  --  them when island is fully shown / and symmetrically for revershe horizon)
  if camera_y0 - full_loop_height / 2 + screen_height / 2 - 12 > self.camera_y and self.camera_y > camera_y0 - full_loop_height - screen_height / 2 + 12 then
    -- inspired by visual_stage.draw_water_reflections, except we've already swapped colors,
    --  so draw the same raw colors as the sprites instead (red and yellow)
    -- however, if we just draw the colors the same way, they will be in sync!
    -- so we must shuffle them (but not randomly or they will change every frame,
    --  so use a spatial-based criteria that won't change over time)
    -- this is due to the difference between fixed colors + time swapping
    --  vs code-based color cycle as in visual_stage.draw_water_reflections

    -- draw every given interval on y
    local shimmer_y_interval = 9 + tuned("shimmer dy", 0)
    local shimmer_x_list_per_j = {
      {13, 30, 46, 62, 111},
      {22, 45, 51, 89, 120},
      {5, 17, 34, 70, 80},
      {23, 90},
    }

    -- sprites already contain water shimmers on ~12 lines, so skip them
    local j = 0
    for y = perfect_horizon_y - full_loop_height / 2 - 12, perfect_horizon_y - full_loop_height + 12, -shimmer_y_interval do
      j = j % #shimmer_x_list_per_j + 1  -- modulo first to make sure we get index between 1 and shimmer_x_list_per_j
      -- only draw if shimmers are visible on camera
      if y >= self.camera_y and y < self.camera_y + screen_height then
        -- wow, busted seems to define x = 2 for some reason (global? where?)
        -- so I didn't detect an error about using x outside of the for loop below
        --  in headless itests, but PICO-8 could detect it... anyway, that's fixed
        for x in all(shimmer_x_list_per_j[j]) do
          -- pseudo-randomize raw colors (based on x, so won't change next frame)
          local color1, color2
          if x % 2 == 0 then
            color1 = colors.red
            color2 = colors.yellow
          else
            color1 = colors.yellow
            color2 = colors.red
          end

          -- pseudo-randomize x to avoid regular shimmers by using y, a stable input
          x = x + y * y

          -- draw triplets for "richer" visuals
          -- wrap around as offset may cause x to go beyond 128
          pset(x % screen_width, y, color1)
          pset((x + 1) % screen_width, y, color2)
          pset((x + 2) % screen_width, y, color1)
        end
      end
    end
  end

  pal()

--#if tuner
  -- DEBUG horizon lines
  local full_loop_height = 1296 -- + tuned("full loop dy x16", 0) * 16
  -- front
  line(0, perfect_horizon_y, 128, perfect_horizon_y, colors.green)
  -- front clouds
  line(0, perfect_horizon_y - full_loop_height / 6, 128, perfect_horizon_y - full_loop_height / 6, colors.green)
  -- top
  line(0, perfect_horizon_y - full_loop_height / 4, 128, perfect_horizon_y - full_loop_height / 4, colors.green)
  -- back clouds
  line(0, perfect_horizon_y - full_loop_height / 4 - (full_loop_height / 12), 128, perfect_horizon_y - full_loop_height / 4 - (full_loop_height / 12), colors.green)
  -- back
  line(0, perfect_horizon_y - full_loop_height / 2, 128, perfect_horizon_y - full_loop_height / 2, colors.green)
  -- bottom
  line(0, perfect_horizon_y - full_loop_height * 3 / 4, 128, perfect_horizon_y - full_loop_height * 3 / 4, colors.green)
--#endif
end

function titlemenu:draw_fx()
  for pfx in all(self.emerald_landing_fxs) do
    pfx:render()
  end
end

function titlemenu:draw_title()
  self.title_logo_drawable:draw()
end

function titlemenu:draw_version()
  -- preprocess can now replace $variables so build_single_cartridge.sh
  --  will just pass the version string to the builder so it replaces $version here
  text_helper.print_aligned("V$version", 126, 2, alignments.right, colors.white, colors.black)
end

-- helper: move camera y linearly along from `from` to `to` over n frames
--  inspired by ui_animation, but specialized for 1 coord
function titlemenu:move_camera_y_async(from, to, n, tween_method)
  for frame = 1, n do
    -- note that alpha starts at 1 / n, not 0
    local alpha = frame / n
    self.camera_y = tween_method(from, to, alpha)
    yield()
  end
end

function titlemenu:tween_scalable_async(scalable_object, from, to, n, tween_method)
  for frame = 1, n do
    local alpha = frame / n
    scalable_object.scale = tween_method(from, to, alpha)
    yield()
  end
end

function titlemenu:play_start_cinematic()
  -- hide (actually destroy) menu
  self.menu = nil

  -- start bgm fade out (in parallel with coroutine start below)
  -- emeralds now use music for their looping SFX so we must fade out music
  -- just before emeralds enter, converting delay in frames to ms,
  --  so with factor 1000 / 60 = 100 / 6 = 50 / 3
  music(-1, visual.start_cinematic_first_emerald_enter_delay_frames * 50 / 3)

  self.is_playing_start_cinematic = true
  self.app:start_coroutine(self.play_start_cinematic_async, self)

--#if tuner
  -- quick advance to end
  for i=1,30*(0+tuned("skip x0.5s", 0)) do
    self.app:update()
  end
--#endif
end

function titlemenu:play_start_cinematic_async()
  -- record start time to work with stable time from start
  self.start_pressed_time = t()

  -- multiply number of frames of 100ms in Aseprite animation by 6 to get frames of (1/60)s

  -- run in parallel with emeralds entering screen, so start new coroutine from this coroutine
  self.app:start_coroutine(self.move_title_logo_out_async, self)

  yield_delay_frames(visual.start_cinematic_first_emerald_enter_delay_frames + tuned("emerald enter dt", 0))

  -- setup all emeralds to enter on screen and start rotating
  for i = 1, 8 do
    local emerald = emerald_cinematic(i, vector(-4, 93))
    add(self.emeralds, emerald)                    -- for easier tracking
    add(self.cinematic_drawables_screen, emerald)  -- for drawing
    self.app:start_coroutine(self.emerald_enter_async, self, self.emeralds[i])
  end

  -- play looped sfx for emerald flying, but for intro-loop, use music
  music(audio.music_ids.emerald_flying)

  yield_delay_frames(36)

--#if tuner
  -- infinite loop to test just emerald entrance with no camera motion
  -- yield_delay_frames(100)
  -- self:on_exit()
  -- self:on_enter()
  -- if true then
  --   return
  -- end
--#endif

  -- run complete camera motion in parallel with the other animations
  self.app:start_coroutine(self.complete_camera_motion_async, self, full_loop_height, camera_y0)

  -- we're gonna start showing clouds now, and the title logo must have been hidden by this point,
  --  so it's safe to reload spritesheet from the start_cinematic data cartridge, which contains
  --  extra sprites we didn't have room for in the builtin titlemenu data because of the big title
  --  logo
  -- for now we just use upper sprites, but to simplify just reload the whole spritesheet
  --  (it contains a copy of pico island, so it won't disappear)
  reload(0x0, 0x0, 0x2000, "data_start_cinematic.p8")

  -- add drawable clouds high in the sky

  for cloud_data in all(clouds_data) do
    local size_category = cloud_data[1]
    local initial_position = cloud_data[2]
    -- constructor is copying position, so safe
    add(self.clouds, sprite_object(cloud_sprites_per_size_category[size_category], initial_position))
  end

  -- cloud must be symmetrical relative to top of the horizon sphere,
  --  which is located at a quarter of a full circle (90 degrees)
  -- so two get the symmetrical, you must do 2*symmetry_distance - y,
  --  and 2*symmetry_distance = 2 * (perfect_horizon_y -full_loop_height / 4) = 2 * perfect_horizon_y -full_loop_height / 2
  local cloud_symmetry_y = 2 * perfect_horizon_y - full_loop_height / 2

  for cloud_data in all(clouds_data) do
    local size_category = cloud_data[1]
    local initial_position = cloud_data[2]
    -- constructor is copying position, so safe
    -- add reverse cloud
    add(self.clouds, sprite_object(cloud_sprites_per_size_category[size_category], vector(initial_position.x, cloud_symmetry_y - initial_position.y)))
  end

  for cloud in all(self.clouds) do
    add(self.cinematic_drawables_world, cloud)  -- for drawing
  end

  -- wait a little more to make sure angel island leaves screen and we can warp it to its new position
  -- but not too late so clouds are properly reloaded
  yield_delay_frames(45 --[[+ tuned("island dt", 0)]])

  -- horizon behind, it is seen upside down since camera did a complete 180 pitch turn
  -- reverse horizon is located at 180 degrees, so half-way of the full circle
  --  + some offset since the exact horizon line depends on the sprite
  -- the reserve horizon sprite itself shows the horizon line 14 pixels below the top-left pivot
  --  so we must draw it 14 pixels above screen center (64) so this matches the reverse horizon
  self.drawables_sea[2].position.y = perfect_horizon_y - 14 - full_loop_height / 2
  -- remember to make it visible
  self.drawables_sea[2].visible = true

  -- we do a complete turn (360 degrees on pitch) which allow us to sea angel island again
  self.drawables_sea[1].position.y = island_full_loop_new_y

--#if tuner
  -- infinite loop to test island warping
  -- yield_delay_frames(80 + tuned("wait loop", 0))
  -- self:on_exit()
  -- self:on_enter()
  -- self.app:stop_all_coroutines()
  -- self:play_start_cinematic()
--#endif

  yield_delay_frames(40 --[[ + tuned("ellipsis dt", 0)]])
  self:tween_scalable_async(self.ellipsis_y_scalable, 1, 0.5, 50 --[[ + tuned("ellipsis dur", 0)]], ui_animation.ease_in_out)

  yield_delay_frames(60 --[[ + tuned("ellipsis dt2", 0)]])
  self:tween_scalable_async(self.ellipsis_y_scalable, 0.5, 1, 50 --[[ + tuned("ellipsis dur", 0)]], ui_animation.ease_in_out)

  yield_delay_frames(70 --[[ + tuned("ellipsis dt3", 0)]])
  self:tween_scalable_async(self.ellipsis_y_scalable, 1, 0.5, 50 --[[ + tuned("ellipsis dur", 0)]], ui_animation.ease_in_out)

  yield_delay_frames(90 --[[ + tuned("ellipsis dt4", 0)]])
  self:tween_scalable_async(self.ellipsis_y_scalable, 0.5, 1, 50 --[[ + tuned("ellipsis dur", 0)]], ui_animation.ease_in_out)
end

function titlemenu:move_title_logo_out_async()
  -- move title logo up until it exists screen, and hide it
  ui_animation.move_drawables_on_coord_async("y", {self.title_logo_drawable}, {0}, 16, -80, 42 + tuned("move logo dt", 0))
  self.title_logo_drawable.visible = false
end

function titlemenu:complete_camera_motion_async(full_loop_height, camera_y0)
  -- 1. ease in out from island to reverse horizon
  self:move_camera_y_async(0, camera_y0 - full_loop_height / 2, 250 --[[ + tuned("->90 dt", 0) * 30 ]], ui_animation.ease_in_out)

  -- 2. back to island very fast, since not much to see on the bottom sea
  -- camera must be 88 above island (top-left pivot) to show it exactly at the bottom of the screen again
  --  which arrives just at y = island_full_loop_new_y - 88 = - full_loop_height (complete turn from 0, don't use camera_y0 to keep
  --  island at the bottom)
  self:move_camera_y_async(camera_y0 - full_loop_height / 2, - full_loop_height, 270 --[[ + tuned("->back dt", 0) * 30 ]], ui_animation.ease_in_out)

  -- 3. after camera is back to island, wait a little and play last phase
  yield_delay_frames(70 + tuned("last phase dt x10", 0) * 10)
  self:play_last_phase_async()
end

-- precompute helper constants
-- angular speed: 1 / period
-- angular distance of 1/8 (distance between emeralds) is traversed in:
--  1/8 / (1/period) = period / 8
-- or in frames:
--  60 * period / 8 = 7.5 * period
-- therefore, by delaying the next emerald by this number, we can make sure that it will arrive
--  right in time to fill the next slot on the circle, 1/8 angle after the previous emerald
local period = visual.start_cinematic_emerald_rotation_period
local next_emerald_delay = 7.5 * period

function titlemenu:emerald_enter_async(emerald)
  -- emerald enters from bottom-left to circle top, with delay depending on emerald
  -- (last emerald enters last)
  -- 3 100ms-frames of lag in Aseprite, so 18 frames between successive emeralds


  yield_delay_frames(next_emerald_delay * (8 - emerald.number))
  -- the entrance duration doesn't need to be next_emerald_delay,
  --  but this way we're sure that the next emerald enters screen at soon as the previous one
  --  reached the circle, and that the entrance duration is proportional to period,
  --  so the initial offset of circle angle in render will always match so the emerald will start
  --  moving on the circle from where it arrived tangentially
  ui_animation.move_drawables_async({emerald}, vector(-4, 93), vector(42, 47), next_emerald_delay)

  -- from here, remove emerald from normal drawables and attach it to the circle to let it
  --  be drawn with rotating circle/ellipse formula instead
  del(self.cinematic_drawables_screen, emerald)
  add(self.cinematic_emeralds_on_circle, emerald.number)
end

function titlemenu:play_last_phase_async(emerald)
  self.app:start_coroutine(self.emeralds_fly_to_island_async, self)

  yield_delay_frames(70 --[[ + tuned("wait plane dt", 0)]])

  self.app:start_coroutine(self.create_and_move_tails_plane_across_sky, self)

  yield_delay_frames(89 --[[ + tuned("wait sonic jump dt", 0)]])

  self:sonic_jump_into_island_async()

--#if tuner
  -- infinite loop to test from the start, possibly with skip to test the end
  yield_delay_frames(40 + tuned("wait loop", 0))
  self:on_exit()
  self:on_enter()
  self.app:stop_all_coroutines()
  self:play_start_cinematic()
--#endif
end

function titlemenu:emeralds_fly_to_island_async()
  -- one by one, the emeralds leave the circle and fly toward a predetermined destination
  --  on the island, shrinking and landing with a star
  -- this time we'll put the delay inside the loop, before coroutine start,
  --  so delays will be small, but cumulated, so make sure to iterate
  --  chronologically, ie starting with emerald 8, the first to land
  for i = 8, 1, -1 do
    self.app:start_coroutine(self.emerald_fly_to_island_async, self, self.emeralds[i])
    yield_delay_frames(next_emerald_delay)
  end

  -- start fading out looping emerald flying SFX, it should end by the time
  --  the last emerald left the circle (but it depends on timing data)
  music(-1, 1000 + tuned("fade out", 0) * 1000)
end

local emerald_landing_positions = {
  -- on-screen coordinates, somewhere on Angel Island sprite
  -- the coordinates broadly correspond to where emeralds are in the level,
  --  assuming we're facing the island like the stage (can be used as a small hint...)
  -- the coordinates have been placed in Aseprite
  vector(68, 111),  -- red
  vector(71, 108),  -- peach
  vector(72, 114),  -- pink
  vector(76, 108),  -- indigo
  vector(84, 110),  -- blue
  vector(80, 112),  -- yellow
  vector(89, 111),  -- green
  vector(86, 114),  -- orange
}

function titlemenu:emerald_fly_to_island_async(emerald)
  -- detach emerald from circle, readd to free screen drawables
  del(self.cinematic_emeralds_on_circle, emerald.number)
  add(self.cinematic_drawables_screen, emerald)

  -- shrink emerald by reducing scale in parallel with incoming motion
  self.app:start_coroutine(self.tween_scalable_async, self, emerald, 1, 0.2 + tuned("em scale", 0) * 0.1, 24, ui_animation.lerp)

  -- calculate position on emerald circle at current time
  --  so we can interpolate from the same position for continuous motion
  local circle_position = self:calculate_emerald_position_on_circle(emerald.number)
  -- this time, here is no relationship between emeralds, they don't chain, so we picked a delay
  -- for motion that's longer than next_emerald_delay
  ui_animation.move_drawables_async({emerald}, circle_position, emerald_landing_positions[emerald.number], 24)

  -- hide emerald
  del(self.cinematic_drawables_screen, emerald)

  -- add emerald landing FX at emerald landing position and play it immediately
  -- note that interpolation is over, so emerald.position == emerald_landing_positions[emerald.number]
  assert(emerald.position == emerald_landing_positions[emerald.number])
  local pfx = emerald_fx(emerald.number, emerald.position, visual.animated_sprite_data_t.star_fx)
  add(self.emerald_landing_fxs, pfx)
end

function titlemenu:create_and_move_tails_plane_across_sky()
  self.tails_plane = animated_sprite(visual.animated_sprite_data_t.tails_plane)
  self.tails_plane:play('loop')

  -- enter from right
  self.tails_plane_position = vector(136, 63)
  self.is_sonic_on_plane = true

  -- for the motion, let update do the job, instead of doing an interpolation
  --  (ui_animation helpers only work with drawable so we'd need to write our own
  --  loop, although move_camera_y_async did it, this one will be useful for complex
  --  tweens while tails plane always moves linearly)
end

function titlemenu:sonic_jump_into_island_async()
  -- remove sonic standing on plane
  self.is_sonic_on_plane = false

  -- sonic spin tiny pivot has also been set to match previous standing position,
  --  and hence the plane
  -- constructing is copying position, so safe
  self.jumping_sonic = sprite_object(visual.sprite_data_t.sonic_spin_tiny, self.tails_plane_position)
  self.jumping_sonic_vy = -0.2 - tuned("sonic vy0 x-0.01", 0) * 0.01
  add(self.cinematic_drawables_screen, self.jumping_sonic)

  -- play jump sound
  sfx(audio.sfx_ids.jump)

  -- like Tails plane, count on physics update to move Sonic to the landing position
  -- when Sonic y reaches a certain point, the star animation will automatically play
end

function titlemenu:sonic_landing_star_async()
  -- as a hack, reuse emerald fx which is just a star, for Sonic landing fx
  -- Sonic is blue, which corresponds to emerald number 5, so pass 5
  --  to get a blue star
  local pfx = emerald_fx(5, self.jumping_sonic.position, visual.animated_sprite_data_t.star_fx)
  add(self.emerald_landing_fxs, pfx)

  -- remove sonic jumping sprite, now replaced by star
  del(self.cinematic_drawables_screen, self.jumping_sonic)

  self.jumping_sonic = nil

  -- we've reached the end of the start cinematic!
  -- we must still wait a few frames to see the landing fx ending, then we can
  -- fade out (we start from everything black so skip max darkness 5)
  yield_delay_frames(20)

  self:fade_out_and_load_stage_intro_async()
end

function titlemenu:fade_out_and_load_stage_intro_async()
  if not self.is_fading_out_for_stage_intro then
    self.is_fading_out_for_stage_intro = true

    -- fade out
    for i = 1, 5 do
      self.postproc.darkness = i
      yield_delay_frames(6)
    end

    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_stage_intro')
  end
end

return titlemenu
