local M = {}

local geom = require 'geom'
local bar = require 'bar'
local dynamic = require 'dynamic'
local line = require 'line'
local style = require 'style'
local pure = require 'pure'
local impure = require 'impure'
local shape = require 'shape'

--------------------------------------------------------------------------------
-- pure

-- TODO make this handle vertical bars
M.make = function(point, length, bg_config, fg_threshold_config, spacing,
                   num_bars, is_vertical)
   local lines = pure.map_n(
      function(i)
         local y = (i - 1) * spacing + point.y
         local p1 = geom.make_point(point.x, y)
         local p2 = geom.make_point(point.x + length, y)
         return geom.make_line(p1, p2)
      end,
      num_bars
   )

   local setters = pure.map(
      bar.make_setter,
      lines,
      bg_config,
      fg_threshold_config
   )

   local bs = bg_config.style
   local static = {
      shapes = pure.map(
         line.make_shape,
         lines,
         bg_config.pattern,
         bs.thickness,
         bg_config.is_wide_pattern
      ),
      style = bs,
   }
   return dynamic.compound(static, setters, 0)
end

--------------------------------------------------------------------------------
-- pure

M.set = function(obj, i, percent)
   obj.var[i] = obj.setters[i](percent)
end

M.draw_static = function(obj, cr)
   local static = obj.static
   style.set_line_style(static.style, cr)
   impure.each(shape.draw_shape, static.shapes, cr)
end

M.draw_dynamic = function(obj, cr)
   style.set_line_style(obj.static.style, cr)
   impure.each(shape.draw_shape, obj.var, cr)
end

return M
