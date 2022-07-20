local M = {}

local source = require 'source'
local ti = require 'text_internal'
local pure = require 'pure'
local impure = require 'impure'
local dynamic = require 'dynamic'

--------------------------------------------------------------------------------
-- pure

M.make = function(point, texts, config, format, spacing)
   local font = ti.make_font(config.font_spec)
   local get_delta_x = ti.x_align_function(config.x_align, font)
   local format_chars = ti.make_format_function(format)
   local delta_y = ti.get_delta_y(config.y_align, font)
   local ys = pure.map_n(
      function(i) return point.y + spacing * (i - 1) + delta_y end,
      #texts
   )
   local make_vtext = pure.partial(ti.make_vtext, point.x, get_delta_x)
   local setter = pure.memoize(pure.compose(make_vtext, format_chars))
   local static = {
      y_positions = ys,
      font = font,
      source = source.solid_color(config.color),
   }
   return dynamic.multi(static, setter, texts)
end

M.make_n = function(point, num_rows, config, format, spacing, init_text)
   local dummy = pure.rep(num_rows, init_text or ti.NULL_TEXT_STRING)
   return M.make(point, dummy, config, format, spacing)
end

--------------------------------------------------------------------------------
-- impure

M.set = function(obj, row_num, text)
   obj.var[row_num] = obj.setter(text)
end

M.draw = function(obj, cr)
   local static = obj.static
   ti.set_font_spec(cr, static.font, static.source)
   impure.each2(ti.draw_vtext_at_y, obj.var, static.y_positions, cr)
end

return M
