local M = {}

local err = require 'err'
local xlabels = require 'xlabels'
local ylabels = require 'ylabels'
local source = require 'source'
local ti = require 'text_internal'
local tsi = require 'timeseries_internal'
local geom = require 'geom'
local impure = require 'impure'

local __string_format = string.format

--------------------------------------------------------------------------------
-- pure

-- TODO group these better
M.config = function(num_points, outline_color, data_line_pattern,
                   data_fill_pattern, grid_config)
   return err.safe_table(
      {
         num_points = num_points,
         outline_color = outline_color,
         data_line_pattern = data_line_pattern,
         data_fill_pattern = data_fill_pattern,
         grid_config = grid_config,
      }
   )
end

M.grid_config = function(num_x, num_y, color)
   return err.safe_table(
      {
         num_x = num_x,
         num_y = num_y,
         pattern = color,
      }
   )
end

M.label_config = function(color, font_spec, y_format)
   return err.safe_table(
      {
         color = color,
         font_spec = font_spec,
         y_format = y_format
      }
   )
end

M.make_format_timecourse_x_label = function(n, freq)
   return function(x) return __string_format('%.0fs', (1 - x) * n / freq) end
end

M.make = function(box, samplefreq, config, label_config)
   local x = box.corner.x
   local y = box.corner.y
   local w = box.width
   local h = box.height
   local right_x = x + w
   local bottom_y = y + h
   local gconf = config.grid_config
   local label_font = ti.make_font(label_config.font_spec)

   local plot_height = box.height - xlabels.get_x_axis_height(label_font)
   local y_labels = ylabels.make(
      box.corner,
      plot_height,
      gconf.num_y + 1,
      label_font,
      label_config.y_format,
      1
   )

   local plot_width = w - y_labels.width

   local x_label_format = M.make_format_timecourse_x_label(config.num_points, samplefreq)

   local x_labels = xlabels.make(bottom_y, gconf.num_x + 1, x_label_format, label_font)

   local setter = function(value, series)
      return tsi.insert_data_point(y, plot_height, config.num_points, series, value)
   end

   return err.safe_table(
      {
         static = {
            box = box,
            axis = {
               font = label_font,
               source = source.solid_color(label_config.color),
               x = {
                  label_data = x_labels,
                  positions = xlabels.get_x_label_positions(right_x, plot_width, x_labels),
               },
               y = {
                  labels = y_labels,
               }
            },
            plotarea = {
               dx = plot_width / config.num_points,
               bottom_y = y + plot_height,
               paths = tsi.make_plotarea_paths(
                  geom.CR_DUMMY,
                  right_x,
                  y,
                  plot_width,
                  plot_height,
                  gconf.num_x,
                  gconf.num_y
               ),
               sources = tsi.make_sources(x, y, w, config),
            },
         },
         setter = setter,
         var = setter(0, {}),
      }
   )
end

--------------------------------------------------------------------------------
-- impure

M.update = function(obj, value)
   obj.var = obj.setter(value, obj.var)
end

M.draw_labels = function(cr, font, _source, x_positions, x_label_data, y_labels)
   ti.set_font_spec(cr, font, _source)
   impure.each2(ti.draw_htext_at_x, x_label_data, x_positions, cr)
   impure.each(ti.draw_text, y_labels, cr)
end


M.draw_static = function(obj, cr)
   local static = obj.static
   local axis = static.axis
   local ax = axis.x
   local plotarea = static.plotarea
   local paths = plotarea.paths
   local sources = plotarea.sources
   M.draw_labels(
      cr,
      axis.font,
      axis.source,
      ax.positions,
      ax.label_data,
      axis.y.labels
   )
   tsi.draw_grid(cr, paths.grid, sources.grid)
end

M.draw_dynamic = function(obj, cr)
   local static = obj.static
   local box = static.box
   local plotarea = static.plotarea
   local right_x = box.right_x
   local sources = plotarea.sources
   tsi.draw_series(cr, right_x, plotarea.bottom_y, plotarea.dx, obj.var, sources.series)
   tsi.draw_outline(cr, plotarea.paths.outline, sources.outline)
end

return M
