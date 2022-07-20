local M = {}

local err = require 'err'

local __cairo_set_line_width = cairo_set_line_width
local __cairo_set_line_cap = cairo_set_line_cap
local __cairo_set_line_join = cairo_set_line_join

--------------------------------------------------------------------------------
-- pure

-- circle: a closed path with no corners
M.circle = function(thickness)
   return err.safe_table({thickness = thickness})
end

-- line: an open path with no corners
M.line = function(thickness, cap)
   return err.safe_table({thickness = thickness, cap = cap})
end

-- open poly: an open path with corners
M.open_poly = function(thickness, cap, join)
   return err.safe_table({thickness = thickness, cap = cap, join = join})
end

-- closed poly: an closed path with corners
M.closed_poly = function(thickness, join)
   return err.safe_table({thickness = thickness, join = join})
end

--------------------------------------------------------------------------------
-- impure

M.set_circle_style = function(style, cr)
   __cairo_set_line_width(cr, style.thickness)
end

M.set_line_style = function(style, cr)
   __cairo_set_line_width(cr, style.thickness)
   __cairo_set_line_cap(cr, style.cap)
end

M.set_open_poly_style = function(style, cr)
   __cairo_set_line_width(cr, style.thickness)
   __cairo_set_line_cap(cr, style.cap)
   __cairo_set_line_join(cr, style.join)
end

M.set_closed_poly_style = function(style, cr)
   __cairo_set_line_width(cr, style.thickness)
   __cairo_set_line_join(cr, style.join)
end

return M
