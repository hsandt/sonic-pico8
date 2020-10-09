require("test/bustedhelper")
local camera_class = require("ingame/camera")

local camera_data = require("data/camera_data")
local player_char = require("ingame/playercharacter")

describe('camera', function ()

  describe('init', function ()

    it('should init members to defaults', function ()
      local cam = camera_class()
      assert.are_same({nil, vector.zero(), 0}, {cam.target_pc, cam.position, cam.forward_offset})
    end)

  end)

  describe('setup_for_stage', function ()

    it('should initialize camera at future character spawn position', function ()
      local mock_curr_stage_data = {
        spawn_location = location(1, 2)
      }

      local cam = camera_class()
      cam:setup_for_stage(mock_curr_stage_data)

      local spawn_position = mock_curr_stage_data.spawn_location:to_center_position()
      assert.are_same(spawn_position, cam.position)
    end)

  end)

  describe('update_camera', function ()

    local cam
    local pc

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

    it('should move the camera X so player X is on left edge if he goes beyond left edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 - camera_data.window_half_width - 1, 80)

      cam:update()

      assert.are_equal(120 - 1, cam.position.x)
    end)

    it('should not move the camera on X if player X remains in window X (left edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 - camera_data.window_half_width, 80)

      cam:update()

      assert.are_equal(120, cam.position.x)
    end)

    it('should not move the camera on X if player X remains in window X (right edge)', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 + camera_data.window_half_width, 80)

      cam:update()

      assert.are_equal(120, cam.position.x)
    end)

    it('should move the camera X so player X is on right edge if he goes beyond right edge', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120 + camera_data.window_half_width + 1, 80)

      cam:update()

      assert.are_equal(120 + 1, cam.position.x)
    end)

    -- forward extension, positive X
    -- at forward_ext_min_speed_x the ratio is still 0, so we need a little more to test actual change

    it('forward extension: should increase forward extension by catch up speed when character reaches (forward_ext_min_speed_x + max_forward_ext_speed_x) / 2', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should increase forward extension toward max by catch up speed when character reaches max_forward_ext_speed_x', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.max_forward_ext_speed_x, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should increase forward extension by catch up speed until half max when character stays at (forward_ext_min_speed_x + max_forward_ext_speed_x) / 2 for long', function ()
      -- simulate a camera that has already been moving toward half max offset and close to reaching it
      cam.forward_offset = camera_data.forward_ext_max_distance / 2 - 0.1  -- just subtract something lower than camera_data.forward_ext_max_distance
      -- to reproduce the fast that the camera is more forward that it should be with window only,
      --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_max_distance / 2, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_max_distance / 2, cam.position.x)
    end)

    it('forward extension: should increase forward extension by catch up speed until max when character stays at max_forward_ext_speed_x for long', function ()
      -- simulate a camera that has already been moving toward max offset and close to reaching it
      cam.forward_offset = camera_data.forward_ext_max_distance - 0.1  -- just subtract something lower than camera_data.forward_ext_max_distance
      -- to reproduce the fast that the camera is more forward that it should be with window only,
      --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.max_forward_ext_speed_x, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_max_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_max_distance, cam.position.x)
    end)

    it('forward extension: should increase forward extension by catch up speed until max (and not more) even when character stays *above* max_forward_ext_speed_x for long', function ()
      cam.forward_offset = camera_data.forward_ext_max_distance - 0.1  -- just subtract something lower than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.max_forward_ext_speed_x + 1, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_max_distance, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_max_distance, cam.position.x)
    end)

    it('forward extension: should decrease forward extension by catch up speed until half max when character goes at (forward_ext_min_speed_x + max_forward_ext_speed_x) / 2 again', function ()
      cam.forward_offset = camera_data.forward_ext_max_distance / 2 + 0.1  -- just add something lower than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_max_distance / 2, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_max_distance / 2, cam.position.x)
    end)

    it('forward extension: should decrease forward extension by catch up speed when character goes below max_forward_ext_speed_x again (and low enough to be perceptible)', function ()
      cam.forward_offset = camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector((camera_data.forward_ext_min_speed_x + camera_data.max_forward_ext_speed_x) / 2, 0)

      cam:update()

      assert.are_equal(camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 + camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should decrease forward extension back to 0 when character goes below forward_ext_min_speed_x for long', function ()
      cam.forward_offset = 0.1  -- just something lower than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(camera_data.forward_ext_min_speed_x - 1, 0)

      cam:update()

      assert.are_equal(0, cam.forward_offset)
      assert.are_equal(120, cam.position.x)
    end)

    -- same, but forward is negative X

    it('forward extension: should increase forward extension toward NEGATIVE by catch up speed when character reaches -max_forward_ext_speed_x', function ()
      cam.position = vector(120, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-camera_data.max_forward_ext_speed_x, 0)

      cam:update()

      assert.are_equal(-camera_data.forward_ext_catchup_speed_x, cam.forward_offset)
      assert.are_equal(120 - camera_data.forward_ext_catchup_speed_x, cam.position.x)
    end)

    it('forward extension: should increase forward extension toward NEGATIVE by catch up speed until max when character stays above -max_forward_ext_speed_x for long', function ()
      cam.forward_offset = -(camera_data.forward_ext_max_distance - 0.1)  -- just subtract something lower than camera_data.forward_ext_max_distance
      -- to reproduce the fast that the camera is more forward that it should be with window only,
      --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-camera_data.max_forward_ext_speed_x, 0)

      cam:update()

      assert.are_equal(-camera_data.forward_ext_max_distance, cam.forward_offset)
      assert.are_equal(120 - camera_data.forward_ext_max_distance, cam.position.x)
    end)

    it('forward extension: should decrease forward extension (in abs) by catch up speed when character goes below max_forward_ext_speed_x (in abs) again', function ()
      cam.forward_offset = -camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-(camera_data.max_forward_ext_speed_x - 1), 0)

      cam:update()

      assert.are_equal(-(camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x), cam.forward_offset)
      assert.are_equal(120 - (camera_data.forward_ext_max_distance - camera_data.forward_ext_catchup_speed_x), cam.position.x)
    end)

    it('forward extension: should decrease forward extension (in abs) back to 0 when character goes below max_forward_ext_speed_x (in abs) for long', function ()
      cam.forward_offset = -0.1  -- just something lower (in abs) than camera_data.forward_ext_max_distance
      cam.position = vector(120 + cam.forward_offset, 80)
      cam.target_pc.position = vector(120, 80)
      cam.target_pc.velocity = vector(-(camera_data.max_forward_ext_speed_x - 1), 0)

      cam:update()

      assert.are_equal(0, cam.forward_offset)
      assert.are_equal(120, cam.position.x)
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

    it('#solo should move the camera to player position, clamped (top-left)', function ()
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
      cam.position = vector(800-64, 160-64)
      cam.target_pc.position = vector(2000, 1000)

      cam:update()

      assert.are_same(vector(800-64, 160-64), cam.position)
    end)

  end)



end)
