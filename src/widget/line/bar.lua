local M = {}

local geom = require 'geom'
local line = require 'line'
local source = require 'source'
local pure = require 'pure'
local path = require 'path'
local shape = require 'shape'
local dynamic = require 'dynamic'

--------------------------------------------------------------------------------
-- pure

M.make_setter = function(_line, config, threshold_config)
   local p1 = _line.p1
   local p2 = _line.p2
   local _p1, _p2 = line.get_wide_pattern_points(_line, config.style.thickness, config.is_wide_pattern)

   local source_chooser = source.linear_pattern_chooser(
      threshold_config.low_pattern,
      threshold_config.high_pattern,
      threshold_config.threshold,
      _p1,
      _p2
   )
   local f = pure.memoize(
      function(percent)
         local frac = percent / 100
         local mp = geom.make_point(
            (p2.x - p1.x) * frac + p1.x,
            (p2.y - p1.y) * frac + p1.y
         )
         return shape.shape(
            path.create_line(geom.CR_DUMMY, p1, mp),
            source_chooser(percent)
         )
      end
   )
   return pure.compose(f, pure.round_percent)
end

M.make = function(p1, p2, bg_config, fg_threshold_config)
   local setter = M.make_setter(geom.make_line(p1, p2), bg_config, fg_threshold_config)
   return dynamic.single(line.make(p1, p2, bg_config), setter, 0)
end

--------------------------------------------------------------------------------
-- impure

M.set = function(obj, percent)
   obj.var = obj.setter(percent)
end

M.draw = function(obj, cr)
   line.draw(obj.static, cr)
   shape.draw_shape(obj.var, cr)
end

return M
