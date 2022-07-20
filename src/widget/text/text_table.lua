local M = {}

local source = require 'source'
local rect = require 'rect'
local err = require 'err'
local ti = require 'text_internal'
local geom = require 'geom'
local pure = require 'pure'
local impure = require 'impure'
local style = require 'style'
local path = require 'path'
local shape = require 'shape'

--------------------------------------------------------------------------------
-- pure

M.config = function(border_config, sep_config, header_config, body_config, padding)
   return err.safe_table(
      {
         border_config = border_config,
         sep_config = sep_config,
         header_config = header_config,
         body_config = body_config,
         padding = padding,
      }
   )
end

M.body_config = function(font_spec, color, columns)
   return err.safe_table(
      {
         font_spec = font_spec,
         color = color,
         columns = columns,
      }
   )
end

M.column_config = function(header, format)
   return err.safe_table({header = header, format = format})
end

M.header_config = function(font_spec, color, bottom_padding)
   return err.safe_table(
      {
         font_spec = font_spec,
         color = color,
         bottom_padding = bottom_padding,
      }
   )
end

M.padding = function(l, t, r, b)
   return err.safe_table(
      {
         left = l,
         right = r,
         top = t,
         bottom = b,
      }
   )
end

-- TODO this is basically the same as that from ylabels
local make_header_text = function(x, y, chars, font)
   return ti.make_text(
      x + ti.x_align_function('center', font)(chars),
      y + ti.get_delta_y('center', font),
      chars
   )
end

-- M.make = function(box, num_rows, columns, table_config)
M.make = function(box, num_rows, table_config)
   local bc = table_config.body_config
   local hs = table_config.header_config
   local columns = bc.columns
   local header_font = ti.make_font(hs.font_spec)
   local body_font = ti.make_font(bc.font_spec)
   local p = table_config.padding
   local tbl_width = box.width - p.left - p.right
   local tbl_height = box.height - p.top - p.bottom
   local tbl_x = box.corner.x + p.left
   local tbl_y = box.corner.y + p.top
   local body_delta_y = ti.get_delta_y('center', body_font)
   local body_y = tbl_y + hs.bottom_padding + body_delta_y
   local column_width = tbl_width / #columns
   local spacing = (tbl_height - hs.bottom_padding) / (num_rows - 1)
   local headers = pure.imap(
      function (i, conf)
         local x = tbl_x + column_width * (i - 0.5)
         return make_header_text(x, tbl_y, conf.header, header_font)
      end,
      columns
   )
   local sep_paths = pure.map_n(
      function(i)
         local x = tbl_x + column_width * i
         return path.create_line(
            geom.CR_DUMMY,
            geom.make_point(x, tbl_y),
            geom.make_point(x, tbl_y + tbl_height)
         )
      end,
      #columns - 1
   )

   local get_delta_x = ti.x_align_function('center', body_font)
   local make_setter = function(i, conf)
      local column_x = tbl_x + column_width * (i - 0.5)
      return pure.memoize(
         pure.compose(
            pure.partial(ti.make_vtext, column_x, get_delta_x),
            ti.make_format_function(conf.format)
         )
      )
   end
   local setters = pure.imap(make_setter, columns)

   return {
      static = {
         header = {
            font = header_font,
            source = source.solid_color(hs.color),
            texts = headers,
         },
         body = {
            font = body_font,
            source = source.solid_color(bc.color),
            y_positions = pure.map_n(
               function(i) return body_y + spacing * (i - 1) end,
               num_rows
            ),
         },
         separators = {
            style = table_config.sep_config.style,
            shapes = {
               source = source.solid_color(table_config.sep_config.pattern),
               paths = sep_paths,
            },
         },
         border = rect.make(box, table_config.border_config),
      },
      setters = setters,
      var = pure.map_n(
         function(c) return pure.rep(num_rows, setters[c]("NULL")) end,
         #columns
      )
   }
end

--------------------------------------------------------------------------------
-- impure

M.set = function(obj, col_num, row_num, text)
   obj.var[col_num][row_num] = obj.setters[col_num](text)
end

M.draw_static = function(obj, cr)
   local static = obj.static
   local seps = static.separators
   local header = static.header

   rect.draw(static.border, cr)

   style.set_line_style(seps.style, cr)
   shape.draw_shapes(seps.shapes, cr)

   ti.set_font_spec(cr, header.font, header.source)
   impure.each(ti.draw_text, header.texts, cr)
end

local draw_column = function(rows, ys, cr)
   impure.each2(ti.draw_vtext_at_y, rows, ys, cr)
end

M.draw_dynamic = function(obj, cr)
   local body = obj.static.body
   ti.set_font_spec(cr, body.font, body.source)
   impure.each(draw_column, obj.var, body.y_positions, cr)
end

return M
