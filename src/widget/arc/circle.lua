local M = {}

local geom = require 'geom'
local err = require 'err'
local source = require 'source'
local style = require 'style'
local path = require 'path'
local shape = require 'shape'

--------------------------------------------------------------------------------
-- pure

M.make_pattern_radii = function(r, t)
   return r - t * 0.5, r + t * 0.5
end

M.make_source = function(pattern, center, radius, thickness)
   local r1, r2 = M.make_pattern_radii(radius, thickness)
   return source.radial_pattern(pattern, center, r1, r2)
end

M.make_shape = function(circle, thickness, pattern)
   return shape.shape(
      path.create_circle_from_geom(geom.CR_DUMMY, circle),
      M.make_source(pattern, circle.center, circle.radius, thickness)
   )
end

M._make = function(_geom, config, make_shape_fun)
   return shape.styled_shape(
      config.style,
      make_shape_fun,
      _geom,
      config.style.thickness,
      config.pattern
   )
end

M.make = function(circle, config)
   return M._make(circle, config, M.make_shape)
end

M.config = function(_style, pattern)
   return err.safe_table({style = _style, pattern = pattern})
end

--------------------------------------------------------------------------------
-- impure

M.draw = function(obj, cr)
   style.set_line_style(obj.style, cr)
   shape.draw_shape(obj.shape, cr)
end

return M
