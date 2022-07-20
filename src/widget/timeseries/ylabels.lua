local M = {}

local geom = require 'geom'
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


-- TODO this function smells funny
M.make = function(point, h, n, font, y_format, scale_factor)
   local y_labels = {width = 0}
   local f = y_format(scale_factor)
   for i = 1, n do
      local z = (i - 1) / (n - 1)
      local l = make_y_label_text(
         geom.make_point(point.x, point.y + z * h),
         f((1 - z) * scale_factor),
         font
      )
      local w = ti.get_width(l.chars, font)
      if w > y_labels.width then
         y_labels.width = w
      end
      y_labels[i] = l
   end
   y_labels.width = y_labels.width + Y_LABEL_PAD
   return y_labels
end

--------------------------------------------------------------------------------
-- impure

M.draw = text.draw

return M
