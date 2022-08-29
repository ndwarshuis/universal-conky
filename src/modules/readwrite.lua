local format = require 'format'
local pure = require 'pure'
local sys = require 'sys'
local i_o = require 'i_o'
local impure = require 'impure'

return function(update_freq, config, common, width, point)
   local geo = config.geometry
   local plot_sec_break = geo.plot.sec_break
   local plot_height = geo.plot.height

   local mod_state = {read = 0, write = 0}
   local device_paths = sys.get_disk_paths(config.devices)

   impure.each(i_o.assert_file_exists, device_paths)

   local update_state = function()
      mod_state.read, mod_state.write = sys.get_total_disk_io(device_paths)
   end

   local format_value_function = function(bps)
      local unit, value = format.convert_data_val(bps)
      return format.precision_round_to_string(value, 3)..' '..unit..'B/s'
   end

   -- prime state
   update_state()

   -----------------------------------------------------------------------------
   -- r/w plots

   local mk_plot = function(label, key, y)
      local obj = common.make_rate_timeseries(
         point.x,
         y,
         width,
         plot_height,
         geo.plot.ticks_y,
         format_value_function,
         common.converted_y_label_format_generator('B'),
         plot_sec_break,
         label,
         2,
         update_freq,
         mod_state[key]
      )
      return common.mk_acc(
         width,
         plot_height + plot_sec_break,
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
         {mk_reads, true, plot_sec_break},
         {mk_writes, true, 0},
      }
   }
end
