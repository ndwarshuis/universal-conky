local M = {}

local ti = require 'text_internal'
local pure = require 'pure'

--------------------------------------------------------------------------------
-- pure

local make_x_label_text = function(y, chars, font)
   return ti.make_htext(
      y + ti.get_delta_y('bottom', font),
      ti.x_align_function('center', font)(chars),
      chars
   )
end

local X_LABEL_PAD = 8

M.get_x_axis_height = function(font)
   return ti.font_height(font) + X_LABEL_PAD
end

M.make = function(y, n, format_fun, font)
   local f = function(i)
      return make_x_label_text(y, format_fun((i - 1) / (n - 1)), font)
   end
   return pure.map_n(f, n)
end

M.get_x_label_positions = function(right_x, w, x_labels)
   local n = #x_labels
   local f = function(i)
      return right_x - w * (1 - (i - 1) / (n - 1))
   end
   return pure.map_n(f, n)
end

--------------------------------------------------------------------------------
-- impure

M.draw = function(obj, cr, positions)
   ti.set_font_spec(cr, obj.font, obj.source)
   pure.each2(ti.draw_htext_at, obj.labels, positions, cr)
end

return M
