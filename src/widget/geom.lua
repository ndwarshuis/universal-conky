local M = {}

local err = require 'err'

-- TODO this is weird to have here
-- dummy drawing surface
local cs = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1366, 768)
M.CR_DUMMY = cairo_create(cs)
cairo_surface_destroy(cs)
cs = nil

M.make_point = function(x, y)
   return err.safe_table({x = x, y = y})
end

M.make_box_at_point = function(p, w, h)
   return err.safe_table(
      {
         corner = p,
         width = w,
         height = h,
         -- TODO these might be unnecessary
         right_x = w + p.x,
         bottom_y = h + p.y
      }
   )
end

M.make_box = function(x, y, w, h)
   return M.make_box_at_point(M.make_point(x, y), w, h)
end

M.make_arc_at_point = function(p, r, t1, t2)
   return err.safe_table(
      {
         center = p,
         radius = r,
         theta0 = t1,
         theta1 = t2,
      }
   )
end

M.make_arc = function(x, y, r, t0, t1)
   return M.make_arc_at_point(M.make_point(x, y), r, t0, t1)
end

M.make_circle_at_point = function(p, r)
   return err.safe_table({center = p, radius = r})
end

M.make_circle = function(x, y, r)
   return M.make_circle_at_point(M.make_point(x, y), r)
end

M.make_line = function(p1, p2)
   return err.safe_table({p1 = p1, p2 = p2})
end

return M
