require("bustedhelper")
local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")
local animated_sprite = require("engine/render/animated_sprite")

describe('animated_sprite', function ()

  local spr_data1 = sprite_data(sprite_id_location(1, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data2 = sprite_data(sprite_id_location(2, 0), tile_vector(1, 2), vector(4, 6))
  local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 10, true)
  local anim_spr_data_once = animated_sprite_data({spr_data1, spr_data2}, 10, false)

  describe('_init', function ()
    it('should init an animated sprite with data, automatically playing from step 1, frame 0', function ()
      local anim_spr = animated_sprite(anim_spr_data)
      assert.are_same({anim_spr_data, true, 1, 0},
        {anim_spr.data, anim_spr.playing, anim_spr.current_step, anim_spr.local_frame})
    end)
  end)

  describe('_tostring', function ()

    it('should return a string describing data, current step and local frame', function ()
      local anim_spr = animated_sprite(anim_spr_data)
      anim_spr.current_step = 2
      anim_spr.local_frame = 5
      assert.are_equal("animated_sprite(animated_sprite_data([2 sprites], 10, true), true, 2, 5)", anim_spr:_tostring())
    end)

  end)

  describe('update', function ()

    it('should increment the local frame if under the animation step_frames', function ()
      local anim_spr = animated_sprite(anim_spr_data)
      anim_spr.playing = true
      anim_spr.current_step = 1
      anim_spr.local_frame = 8  -- data.step_frames is 10, so frames play from 0 to 9

      anim_spr:update()

      assert.are_same({1, 9},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should reset local frame and enter next step when step_frames is reached', function ()
      local anim_spr = animated_sprite(anim_spr_data)
      anim_spr.playing = true
      anim_spr.current_step = 1
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({2, 0},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should continue playing from the start when looping and end of animation has been reached', function ()
      local anim_spr = animated_sprite(anim_spr_data)
      anim_spr.playing = true
      anim_spr.current_step = 2
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({true, 1, 0},
        {anim_spr.playing, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should stop playing when not looping and end of animation has been reached', function ()
      local anim_spr = animated_sprite(anim_spr_data_once)
      anim_spr.playing = true
      anim_spr.current_step = 2
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({false, 2, 9},
        {anim_spr.playing, anim_spr.current_step, anim_spr.local_frame})
    end)

  end)

  describe('render', function ()

    local anim_spr = animated_sprite(anim_spr_data)

    setup(function ()
      sprite_data_render = stub(sprite_data, "render")

      anim_spr.current_step = 2
      anim_spr.local_frame = 5
    end)

    teardown(function ()
      sprite_data_render:revert()
    end)

    after_each(function ()
      sprite_data_render:clear()
    end)

    it('should render the sprite from the id location, at the draw position minus pivot, with correct span when not flipping', function ()
      anim_spr:render(vector(41, 80), false, true)

      assert.spy(sprite_data_render).was_called(1)
      assert.spy(sprite_data_render).was_called_with(match.ref(spr_data2), vector(41, 80), false, true)
    end)

  end)

end)
