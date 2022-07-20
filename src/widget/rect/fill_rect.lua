local M = {}

local geom = require 'geom'
local source = require 'source'
local path = require 'path'
local style = require 'style'
local shape = require 'shape'

--------------------------------------------------------------------------------
-- pure

local make_shape = function(box, line_pattern, fill_pattern)
   local p1 = box.corner
   local p2 = geom.make_point(p1.x, p1.y + box.height)
   return shape.filled_shape(
      path.create_rect(geom.CR_DUMMY, p1.x, p1.y, box.width, box.height),
      source.linear_pattern(line_pattern, p1, p2),
      source.linear_pattern(fill_pattern, p1, p2)
   )
end

M.make = function(box, config, fill_pattern)
   return shape.styled_shape(config.style, make_shape, box, config.pattern, fill_pattern)
end

--------------------------------------------------------------------------------
-- impure

M.draw = function(obj, cr)
   style.set_closed_poly_style(obj.style, cr)
   shape.draw_filled_shape(obj.shape, cr)
end

return M
