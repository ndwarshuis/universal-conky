local M = {}

local impure = require 'impure'
local err = require 'err'

local __cairo_append_path = cairo_append_path
local __cairo_fill_preserve = cairo_fill_preserve
local __cairo_set_source = cairo_set_source
local __cairo_stroke = cairo_stroke

--------------------------------------------------------------------------------
-- pure

M.shape = function(path, source)
   return {path = path, source = source}
end

M.filled_shape = function(path, line_source, fill_source)
   return {path = path, line_source = line_source, fill_source = fill_source}
end

M.shapes = function(paths, source)
   return {paths = paths, source = source}
end

M.styled_shape = function(style, make_shape_fun, geom, ...)
   return err.safe_table(
      {
         style = style,
         shape = make_shape_fun(geom, ...),
      }
   )
end

--------------------------------------------------------------------------------
-- impure

M.draw_path_with_source = function(path, cr, source)
   __cairo_append_path(cr, path)
   __cairo_set_source(cr, source)
   __cairo_stroke(cr)
end

M.draw_shape = function(shape, cr)
   M.draw_path_with_source(shape.path, cr, shape.source)
end

M.draw_filled_shape = function(shape, cr)
   __cairo_append_path(cr, shape.path)
   __cairo_set_source(cr, shape.fill_source)
   __cairo_fill_preserve(cr)
   __cairo_set_source(cr, shape.line_source)
   __cairo_stroke(cr)
end

local append_path = function(p, cr)
   __cairo_append_path(cr, p)
end

M.draw_paths_with_source = function(paths, cr, source)
   impure.each(append_path, paths, cr)
   __cairo_set_source(cr, source)
   __cairo_stroke(cr)
end

M.draw_shapes = function(shapes, cr)
   M.draw_paths_with_source(shapes.paths, cr, shapes.source)
end

return M
