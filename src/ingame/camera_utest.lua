require("test/bustedhelper_ingame")
local camera_class = require("ingame/camera")

local camera_data = require("data/camera_data")
local player_char = require("ingame/playercharacter")

describe('camera_class', function ()

  describe('init', function ()

    it('should init members to defaults', function ()
      local cam = camera_class()
      assert.are_same({nil, vector.zero(), 0, horizontal_dirs.right, 0},
        {cam.target_pc, cam.position, cam.forward_offset, cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change})
    end)

  end)

  describe('setup_for_stage', function ()

    it('should initialize camera at future character spawn position (+ estimated future forward base offset)', function ()
      local mock_curr_stage_data = {
        spawn_location = location(1, 2)
      }

      local cam = camera_class()
      cam:setup_for_stage(mock_curr_stage_data)

      local spawn_position = mock_curr_stage_data.spawn_location:to_center_position()
      assert.are_same(spawn_position, cam.position)
    end)

    it('should initialize forward_offset to + camera_data.forward_distance ', function ()
      local mock_curr_stage_data = {
        -- doesn't matter for this test
        spawn_location = location(1, 2)
      }

      local cam = camera_class()
      cam:setup_for_stage(mock_curr_stage_data)

      assert.are_same(camera_data.forward_distance, cam.forward_offset)
    end)

  end)

  describe('update_camera', function ()

    local cam
    local pc

    setup(function ()
      stub(camera_class, "get_bottom_limit_at_x", function (self, x)
        if x < 50 * tile_size then
          return 28 * tile_size  -- margin of 2 -> 224
        else
          return 30 * tile_size  -- 240, to match tile_height below, means bottom limit offset is 0
        end
      end)
    end)

    teardown(function ()
      camera_class.get_bottom_limit_at_x:revert()
    end)

    after_each(function ()
      camera_class.get_bottom_limit_at_x:clear()
    end)

    before_each(function ()
      -- required for stage edge clamping
      -- we only need to mock width and height,
      --  normally we'd get full stage data as in stage_data.lua
      local mock_curr_stage_data = {
        tile_width = 100,
        tile_height = 20
      }

      pc = player_char()

      cam = camera_class()
      cam.stage_data = mock_curr_stage_data
      cam.target_pc = pc
    end)

    it('(debug motion) should track the player 1:1', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_mode = motion_modes.debug
      cam.target_pc.position = vector(140, 100)

      cam:update()

      assert.are_same(vector(140, 100), cam.position)
    end)

    it('(pc grounded, last orientation is not current) should change last_grounded_orientation and reset frames_since_grounded_orientation_change', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.left
      cam.frames_since_grounded_orientation_change = 1
      cam.target_pc.orientation = horizontal_dirs.left
      cam.target_pc.motion_state = motion_states.standing

      cam:update()

      assert.are_same({horizontal_dirs.left, 0}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change})
    end)

    it('(pc grounded, last orientation is current, but not confirmed and timer has just started) should keep last_grounded_orientation, increment frames_since_grounded_orientation_change, keep confirmed orientation', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.left
      cam.frames_since_grounded_orientation_change = 1
      cam.target_pc.orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.standing

      cam:update()

      assert.are_same({horizontal_dirs.right, 2, horizontal_dirs.left}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change, cam.confirmed_orientation})
    end)

    it('(pc grounded, last orientation is current, but not confirmed and timer is just before the end) should keep last_grounded_orientation, increment frames_since_grounded_orientation_change and change confirmed_orientation', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.left
      cam.frames_since_grounded_orientation_change = camera_data.grounded_orientation_confirmation_duration - 1
      cam.target_pc.orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.standing

      cam:update()

      assert.are_same({horizontal_dirs.right, camera_data.grounded_orientation_confirmation_duration, horizontal_dirs.right}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change, cam.confirmed_orientation})
    end)

    it('(pc grounded, last orientation is current, and confirmed) should keep last_grounded_orientation and keep frames_since_grounded_orientation_change', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.right
      cam.frames_since_grounded_orientation_change = 1
      cam.target_pc.orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.standing

      cam:update()

      assert.are_same({horizontal_dirs.right, 1}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change})
    end)

    it('(pc not grounded, last orientation is not confirmed) should keep last_grounded_orientation, increment frames_since_grounded_orientation_change, keep confirmed orientation', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.left
      cam.frames_since_grounded_orientation_change = 1
      cam.target_pc.orientation = horizontal_dirs.left  -- ignored in the air
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_same({horizontal_dirs.right, 2, horizontal_dirs.left}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change, cam.confirmed_orientation})
    end)

    it('(pc not grounded, last orientation is not confirmed) should keep last_grounded_orientation, increment frames_since_grounded_orientation_change, change confirmed orientation', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.left
      cam.frames_since_grounded_orientation_change = camera_data.grounded_orientation_confirmation_duration - 1
      cam.target_pc.orientation = horizontal_dirs.left  -- ignored in the air
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_same({horizontal_dirs.right, camera_data.grounded_orientation_confirmation_duration, horizontal_dirs.right}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change, cam.confirmed_orientation})
    end)

    it('(pc not grounded, last orientation is confirmed) should keep last_grounded_orientation and keep frames_since_grounded_orientation_change', function ()
      cam.last_grounded_orientation = horizontal_dirs.right
      cam.confirmed_orientation = horizontal_dirs.right
      cam.frames_since_grounded_orientation_change = 1
      cam.target_pc.orientation = horizontal_dirs.left  -- ignored in the air
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_same({horizontal_dirs.right, 1}, {cam.last_grounded_orientation, cam.frames_since_grounded_orientation_change})
    end)

    -- below, make sure to test base_position_x instead of cam.position.x if you want to ignore the forward offset,
    --  and in particular the base forward offset which is always present due to orientation

    it('should move the camera X so player X is on left edge if he goes beyond left edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 - camera_data.window_half_width - 1, 80)

      cam:update()

      assert.are_equal(120 - 1, cam.base_position_x)
    end)

    it('should not move the camera on X if player X remains in window X (left edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 - camera_data.window_half_width, 80)

      cam:update()

      assert.are_equal(120, cam.base_position_x)
    end)

    it('should not move the camera on X if player X remains in window X (right edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 + camera_data.window_half_width, 80)

      cam:update()

      assert.are_equal(120, cam.base_position_x)
    end)

    it('should move the camera X so player X is on right edge if he goes beyond right edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 + camera_data.window_half_width + 1, 80)

      cam:update()

      assert.are_equal(120 + 1, cam.base_position_x)
    end)

    -- forward base, positive X

    it('forward base: should increase forward offset toward + camera_data.forward_distance by catch up speed (not clamped yet) when character faces right (but not moving fast)', function ()
      cam.position = vector(120, 80)
      cam.forward_offset = 0
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector.zero()
      -- we try to set state to falling to make sure we don't update
      --  confirmed_orientation and use the stored one
      -- for the same reason we don't care about cam.target_pc.orientation here,
      --  but set confirmed_orientation instead
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward base: should increase forward offset toward + camera_data.forward_distance by catch up speed (clamped) when character faces right (but not moving fast)', function ()
      cam.position = vector(120 + camera_data.forward_distance, 80)
      cam.forward_offset = camera_data.forward_distance
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector.zero()
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance, cam.position.x)
    end)

    -- forward base, negative X

    it('forward base: should increase forward offset toward - camera_data.forward_distance by catch up speed (not clamped yet) when character faces left (but not moving fast)', function ()
      cam.position = vector(120, 80)
      cam.forward_offset = 0
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector.zero()
      cam.confirmed_orientation = horizontal_dirs.left
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(- camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 - camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward base: should increase forward offset toward - camera_data.forward_distance by catch up speed (clamped) when character faces left (but not moving fast)', function ()
      cam.position = vector(120 - camera_data.forward_distance, 80)
      cam.forward_offset = - camera_data.forward_distance
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector.zero()
      cam.confirmed_orientation = horizontal_dirs.left
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(- camera_data.forward_distance, cam.forward_offset)
      assert.are_equal(120 - camera_data.forward_distance, cam.position.x)
    end)

    -- forward extension, positive X
    -- at forward_ext_min_speed_x the ratio is still 0, so we need a little more to test actual change

    it('forward extension: should increase forward extension by catch up speed when character reaches (forward_ext_min_speed_x + max_forward_ext_speed_x) / 2', function ()
      -- we start from offset 0 so the forward base offset doesn't have an impact here

      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should increase forward extension toward max by catch up speed when character reaches max_forward_ext_speed_x', function ()
      -- we start from offset 0 so the forward base offset doesn't have an impact here

      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.max_forward_ext_speed_x, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should increase forward extension by catch up speed until half max when character stays at (forward_ext_min_speed_x + max_forward_ext_speed_x) / 2 for long', function ()
      -- here we are reaching the max, so base forward offset contribution is felt, add it
      --  everywhere

      -- simulate a camera that has already been moving toward half max offset and close to reaching it
      cam.forward_offset = camera_data.forward_distance + camera_data.forward_ext_max_distance / 2 - 0.1  -- just subtract something lower than camera_data.forward_ext_max_distance
      -- to reproduce the fast that the camera is more forward that it should be with window only,
      --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_distance + camera_data.forward_ext_max_distance / 2, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance + camera_data.forward_ext_max_distance / 2, cam.position.x)
    end)

    it('forward extension: should increase forward extension by catch up speed until max when character stays at max_forward_ext_speed_x for long', function ()
      -- here we are reaching the max, so base forward offset contribution is felt, add it
      --  everywhere

      -- simulate a camera that has already been moving toward max offset and close to reaching it
      cam.forward_offset = camera_data.forward_distance + camera_data.forward_ext_max_distance - 0.1  -- just subtract something lower than camera_data.forward_ext_max_distance
      -- to reproduce the fast that the camera is more forward that it should be with window only,
      --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.max_forward_ext_speed_x, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_distance + camera_data.forward_ext_max_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance + camera_data.forward_ext_max_distance, cam.position.x)
    end)

    it('forward extension: should increase forward extension by catch up speed until max (and not more) even when character stays *above* max_forward_ext_speed_x for long', function ()
      -- here we are reaching the max, so base forward offset contribution is felt, add it
      --  everywhere

      cam.forward_offset = camera_data.forward_distance + camera_data.forward_ext_max_distance - 0.1  -- just subtract something lower than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.max_forward_ext_speed_x + 1, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_distance + camera_data.forward_ext_max_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance + camera_data.forward_ext_max_distance, cam.position.x)
    end)

    it('forward extension: should decrease forward extension by catch up speed until half max when character goes at (forward_ext_min_speed_x + max_forward_ext_speed_x) / 2 again', function ()
      -- here we are reaching the max, so base forward offset contribution is felt, add it
      --  everywhere

      cam.forward_offset = camera_data.forward_distance + camera_data.forward_ext_max_distance / 2 + 0.1  -- just add something lower than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_distance + camera_data.forward_ext_max_distance / 2, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance + camera_data.forward_ext_max_distance / 2, cam.position.x)
    end)

    it('forward extension: should decrease forward extension by catch up speed when character goes below max_forward_ext_speed_x again (and low enough to be perceptible)', function ()
      -- here we decrease back toward the opposite sign from the max,
      --  so the forward base offset doesn't have an impact

      cam.forward_offset = camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should decrease forward extension back to 0 when character goes below forward_ext_min_speed_x for long', function ()
      -- here we are reaching the new target 0, so base forward offset contribution is felt, add it
      --  everywhere

      cam.forward_offset = camera_data.forward_distance + 0.1  -- just something lower than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.forward_ext_min_speed_x - 1, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(0 + camera_data.forward_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance, cam.position.x)
    end)

    -- same, but forward is negative X
    -- keep facing direction right so we can test when the forward base offset contribution
    --  opposes the forward extension

    it('forward extension: should increase forward extension toward NEGATIVE by catch up speed when character reaches -max_forward_ext_speed_x', function ()
      -- we start from offset 0 so the forward base offset doesn't have an impact here

      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-camera_data.max_forward_ext_speed_x, 0)
      cam.confirmed_orientation = horizontal_dirs.right
      cam.target_pc.motion_state = motion_states.falling

      cam:update()

      assert.are_equal(-camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 - camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should increase forward extension toward NEGATIVE by catch up speed until max when character stays above -max_forward_ext_speed_x for long', function ()
      -- here we are reaching the negative max, so base forward offset contribution is felt, add it
      --  everywhere

      cam.forward_offset = camera_data.forward_distance - (camera_data.forward_ext_max_distance - 0.1)  -- just subtract something lower than camera_data.forward_ext_max_distance
      -- to reproduce the fast that the camera is more forward that it should be with window only,
      --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-camera_data.max_forward_ext_speed_x, 0)

      cam:update()

      assert.are_equal(camera_data.forward_distance - camera_data.forward_ext_max_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance - camera_data.forward_ext_max_distance, cam.position.x)
    end)

    it('forward extension: should decrease forward extension (in abs) by catch up speed when character goes below max_forward_ext_speed_x (in abs) again', function ()
      -- here we are reaching the negative max, so base forward offset contribution is felt, add it
      --  everywhere

      cam.forward_offset = camera_data.forward_distance - camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-(camera_data.max_forward_ext_speed_x - 1), 0)

      cam:update()

      assert.are_equal(camera_data.forward_distance - (camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x), cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance - (camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x), cam.position.x)
    end)

    it('forward extension: should decrease forward extension (in abs) back to 0 when character goes below max_forward_ext_speed_x (in abs) for long', function ()
      -- here we are reaching the new target 0, so base forward offset contribution is felt, add it
      --  everywhere

      cam.forward_offset = camera_data.forward_distance - 0.1  -- just something lower (in abs) than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-(camera_data.max_forward_ext_speed_x - 1), 0)

      cam:update()

      assert.are_equal(0 + camera_data.forward_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_distance, cam.position.x)
    end)

    -- Y

    it('(standing, low ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond top edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      -- alternative +/- ground speed to check abs logic
      cam.target_pc.ground_speed = -(camera_data.fast_catchup_min_ground_speed - 0.5)
      -- it's hard to find realistic values for such a motion, where you're move slowly on a slope but still
      --  fast vertically... but it should be possible on a very high slope. Here we imagine a wall where we move
      --  at ground speed 3.5, 100% vertically!
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.slow_catchup_speed_y + 0.5))

      cam:update()

      -- extra 0.5 was cut
      assert.are_equal(80 - camera_data.slow_catchup_speed_y, cam.position.y)
    end)

    it('(standing, high ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond top edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = camera_data.fast_catchup_min_ground_speed
      -- unrealistic, we have ground speed 4 but still move by more than 8, impossible even on vertical wall... but good for testing
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.fast_catchup_speed_y + 0.5))

      cam:update()

      -- extra 0.5 was cut
      assert.are_equal(80 - camera_data.fast_catchup_speed_y, cam.position.y)
    end)

    it('(standing, low ground speed) should move the camera Y to match player Y if he goes beyond top edge slower than low catchup speed', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = camera_data.fast_catchup_min_ground_speed - 0.5
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.slow_catchup_speed_y - 0.5))

      cam:update()

      assert.are_equal(80 - (camera_data.slow_catchup_speed_y - 0.5), cam.position.y)
    end)

    it('(standing, high ground speed) should move the camera Y to match player Y if he goes beyond top edge slower than fast catchup speed', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = -camera_data.fast_catchup_min_ground_speed
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.fast_catchup_speed_y - 0.5))

      cam:update()

      assert.are_equal(80 - (camera_data.fast_catchup_speed_y - 0.5), cam.position.y)
    end)

    it('(standing) should not move the camera Y if player Y remains in window Y (top edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = -(camera_data.fast_catchup_min_ground_speed - 0.5)
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y)

      cam:update()

      assert.are_equal(80, cam.position.y)
    end)

    it('(standing) should not move the camera Y if player Y remains in window Y (bottom edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = camera_data.fast_catchup_min_ground_speed
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y)

      cam:update()

      assert.are_equal(80, cam.position.y)
    end)

    it('(standing, low ground speed) should move the camera Y to match player Y if he goes beyond bottom edge slower than low catchup speed', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = camera_data.fast_catchup_min_ground_speed - 0.5
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.slow_catchup_speed_y - 0.5))

      cam:update()

      assert.are_equal(80 + (camera_data.slow_catchup_speed_y - 0.5), cam.position.y)
    end)

    it('(standing, high ground speed) should move the camera Y to match player Y if he goes beyond bottom edge slower than low catchup speed', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = -camera_data.fast_catchup_min_ground_speed
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.fast_catchup_speed_y - 0.5))

      cam:update()

      assert.are_equal(80 + (camera_data.fast_catchup_speed_y - 0.5), cam.position.y)
    end)

    it('(standing, low ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond bottom edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = -(camera_data.fast_catchup_min_ground_speed - 0.5)
      -- it's hard to find realistic values for such a motion, where you're move slowly on a slope but still
      --  fast vertically... but it should be possible on a very high slope. Here we imagine a wall where we move
      --  at ground speed 3.5, 100% vertically!
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.slow_catchup_speed_y + 0.5))

      cam:update()

      -- extra 0.5 was cut
      assert.are_equal(80 + camera_data.slow_catchup_speed_y, cam.position.y)
    end)

    it('(standing, high ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond bottom edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.standing
      cam.target_pc.ground_speed = camera_data.fast_catchup_min_ground_speed
      -- unrealistic, we have ground speed 4 but still move by more than 8, impossible even on vertical wall... but good for testing
      cam.target_pc.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.fast_catchup_speed_y + 0.5))

      cam:update()

      -- extra 0.5 was cut
      assert.are_equal(80 + camera_data.fast_catchup_speed_y, cam.position.y)
    end)

    it('(airborne) should move the camera Y toward player Y with fast catchup speed (so that it gets closer to top edge) if player Y goes beyond top edge faster than fast_catchup_speed_y', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.air_spin
      cam.target_pc.position = vector(120 , 80 + camera_data.window_center_offset_y - camera_data.window_half_height - (camera_data.fast_catchup_speed_y + 5))

      cam:update()

      -- extra 5 was cut
      assert.are_equal(80 - camera_data.fast_catchup_speed_y, cam.position.y)
    end)

    it('(airborne) should move the camera Y so player Y is on top edge if he goes beyond top edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.air_spin
      cam.target_pc.position = vector(120 , 80 + camera_data.window_center_offset_y - camera_data.window_half_height - 1)

      cam:update()

      assert.are_equal(80 - 1, cam.position.y)
    end)

    it('(airborne) should not move the camera on Y if player Y remains in window Y (top edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.air_spin
      cam.target_pc.position = vector(120 , 80 + camera_data.window_center_offset_y - camera_data.window_half_height)

      cam:update()

      assert.are_equal(80, cam.position.y)
    end)

    it('(airborne) should not move the camera on X if player X remains in window X (bottom edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.air_spin
      cam.target_pc.position = vector(120 , 80 + camera_data.window_center_offset_y + camera_data.window_half_height)

      cam:update()

      assert.are_equal(80, cam.position.y)
    end)

    it('(airborne) should move the camera X so player X is on bottom edge if he goes beyond bottom edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.air_spin
      cam.target_pc.position = vector(120 , 80 + camera_data.window_center_offset_y + camera_data.window_half_height + 1)

      cam:update()

      assert.are_equal(80 + 1, cam.position.y)
    end)

    it('(airborne) should move the camera Y toward player Y with fast catchup speed (so that it gets closer to bottom edge) if player Y goes beyond bottom edge faster than fast_catchup_speed_y', function ()
      cam.position = vector(120, 80)
      cam.target_pc.motion_state = motion_states.air_spin
      cam.target_pc.position = vector(120 , 80 + camera_data.window_center_offset_y + camera_data.window_half_height + (camera_data.fast_catchup_speed_y + 5))

      cam:update()

      -- extra 5 was cut
      assert.are_equal(80 + camera_data.fast_catchup_speed_y, cam.position.y)
    end)

    it('should move the camera to player position, clamped (top-left)', function ()
      cam.target_pc.ground_speed = camera_data.fast_catchup_min_ground_speed
      -- start near/at the edge already, if you're too far the camera won't have
      --  time to reach the edge in one update due to smooth motion (in y)
      -- pick offsets of camera_data.slow_catchup_speed_y or lower to be safe
      cam.position = vector(64 + 2, 64 + 2)
      cam.target_pc.position = vector(12, 24)

      cam:update()

      assert.are_same(vector(64, 64), cam.position)
    end)

    it('should move the camera to player position, clamped (bottom-right)', function ()
      -- start near/at the edge already, if you're too far the camera won't have
      --  time to reach the edge in one update due to smooth motion (in y)
      cam.position = vector(800-64, 240-64)
      cam.target_pc.position = vector(2000, 1000)

      cam:update()

      assert.are_same(vector(800-64, 240-64), cam.position)
    end)

    it('should move the camera to player position, clamped (bottom-right, bottom limit offset 0)', function ()
      -- start near/at the edge already, if you're too far the camera won't have
      --  time to reach the edge in one update due to smooth motion (in y)
      cam.position = vector(800-64, 240-64)
      cam.target_pc.position = vector(2000, 1000)

      cam:update()

      assert.are_same(vector(800-64, 240-64), cam.position)
    end)

    it('should move the camera to player position, clamped (bottom-left, bottom limit offset 2)', function ()
      -- start near/at the edge already, if you're too far the camera won't have
      --  time to reach the edge in one update due to smooth motion (in y)
      cam.position = vector(64, 224-64)
      cam.target_pc.position = vector(0, 1000)

      cam:update()

      assert.are_same(vector(64, 224-64), cam.position)
    end)

  end)

  describe('get_bottom_limit_at_x', function ()

    local cam

    before_each(function ()
      local mock_curr_stage_data = {
        tile_width = 200,  -- not needed for this test, but helps us imagine
        tile_height = 100,
        camera_bottom_limit_margin_keypoints = {
          vector(10, 50),  -- margin 50, reaches tile 50 so y = 400
          vector(30, 20),  -- margin 20, reaches tile 80 so y = 640
          -- no margin from tile 20 until the end
        }
      }

      cam = camera_class()
      cam.stage_data = mock_curr_stage_data
    end)

    it('should return complement of margin 50 for pixel scale for x = 9 * tile_size + .9', function ()
      assert.are_equal((100 - 50) * tile_size, cam:get_bottom_limit_at_x(9 * tile_size + .9))
    end)

    it('should return complement of margin 20 for pixel scale for x = 10 * tile_size', function ()
      assert.are_equal((100 - 20) * tile_size, cam:get_bottom_limit_at_x(10 * tile_size))
    end)

    it('should return complement of margin 20 for pixel scale for x = 29 * tile_size', function ()
      assert.are_equal((100 - 20) * tile_size, cam:get_bottom_limit_at_x(29 * tile_size))
    end)

    it('should return complement of margin 0 (reaches end of curve) for pixel scale for x = 30 * tile_size', function ()
      assert.are_equal(100 * tile_size, cam:get_bottom_limit_at_x(30 * tile_size))
    end)

  end)

end)
