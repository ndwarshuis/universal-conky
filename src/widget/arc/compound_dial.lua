local M = {}

local arc = require 'arc'
local dial = require 'dial'
local pure = require 'pure'
local impure = require 'impure'
local style = require 'style'
local shape = require 'shape'
local dynamic = require 'dynamic'

--------------------------------------------------------------------------------
-- pure

M.make = function(_arc, bg_config, fg_threshold_config, inner_radius, num_dials)
   local t = bg_config.style.thickness

   local spacing = (t * num_dials - _arc.radius + inner_radius)
      / (1 - num_dials)
   assert(spacing >= 0, "ERROR: compound dial spacing is negative")
   local arcs = pure.map_n(
      function(i)
         return pure.set(
            _arc,
            "radius",
            inner_radius + t * 0.5 + (i - 1) * (spacing + t)
         )
      end,
      num_dials
   )
   local setters = pure.map(dial.make_setter, arcs, t, fg_threshold_config)

   return dynamic.compound(
      {
         shapes = pure.map(arc.make_shape, arcs, t, bg_config.pattern),
         style = bg_config.style,
      },
      setters,
      0
   )
end

--------------------------------------------------------------------------------
-- impure

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
