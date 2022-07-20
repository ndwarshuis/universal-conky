local M = {}

local timeseries = require 'timeseries'
local tsi = require 'timeseries_internal'
local ti = require 'text_internal'
local err = require 'err'
local ylabels = require 'ylabels'
local xlabels = require 'xlabels'
local geom = require 'geom'
local source = require 'source'
local pure = require 'pure'
local impure = require 'impure'

local __table_remove = table.remove
local __math_ceil = math.ceil
local __math_log = math.log

--------------------------------------------------------------------------------
-- pure

local choose_scale_factor = function(timers, new_sf)
   if #timers == 0 then
      return new_sf
   else
      local cur_sf = timers[1].factor
      if new_sf < cur_sf then
         return new_sf
      else
         return cur_sf
      end
   end
end

M.scaling_parameters = function(base, min_domain, threshold)
   return err.safe_table(
      {
         base = base,
         min_domain = min_domain,
         threshold = threshold,
      }
   )
end

local tick_timer = function(timer)
   timer.remaining = timer.remaining - 1
end

-- ASSUME
-- 1. this is a FIFO queue
-- 2. timers will be sorted from highest scale to lowest scale going from
--    back to front
-- 3. no timers will share a time slot
-- 4. no timers will have the same scale factor
-- 5. the table will always be a sequence
-- NOTE: scale factor is inversely related to scale, so higher scale -> lower
-- factor (hence the inequalities)
local update_timers = function(timers, prev_sf, new_sf, init_timer)
   if timers[1] and timers[1].remaining == 0 then
      __table_remove(timers, 1)
   end

   impure.each(tick_timer, timers)
   local n = #timers

   if new_sf < prev_sf then
      while n > 0 and timers[n].factor >= new_sf do
         timers[n] = nil
         n = n - 1
      end
   elseif new_sf > prev_sf and (n == 0 or prev_sf > timers[1].factor) then
      timers[n + 1] = init_timer(prev_sf)
   end
   return timers
end

local scale_point = function(value, y, h, new_factor, old_factor)
   return y + h * (1 - (1 - (value - y) / h) * (new_factor / old_factor))
end

-- local debug_timers = function(timers, sf, value)
--    print('----------------------------------------------------------------------')
--    print('value', value, 'scale_factor', sf)
--    for i, v in pairs(timers) do
--       print('timers', 'i', i, 't', v.remaining, 'f', v.factor)
--    end
--    print('length', #timers)
-- end

M.make = function(box, samplefreq, plot_config, label_config, scaling_params)
   local t = scaling_params.threshold
   local m = scaling_params.min_domain
   local b = scaling_params.base

   local get_scale_factor = function(x)
      local domain = m
      if x > 0 then
         domain = __math_ceil(__math_log(x / t) / __math_log(b))
      end
      if domain < m then domain = m end
      return b ^ -domain
   end

   local x = box.corner.x
   local gconf = plot_config.grid_config
   local x_label_format = timeseries.make_format_timecourse_x_label(plot_config.num_points, samplefreq)
   local label_font = ti.make_font(label_config.font_spec)
   local x_label_data = xlabels.make(box.bottom_y, gconf.num_x + 1, x_label_format, label_font)
   local axis_x = box.corner.x
   local right_x = axis_x + box.width
   local plot_y = box.corner.y
   local total_width = box.width
   local n_y_labels = gconf.num_y + 1

   local plot_height = box.height - xlabels.get_x_axis_height(label_font)

   local make_y_labels = pure.memoize(
      function(scale_factor)
         return ylabels.make(
            box.corner,
            plot_height,
            n_y_labels,
            label_font,
            label_config.y_format,
            scale_factor
         )
      end
   )

   local make_grid_paths = pure.memoize(
      function(y_axis_width)
         return tsi.make_plotarea_paths(
            geom.CR_DUMMY,
            right_x,
            plot_y,
            total_width - y_axis_width,
            plot_height,
            gconf.num_x,
            gconf.num_y
         )
      end
   )

   local get_x_label_positions = pure.memoize(
      function(y_axis_width)
         local w = total_width - y_axis_width
         return xlabels.get_x_label_positions(right_x, w, x_label_data)
      end
   )

   local init_timer = function(scale_factor)
      return {
         factor = scale_factor,
         remaining = plot_config.num_points
      }
   end

   local scale_data_points = function(series, old_factor, new_factor)
      if old_factor == new_factor then
         return series
      else
         return pure.map(scale_point, series, plot_y, plot_height, new_factor, old_factor)
      end
   end

   local insert_data_point = function(series, value, scale_factor)
      return tsi.insert_data_point(plot_y, plot_height, plot_config.num_points, series, value * scale_factor)
   end

   local inner_setter = function(value, series, cur_sf, prev_sf, timers)
      local new_sf = get_scale_factor(value)
      local new_timers = update_timers(timers, prev_sf, new_sf, init_timer)
      local new_cur_sf = choose_scale_factor(new_timers, new_sf)
      local y_labels = make_y_labels(1 / new_cur_sf)
      local width = total_width - y_labels.width
      -- debug_timers(new_timers, new_sf, value)
      return {
         axis = {
            x = {
               positions = get_x_label_positions(y_labels.width),
            },
            y = {
               labels = y_labels,
            }
         },
         current_scale_factor = new_cur_sf,
         prev_scale_factor = new_sf,
         plotarea = {
            dx = width / plot_config.num_points,
            paths = make_grid_paths(y_labels.width)
         },
         timers = new_timers,
         series = insert_data_point(
            scale_data_points(series, cur_sf, new_cur_sf),
            value,
            new_cur_sf
         )
      }
   end

   local setter = function(value, var)
      return inner_setter(
         value,
         var.series,
         var.current_scale_factor,
         var.prev_scale_factor,
         var.timers
      )
   end

   return err.safe_table(
      {
         static = {
            box = box,
            axis = {
               font = label_font,
               source = source.solid_color(label_config.color),
               x = {
                  label_data = x_label_data,
               }
            },
            plotarea = {
               bottom_y = plot_height + plot_y,
               sources = tsi.make_sources(x, plot_y, total_width, plot_config),
            },
         },
         setter = setter,
         var = inner_setter(0, {}, 1, 1, {}),
      }
   )
end

--------------------------------------------------------------------------------
-- impure

M.update = function(obj, value)
   obj.var = obj.setter(value, obj.var)
end

-- nothing here is "static" because we cannot assume that
-- any object will remain the same shape (can shift in both x and y)
M.draw_static = function(_, _)
   -- stub
end

M.draw_dynamic = function(obj, cr)
   local var = obj.var
   local static = obj.static
   local box = static.box
   local saxis = static.axis
   local vaxis = var.axis
   local vplotarea = var.plotarea
   local splotarea = static.plotarea
   local sources = splotarea.sources
   local paths = vplotarea.paths
   local right_x = box.right_x
   timeseries.draw_labels(
      cr,
      saxis.font,
      saxis.source,
      vaxis.x.positions,
      saxis.x.label_data,
      vaxis.y.labels
   )
   tsi.draw_grid(cr, paths.grid, sources.grid)
   tsi.draw_series(cr, right_x, splotarea.bottom_y, vplotarea.dx, var.series, sources.series)
   tsi.draw_outline(cr, paths.outline, sources.outline)
end

return M
