local M = {}

local source = require 'source'
local geom = require 'geom'
local pure = require 'pure'
local style = require 'style'
local path = require 'path'
local shape = require 'shape'

local __cairo_move_to = cairo_move_to
local __cairo_line_to = cairo_line_to
local __cairo_set_source = cairo_set_source
local __cairo_fill_preserve = cairo_fill_preserve
local __cairo_stroke = cairo_stroke
local __table_insert = table.insert

local DATA_STYLE = style.open_poly(1, CAIRO_LINE_CAP_BUTT, CAIRO_LINE_JOIN_MITER)
local GRID_CONFIG = style.line(1, CAIRO_LINE_CAP_BUTT)
local OUTLINE_STYLE = style.open_poly(2, CAIRO_LINE_CAP_BUTT, CAIRO_LINE_JOIN_MITER)

--------------------------------------------------------------------------------
-- pure

local make_x_grid = function(cr, x, y, w, h, n)
   local y1 = y - 0.5
   local y2 = y1 + h + 0.5
   local grid_line_spacing = w / n
   local f = function(i)
      local x1 = x - w + grid_line_spacing * i - 0.5
      local p1 = geom.make_point(x1, y1)
      local p2 = geom.make_point(x1, y2)
      return path.create_line(cr, p1, p2)
   end
   return pure.map_n(f, n)
end

local make_y_grid = function(cr, x, y, w, h, n)
   local x1 = x
   local x2 = x - w
   local grid_line_spacing = h / n
   local f = function(i)
      local y1 = y + (i - 1) * grid_line_spacing - 0.5
      local p1 = geom.make_point(x1, y1)
      local p2 = geom.make_point(x2, y1)
      return path.create_line(cr, p1, p2)
   end
   return pure.map_n(f, n)
end

local make_grid_paths = function(cr, x, y, w, h, nx, ny)
   return {
      x = make_x_grid(cr, x, y, w, h, nx),
      y = make_y_grid(cr, x, y, w, h, ny),
   }
end

local make_outline = function(cr, right_x, y, w, h)
	local x1 = right_x - w
	local y1 = y - 0.5
	local x2 = right_x + 0.5
	local y2 = y + h + 1.0
	local p1 = geom.make_point(x1, y1)
	local p2 = geom.make_point(x1, y2)
	local p3 = geom.make_point(x2, y2)
	return path.create_open_poly(cr, {p1, p2, p3})
end

M.make_plotarea_paths = function(cr, right_x, y, w, h, num_x, num_y)
   return {
      grid = make_grid_paths(cr, right_x, y, w, h, num_x, num_y),
      outline = make_outline(cr, right_x, y, w, h),
   }
end

M.make_sources = function(x, y, width, config)
   local p1 = geom.make_point(x, y)
   local p2 = geom.make_point(x + width, y)
   return {
      grid = source.solid_color(config.grid_config.pattern),
      outline = source.solid_color(config.outline_color),
      series = {
         line = source.linear_pattern(config.data_line_pattern, p1, p2),
         fill = source.linear_pattern(config.data_fill_pattern, p1, p2),
      }
   }
end

--------------------------------------------------------------------------------
-- impure

M.insert_data_point = function(y, h, n, series, value)
   __table_insert(series, 1, y + h * (1 - value))
   if #series == n + 2 then
      series[#series] = nil
   end
   return series
end

M.draw_grid = function(cr, grid, _source)
   style.set_line_style(GRID_CONFIG, cr)
   -- TODO this sets the same source twice and strokes twice
   shape.draw_paths_with_source(grid.x, cr, _source)
   shape.draw_paths_with_source(grid.y, cr, _source)
end

M.draw_outline = function(cr, _path, _source)
   style.set_open_poly_style(OUTLINE_STYLE, cr)
   shape.draw_path_with_source(_path, cr, _source)
end

M.draw_series = function(cr, right_x, bottom_y, dx, series, sources)
   style.set_open_poly_style(DATA_STYLE, cr)
   local n = #series

   -- TODO this accounts for up to 20% of the execution time once the series
   -- reaches its max length
   __cairo_move_to(cr, right_x, series[1])

   for j = 2, n do
      __cairo_line_to(cr, right_x - (j - 1) * dx, series[j])
   end

   __cairo_line_to(cr, right_x - (n - 1) * dx, bottom_y)
   __cairo_line_to(cr, right_x, bottom_y)
   __cairo_set_source(cr, sources.fill)
   __cairo_fill_preserve(cr)

   __cairo_set_source(cr, sources.line)
   __cairo_stroke(cr)
end

return M
