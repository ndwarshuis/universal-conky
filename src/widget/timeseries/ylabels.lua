local M = {}

local geom = require 'geom'
local pure = require 'pure'
local text = require 'text'
local ti = require 'text_internal'

local Y_LABEL_PAD = 5

--------------------------------------------------------------------------------
-- pure

local make_y_label_text = function(point, chars, font)
   return ti.make_text(
      point.x,
      point.y + ti.get_delta_y('center', font),
      chars
   )
end

M.make = function(point, h, n, font, y_format, scale_factor)
   local f = y_format(scale_factor)
   local to_label = function(i)
      local z = (i - 1) / (n - 1)
      return make_y_label_text(
         geom.make_point(point.x, point.y + z * h),
         f((1 - z) * scale_factor),
         font
      )
   end
   local labels = pure.map_n(to_label, n)
   local max_width = pure.compose(
      pure.curry_table(math.max),
      pure.partial(pure.map, function(l) return ti.get_width(l.chars, font) end)
   )
   return { width = max_width(labels) + Y_LABEL_PAD, table.unpack(labels) }
end

--------------------------------------------------------------------------------
-- impure

M.draw = text.draw

return M
