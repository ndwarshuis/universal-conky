local M = {}

local err = require 'err'
local dynamic = require 'dynamic'
local ti = require 'text_internal'
local source = require 'source'
local pure = require 'pure'

--------------------------------------------------------------------------------
-- pure

M.config = function(font_spec, color, x_align, y_align)
   return err.safe_table(
      {
         font_spec = font_spec,
         color = color,
         x_align = x_align,
         y_align = y_align,
      }
   )
end

local _make = function(point, chars, config, format)
   local font = ti.make_font(config.font_spec)
   local get_delta_x = ti.x_align_function(config.x_align, font)
   local format_chars = ti.make_format_function(format)
   local make_vtext = pure.partial(ti.make_vtext, point.x, get_delta_x)
   local setter = pure.memoize(pure.compose(make_vtext, format_chars))
   local static = {
      y = point.y + ti.get_delta_y(config.y_align, font),
      font = font,
      source = source.solid_color(config.color),
   }
   return dynamic.single(static, setter, chars)
end

M.make_formatted = function(point, text, config, format)
   return _make(point, (text or ti.NULL_TEXT_STRING), config, format)
end

M.make_plain = function(point, text, config)
   return M.make_formatted(point, text, config, nil)
end

--------------------------------------------------------------------------------
-- impure

M.set = function(obj, text)
   obj.var = obj.setter(text)
end

M.draw = function(obj, cr)
   local st = obj.static
   ti.set_font_spec(cr, st.font, st.source)
   ti.draw_vtext_at_y(obj.var, st.y, cr)
end

return M
