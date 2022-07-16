local format = require 'format'
local pure = require 'pure'
local common = require 'common'
local geometry = require 'geometry'
local sys = require 'sys'

return function(update_freq, devices, point)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   -- TODO currently this will find any block device
   local DEVICE_PATHS = sys.get_disk_paths(devices)

   local state = {read = 0, write = 0}
   state.read, state.write = sys.get_total_disk_io(DEVICE_PATHS)

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
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         format_value_function,
         common.converted_y_label_format_generator('B'),
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq,
         state[key]
      )
      return common.mk_acc(
         -- TODO construct this more sanely without referring to hardcoded vars
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         function() common.update_rate_timeseries(obj, state[key]) end,
         pure.partial(common.tagged_scaled_timeseries_draw_static, obj),
         pure.partial(common.tagged_scaled_timeseries_draw_dynamic, obj)
      )
   end

   local mk_reads = pure.partial(mk_plot, 'Reads', 'read')
   local mk_writes = pure.partial(mk_plot, 'Writes', 'write')

   -----------------------------------------------------------------------------
   -- main drawing functions

   local rbs = common.reduce_blocks_(
      'INPUT / OUTPUT',
      point,
      geometry.SECTION_WIDTH,
      {
         common.mk_block(mk_reads, true, PLOT_SEC_BREAK),
         common.mk_block(mk_writes, true, 0),
      }
   )

   return pure.map_at(
      "update",
      function(f)
         return function(_)
            state.read, state.write = sys.get_total_disk_io(DEVICE_PATHS)
            f()
         end
      end,
      rbs)
end
