local format = require 'format'
local common = require 'common'
local geometry = require 'geometry'
local sys = require 'sys'

return function(update_freq, devices, point)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   -- TODO currently this will find any block device
   local DEVICE_PATHS = sys.get_disk_paths(devices)

   local init_read_bytes, init_write_bytes = sys.get_total_disk_io(DEVICE_PATHS)

   local format_value_function = function(bps)
      local unit, value = format.convert_data_val(bps)
      return format.precision_round_to_string(value, 3)..' '..unit..'B/s'
   end

   local make_plot = function(y, label, init)
      return common.make_rate_timeseries(
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
         init
      )
   end

   -----------------------------------------------------------------------------
   -- header

   local header = common.make_header(
      point.x,
      point.y,
      geometry.SECTION_WIDTH,
      'INPUT / OUTPUT'
   )

   -----------------------------------------------------------------------------
   -- reads

   local reads = make_plot(header.bottom_y, 'Reads', init_read_bytes)

   -----------------------------------------------------------------------------
   -- writes

   local writes = make_plot(
      header.bottom_y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2,
      'Writes',
      init_write_bytes
   )

   -----------------------------------------------------------------------------
   -- main drawing functions

   local update = function()
      local read_bytes, write_bytes = sys.get_total_disk_io(DEVICE_PATHS)
      common.update_rate_timeseries(reads, read_bytes)
      common.update_rate_timeseries(writes, write_bytes)
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)
      common.tagged_scaled_timeseries_draw_static(reads, cr)
      common.tagged_scaled_timeseries_draw_static(writes, cr)
   end

   local draw_dynamic = function(cr)
      common.tagged_scaled_timeseries_draw_dynamic(reads, cr)
      common.tagged_scaled_timeseries_draw_dynamic(writes, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
