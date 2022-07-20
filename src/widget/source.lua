local M = {}

local err		= require 'err'

local __cairo_pattern_create_rgba = cairo_pattern_create_rgba
local __cairo_pattern_create_radial	= cairo_pattern_create_radial
local __cairo_pattern_create_linear	= cairo_pattern_create_linear
local __cairo_pattern_add_color_stop_rgba = cairo_pattern_add_color_stop_rgba

M.threshold_config = function(low_pattern, high_pattern, threshold)
   return err.safe_table(
      {
         low_pattern = low_pattern,
         high_pattern = high_pattern,
         threshold = threshold,
      }
   )
end

local set_color_stops = function(pattern, colorstops)
   for stop, color in pairs(colorstops) do
      __cairo_pattern_add_color_stop_rgba(
         pattern,
         stop,
         color.r,
         color.g,
         color.b,
         color.a
      )
   end
end

local _solid_color = function(color)
   return __cairo_pattern_create_rgba(color.r, color.g, color.b, color.a)
end

local _linear_gradient = function(gradient, p1, p2)
   local pattern = __cairo_pattern_create_linear(p1.x, p1.y, p2.x, p2.y)
   set_color_stops(pattern, gradient)
   return pattern
end

local _radial_gradient = function(gradient, p, r1, r2)
   local pattern = __cairo_pattern_create_radial(p.x, p.y, r1, p.x, p.y, r2)
   set_color_stops(pattern, gradient)
   return pattern
end

local _is_gradient = function(spec)
   return err.get_type(spec) == "gradient"
end

local _create_critical_function = function(limit)
   if limit then
      return function(n) return (n > limit) end
   else
      return function(_) return nil end
   end
end

M.solid_color = function(spec)
   err.check_type(spec, "color")
   return _solid_color(spec)
end

M.linear_pattern = function(spec, p1, p2)
   if _is_gradient(spec) then
      return _linear_gradient(spec, p1, p2)
   else
      return _solid_color(spec)
   end
end

M.radial_pattern = function(spec, p, r1, r2)
   if _is_gradient(spec) then
      return _radial_gradient(spec, p, r1, r2)
   else
      return _solid_color(spec)
   end
end

local source_chooser = function(low_source, high_source, limit)
   local f = _create_critical_function(limit)
   return function(value)
      if f(value) then
         return high_source
      else
         return low_source
      end
   end
end

M.solid_color_chooser = function(low_color, high_color, limit)
   return source_chooser(
      M.solid_color(low_color),
      M.solid_color(high_color),
      limit
   )
end

M.linear_pattern_chooser = function(low_pattern, high_pattern, limit, p1, p2)
   return source_chooser(
      M.linear_pattern(low_pattern, p1, p2),
      M.linear_pattern(high_pattern, p1, p2),
      limit
   )
end

M.radial_pattern_chooser = function(low_pattern, high_pattern, limit, p, r1, r2)
   return source_chooser(
      M.radial_pattern(low_pattern, p, r1, r2),
      M.radial_pattern(high_pattern, p, r1, r2),
      limit
   )
end

return M
