local M = {}

local geom = require 'geom'
local pure = require 'pure'
local arc = require 'arc'
local circle = require 'circle'
local source = require 'source'
local style = require 'style'
local path = require 'path'
local shape = require 'shape'
local dynamic = require 'dynamic'

--------------------------------------------------------------------------------
-- pure

M.make_setter = function(_arc, thickness, threshold_config)
   local c = _arc.center
   local r = _arc.radius
   local t1 = _arc.theta0
   local t2 = _arc.theta1
   local r1, r2 = circle.make_pattern_radii(r, thickness)
   local source_chooser = source.radial_pattern_chooser(
      threshold_config.low_pattern,
      threshold_config.high_pattern,
      threshold_config.threshold,
      c,
      r1,
      r2
   )
   local f = pure.memoize(
      function(percent)
         return shape.shape(
            path.create_arc(
               geom.CR_DUMMY,
               c.x,
               c.y,
               r,
               t1,
               t1 + (percent / 100) * (t2 - t1)
            ),
            source_chooser(percent)
         )
      end
   )
   return function(percent)
      return f(pure.round_percent(percent))
   end
end

M.make = function(_arc, bg_config, fg_threshold_config)
   local setter = M.make_setter(
      _arc,
      bg_config.style.thickness,
      fg_threshold_config
   )
   return dynamic.single(arc.make(_arc, bg_config), setter, 0)
end

--------------------------------------------------------------------------------
-- impure

M.set = function(obj, percent)
   obj.var = obj.setter(percent)
end

M.draw_static = function(obj, cr)
   arc.draw(obj.static, cr)
end

M.draw_dynamic = function(obj, cr)
   style.set_line_style(obj.static.style, cr)
   shape.draw_shape(obj.var, cr)
end

return M
