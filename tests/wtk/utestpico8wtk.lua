require("bustedhelper")
local wtk = require("engine/wtk/pico8wtk")

describe('wtk', function ()

  describe('vertical_layout', function ()

    describe('new', function ()

      it('should create a new vertical layout', function ()
        local vl = wtk.vertical_layout.new(10, 3)
        assert.is_not_nil(vl)
        assert.are_equal(10, vl.w)
        assert.are_equal(0, vl.h)
        assert.are_equal(3, vl.c)
      end)

    end)

    describe('add_child', function ()

      local vl

      before_each(function ()
        vl = wtk.vertical_layout.new(10, 3)
      end)

      describe('(when no children)', function ()

        it('should create a new vertical layout', function ()
          local label = wtk.label.new("hello", 4)  -- width: 19, height: 5
          vl:add_child(label)
          assert.is_not_nil(vl)
          assert.are_equal(19, vl.w)
          assert.are_equal(6, vl.h)
          assert.are_equal(1, #vl.children)
          assert.are_equal(label, vl.children[1])
          assert.are_same({0, 0}, {vl.children[1].x, vl.children[1].y})
        end)

      end)

      describe('(when some children)', function ()

        before_each(function ()
          local label = wtk.label.new("hello", 4)  -- width: 19, height: 5
          vl:add_child(label)
        end)

        it('should create a new vertical layout', function ()
          local label2 = wtk.label.new("hello again", 4)  -- width: 43, height: 5
          vl:add_child(label2)
          assert.is_not_nil(vl)
          assert.are_equal(43, vl.w)
          assert.are_equal(12, vl.h)
          assert.are_equal(2, #vl.children)
          assert.are_equal(label2, vl.children[2])
          assert.are_same({0, 6}, {vl.children[2].x, vl.children[2].y})
        end)

      end)

    end)

    describe('remove_child', function ()

      local vl
      local widget_remove_child_stub

      setup(function ()
        widget_remove_child_stub = stub(wtk.widget, "remove_child")  -- native print
      end)

      teardown(function ()
        widget_remove_child_stub:revert()
      end)

      before_each(function ()
        vl = wtk.vertical_layout.new(10, 3, 2)  -- padding of 2
      end)

      after_each(function ()
        widget_remove_child_stub:clear()
      end)

      it('should call base method implementation', function ()
        local some_icon = wtk.icon.new(2, 3)
        vl:remove_child(some_icon)
        assert.spy(widget_remove_child_stub).was_called(1)
        assert.spy(widget_remove_child_stub).was_called_with(vl, some_icon)
      end)

      it('should do nothing when trying to remove a non-child element (except unsetting its parent due to base method implementation)', function ()
        local icon_not_here = wtk.icon.new(2, 3)
        assert.has_no_errors(function ()
          vl:remove_child(icon_not_here)
        end)
      end)

      describe('(when some children)', function ()

        local label1, label2, label3, icon1, icon2

        before_each(function ()
          icon1 = wtk.icon.new(2, 3)  -- height: 8
          icon2 = wtk.icon.new(3, 4)  -- height: 8
          label1 = wtk.label.new("hello1", 4)  -- height: 5
          label2 = wtk.label.new("hello2", 4)  -- height: 5
          vl:add_child(icon1)   -- y: 0
          vl:add_child(icon2)   -- y: 9
          vl:add_child(label1)  -- y: 15
          vl:add_child(label2)  -- y: 21
        end)

        it('should move all children below that child up', function ()
          assert.are_same(
            {0,              10,       20,       27},
            {icon1.y, icon2.y, label1.y, label2.y})
          vl:remove_child(icon2)
          assert.are_same(
            {0,              10,       17},
            {icon1.y, label1.y, label2.y})
        end)

      end)

    end)

    describe('draw', function ()

      local rectfill_stub

      setup(function ()
        rectfill_stub = stub(_G, "rectfill")
      end)

      teardown(function ()
        rectfill_stub:revert()
      end)

      it('should call rectfill', function ()
        local vl = wtk.vertical_layout.new(10, 3)
        vl:draw(5, 8)
        assert.spy(rectfill_stub).was_called()
        assert.spy(rectfill_stub).was_called_with(5, 8, 14, 7, 3)
      end)

    end)

  end)

end)
