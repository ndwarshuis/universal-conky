local M = {}

local err = require 'err'
local pure = require 'pure'
local source = require 'source'
local ti = require 'text_internal'
local dynamic = require 'dynamic'

local __tonumber = tonumber

--------------------------------------------------------------------------------
-- pure

local _make = function(point, chars, config, threshold_config, format)
   local font = ti.make_font(config.font_spec)
   local get_delta_x = ti.x_align_function(config.x_align, font)
   local make_vtext = pure.partial(ti.make_vtext, point.x, get_delta_x)
   local format_chars = ti.make_format_function(format)
   local source_chooser = source.solid_color_chooser(
      config.color,
      threshold_config.high_color,
      threshold_config.threshold
   )
   local _setter = pure.memoize(
      function(cs)
         local _cs = cs or 0
         return {
            text = make_vtext(format_chars(_cs)),
            source = source_chooser(_cs),
         }
      end
   )
   local f = threshold_config.pre_function
   local setter
   if f then
      setter = function(x) return _setter(f(x)) end
   else
      setter = _setter
   end
   local static = {
      y = point.y + ti.get_delta_y(config.y_align, font),
      font = font,
   }
   return dynamic.single(static, setter, chars or 0)
end

M.config = function(high_color, threshold, pre_function)
   return err.safe_table(
      {
         high_color = high_color,
         threshold = threshold,
         pre_function = pre_function,
      }
   )
end

M.make_formatted = function(point, text, config, format, threshold_config)
   return _make(point, text, config, threshold_config, format)
end

M.make_plain = function(point, text, config, threshold_config)
   return M.make_formatted(point, text, config, threshold_config, nil)
end

--------------------------------------------------------------------------------
-- impure

M.set = function(obj, x)
   obj.var = obj.setter(x)
end

M.draw = function(obj, cr)
   local st = obj.static
   local var = obj.var
   ti.set_font_spec(cr, st.font, var.source)
   ti.draw_vtext_at_y(var.text, st.y, cr)
end

return M
