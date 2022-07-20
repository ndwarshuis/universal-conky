local M = {}

local geom = require 'geom'
local err = require 'err'
local source = require 'source'
local style = require 'style'
local path = require 'path'
local shape = require 'shape'

M.config = function(closed_poly_style, pattern)
   return err.safe_table(
      {
         style = closed_poly_style,
         pattern = pattern,
      }
   )
end

local make_shape = function(box, pattern)
   local p = box.corner
   return shape.shape(
      path.create_rect(geom.CR_DUMMY, p.x, p.y, box.width, box.height),
      source.linear_pattern(
         pattern,
         p,
         geom.make_point(p.x, p.y + box.height)
      )
   )
end

M.make = function(box, config)
   return shape.styled_shape(config.style, make_shape, box, config.pattern)
end

M.draw = function(obj, cr)
   style.set_closed_poly_style(obj.style, cr)
   shape.draw_shape(obj.shape, cr)
end

return M
