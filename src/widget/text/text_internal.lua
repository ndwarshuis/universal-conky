local M = {}

local err = require 'err'
local geom = require 'geom'

local __string_sub = string.sub
local __cairo_toy_font_face_create = cairo_toy_font_face_create
local __cairo_font_extents = cairo_font_extents
local __cairo_set_font_face = cairo_set_font_face
local __cairo_set_font_size = cairo_set_font_size
local __cairo_text_extents = cairo_text_extents
local __cairo_set_source = cairo_set_source
local __cairo_move_to = cairo_move_to
local __cairo_show_text = cairo_show_text

M.NULL_TEXT_STRING = '<null>'

--------------------------------------------------------------------------------
-- pure

local trim_to_length = function(text, len)
   if #text > len then
      return __string_sub(text, 1, len)..'...'
   else
      return text
   end
end

M.make_format_function = function(format)
   if type(format) == "function" then
      return format
   elseif type(format) == "number" and format > 0 then
      return function(_text) return trim_to_length(_text, format) end
   elseif type(format) == "string" then
      return function(_text) return string.format(format, _text) end
   elseif format == nil or format == false then
      return function(_text) return _text end
   else
      local msg = "format must be a printf string, positive int, or function: got "
      local t = type(format)
      if t == "number" or t == "string" then
         msg = msg..format
      else
         msg = msg.."a "..t
      end
      err.assert_trace(nil, msg)
   end
end

M.make_font_face = function(font_spec)
   return __cairo_toy_font_face_create(
      font_spec.family,
      font_spec.slant,
      font_spec.weight
   )
end

M.make_font = function(font_spec)
   return {
      face = M.make_font_face(font_spec),
      size = font_spec.size,
   }
end

M.make_text = function(x, y, chars)
   return err.safe_table({x = x, y = y, chars = chars})
end

M.make_htext = function(y, delta_x, chars)
   return err.safe_table({y = y, delta_x = delta_x, chars = chars})
end

M.make_vtext = function(x, delta_x_fun, chars)
   return err.safe_table({x = x + delta_x_fun(chars), chars = chars})
end

--------------------------------------------------------------------------------
-- impure

local dummy_text_extents = cairo_text_extents_t:create()
tolua.takeownership(dummy_text_extents)

local dummy_font_extents = cairo_font_extents_t:create()
tolua.takeownership(dummy_font_extents)

local set_font_extents = function(font)
   __cairo_set_font_size(geom.CR_DUMMY, font.size)
   __cairo_set_font_face(geom.CR_DUMMY, font.face)
   __cairo_font_extents(geom.CR_DUMMY, dummy_font_extents)
   return dummy_font_extents
end

local set_text_extents = function(chars, font)
   __cairo_set_font_size(geom.CR_DUMMY, font.size)
   __cairo_set_font_face(geom.CR_DUMMY, font.face)
   __cairo_text_extents(geom.CR_DUMMY, chars, dummy_text_extents)
   return dummy_text_extents
end

M.get_width = function(chars, font)
   return set_text_extents(chars, font).width
end

M.font_height = function(font)
   return set_font_extents(font).height
end

M.x_align_function = function(x_align, font)
   if x_align == 'left' then
      return function(text)
         local te = set_text_extents(text, font)
         return -te.x_bearing
      end
   elseif x_align == 'center' then
      return function(text)
         local te = set_text_extents(text, font)
         return -(te.x_bearing + te.width * 0.5)
      end
   elseif x_align == 'right' then
      return function(text)
         local te = set_text_extents(text, font)
         return -(te.x_bearing + te.width)
      end
   else
      err.assert_trace(nil, "invalid x_align")
   end
end

M.get_delta_y = function(y_align, font)
   local fe = set_font_extents(font)
   if y_align == 'bottom' then
      return -fe.descent
   elseif y_align == 'top'	then
      return fe.height
   elseif y_align == 'center' then
      return 0.92 * fe.height * 0.5 - fe.descent
   else
      err.assert_trace(nil, "invalid y_align")
   end
end

M.set_font_spec = function(cr, font, source)
   __cairo_set_font_face(cr, font.face)
   __cairo_set_font_size(cr, font.size)
   __cairo_set_source(cr, source)
end

local draw_text_at = function(cr, x, y, chars)
   __cairo_move_to(cr, x, y)
   __cairo_show_text(cr, chars)
end

M.draw_text = function(obj, cr)
   draw_text_at(cr, obj.x, obj.y, obj.chars)
end

M.draw_htext_at_x = function(obj, x, cr)
   draw_text_at(cr, obj.delta_x + x, obj.y, obj.chars)
end

M.draw_vtext_at_y = function(obj, y, cr)
   draw_text_at(cr, obj.x, y, obj.chars)
end

return M
