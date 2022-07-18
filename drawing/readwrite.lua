local format = require 'format'
local pure = require 'pure'
local sys = require 'sys'

return function(update_freq, config, common, width, point)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56

   local mod_state = {read = 0, write = 0}
   local device_paths = sys.get_disk_paths(config.devices)

   local update_state = function()
      mod_state.read, mod_state.write = sys.get_total_disk_io(device_paths)
   end

   local format_value_function = function(bps)
      local unit, value = format.convert_data_val(bps)
      return format.precision_round_to_string(value, 3)..' '..unit..'B/s'
   end

   -----------------------------------------------------------------------------
   -- r/w plots

   local mk_plot = function(label, key, y)
      local obj = common.make_rate_timeseries(
         point.x,
         y,
         width,
         PLOT_HEIGHT,
         format_value_function,
         common.converted_y_label_format_generator('B'),
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq,
         mod_state[key]
      )
      return common.mk_acc(
         -- TODO construct this more sanely without referring to hardcoded vars
         width,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         function() common.update_rate_timeseries(obj, mod_state[key]) end,
         pure.partial(common.tagged_scaled_timeseries_draw_static, obj),
         pure.partial(common.tagged_scaled_timeseries_draw_dynamic, obj)
      )
   end

   local mk_reads = pure.partial(mk_plot, 'Reads', 'read')
   local mk_writes = pure.partial(mk_plot, 'Writes', 'write')

   -----------------------------------------------------------------------------
   -- main drawing functions

   return {
      header = 'INPUT / OUTPUT',
      point = point,
      width = width,
      set_state = update_state,
      top = {
         {mk_reads, true, PLOT_SEC_BREAK},
         {mk_writes, true, 0},
      }
   }
end
