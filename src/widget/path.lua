local M = {}

local impure = require 'impure'

local __cairo_new_path = cairo_new_path
local __cairo_line_to = cairo_line_to
local __cairo_copy_path	= cairo_copy_path
local __cairo_close_path = cairo_close_path
local __cairo_arc = cairo_arc
local __cairo_rectangle = cairo_rectangle
local __math_rad = math.rad

local line_to = function(p, cr)
   __cairo_line_to(cr, p.x, p.y)
end

local create_poly = function(cr, points)
   __cairo_new_path(cr)
   impure.each(line_to, points, cr)
end

local copy_path = function(cr)
   local path = __cairo_copy_path(cr)
   __cairo_new_path(cr) -- clear path to keep it from reappearing
   return path
end

M.create_open_poly = function(cr, points)
   create_poly(cr, points)
   return copy_path(cr)
end

M.create_closed_poly = function(cr, points)
   create_poly(cr, points)
   __cairo_close_path(cr)
   return copy_path(cr)
end

M.create_line = function(cr, p1, p2)
   return M.create_open_poly(cr, {p1, p2})
end

M.create_line_from_geom = function(cr, line)
   return M.create_line(cr, line.p1, line.p2)
end

M.create_arc = function(cr, x, y, radius, theta1, theta2)
   __cairo_new_path(cr)
   __cairo_arc(cr, x, y, radius, __math_rad(theta1), __math_rad(theta2))
   return copy_path(cr)
end

M.create_arc_from_geom = function(cr, arc)
   local c = arc.center
   return M.create_arc(cr, c.x, c.y, arc.radius, arc.theta0, arc.theta1)
end

M.create_circle = function(cr, x, y, radius)
   return M.create_arc(cr, x, y, radius, 0, 360)
end

M.create_circle_from_geom = function(cr, circle)
   local c = circle.center
   return M.create_circle(cr, c.x, c.y, circle.radius)
end

M.create_rect = function(cr, x, y, w, h)
   __cairo_new_path(cr)
   __cairo_rectangle(cr, x, y, w, h)
   return copy_path(cr)
end

return M
