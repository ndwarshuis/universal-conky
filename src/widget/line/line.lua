local M = {}

local geom = require 'geom'
local err = require 'err'
local source = require 'source'
local style = require 'style'
local path = require 'path'
local shape = require 'shape'

local __math_atan2	= math.atan2
local __math_sin	= math.sin
local __math_cos	= math.cos

--------------------------------------------------------------------------------
-- pure

M.config = function(_style, pattern, is_wide_pattern)
   return err.safe_table(
      {
         style = _style,
         pattern = pattern,
         is_wide_pattern = is_wide_pattern or false,
      }
   )
end

M.get_wide_pattern_points = function(line, thickness, is_wide)
   local p1 = line.p1
   local p2 = line.p2
   if is_wide then
      local theta = __math_atan2(p2.y - p1.y, p2.x - p1.x)
      local delta_x = 0.5 * thickness * __math_sin(theta) --and yes, these are actually flipped
      local delta_y = 0.5 * thickness * __math_cos(theta)
      local _p1 = geom.make_point(p1.x + delta_x, p1.y + delta_y)
      local _p2 = geom.make_point(p1.x - delta_x, p1.y - delta_y)
      return _p1, _p2
   else
      return p1, p2
   end
end

M.make_source = function(line, thickness, pattern, is_wide)
   local p1, p2 = M.get_wide_pattern_points(line, thickness, is_wide)
   return source.linear_pattern(pattern, p1, p2)
end

M.make_shape = function(line, pattern, thickness, is_wide)
   return shape.shape(
      path.create_line_from_geom(geom.CR_DUMMY, line),
      M.make_source(line, thickness, pattern, is_wide)
   )
end

M.make = function(line, config)
   local _style = config.style
   return shape.styled_shape(
      _style,
      M.make_shape,
      line,
      config.pattern,
      _style.thickness,
      config.is_wide_pattern
   )
end

--------------------------------------------------------------------------------
-- impure

M.draw = function(obj, cr)
   style.set_line_style(obj.style, cr)
   shape.draw_shape(obj.shape, cr)
end

return M
