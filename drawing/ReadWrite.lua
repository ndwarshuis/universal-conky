local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local DEVICES = {'sda', 'nvme0n1'}

   -- the sector size of any block device in linux is 512 bytes
   -- see https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/linux/types.h?id=v4.4-rc6#n121
   local BLOCK_SIZE_BYTES = 512

   -- fields 3 and 7 (sectors read and written)
   local RW_REGEX = '%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)'

   local __tonumber = tonumber
   local __string_match = string.match

   local DEVICE_PATHS = {}
   for i = 1, #DEVICES do
      DEVICE_PATHS[i] = string.format('/sys/block/%s/stat', DEVICES[i])
   end

   local read_devices = function()
      local read_bytes = 0
      local write_bytes = 0
      for _, path in pairs(DEVICE_PATHS) do
         local r, w = __string_match(Util.read_file(path), RW_REGEX)
         read_bytes = read_bytes + __tonumber(r)
         write_bytes = write_bytes + __tonumber(w)
      end
      return read_bytes * BLOCK_SIZE_BYTES, write_bytes * BLOCK_SIZE_BYTES
   end

   local init_read_bytes, init_write_bytes = read_devices()

   local format_value_function = function(bps)
      local unit, value = Util.convert_data_val(bps)
      return Util.precision_round_to_string(value, 3)..' '..unit..'B/s'
   end

   local build_plot = function(y, label, init)
      return Common.build_rate_timeseries(
         Geometry.CENTER_LEFT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         format_value_function,
         Common.converted_y_label_format_generator('B'),
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq,
         init
      )
   end

   -----------------------------------------------------------------------------
   -- header

   local header = Common.Header(
      Geometry.CENTER_LEFT_X,
      Geometry.TOP_Y,
      Geometry.SECTION_WIDTH,
      'INPUT / OUTPUT'
   )

   -----------------------------------------------------------------------------
   -- reads

   local reads = build_plot(header.bottom_y, 'Reads', init_read_bytes)

   -----------------------------------------------------------------------------
   -- writes

   local writes = build_plot(
      header.bottom_y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2,
      'Writes',
      init_write_bytes
   )

   -----------------------------------------------------------------------------
   -- main drawing functions

   local update = function(cr)
      local read_bytes, write_bytes = read_devices()
      Common.update_rate_timeseries(reads, cr, read_bytes)
      Common.update_rate_timeseries(writes, cr, write_bytes)
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.annotated_scale_plot_draw_static(reads, cr)
      Common.annotated_scale_plot_draw_static(writes, cr)
   end

   local draw_dynamic = function(cr)
      update(cr)
      Common.annotated_scale_plot_draw_dynamic(reads, cr)
      Common.annotated_scale_plot_draw_dynamic(writes, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
