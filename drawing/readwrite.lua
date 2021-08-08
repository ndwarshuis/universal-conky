local i_o = require 'i_o'
local format = require 'format'
local common = require 'common'
local geometry = require 'geometry'
local pure = require 'pure'

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

   local DEVICE_PATHS = pure.map(
      pure.partial(string.format, '/sys/block/%s/stat', true),
      DEVICES
   )

   local read_devices = function()
      local read_bytes = 0
      local write_bytes = 0
      for _, path in pairs(DEVICE_PATHS) do
         local r, w = __string_match(i_o.read_file(path), RW_REGEX)
         read_bytes = read_bytes + __tonumber(r)
         write_bytes = write_bytes + __tonumber(w)
      end
      return read_bytes * BLOCK_SIZE_BYTES, write_bytes * BLOCK_SIZE_BYTES
   end

   local init_read_bytes, init_write_bytes = read_devices()

   local format_value_function = function(bps)
      local unit, value = format.convert_data_val(bps)
      return format.precision_round_to_string(value, 3)..' '..unit..'B/s'
   end

   local make_plot = function(y, label, init)
      return common.make_rate_timeseries(
         geometry.CENTER_LEFT_X,
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
      geometry.CENTER_LEFT_X,
      geometry.TOP_Y,
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
      local read_bytes, write_bytes = read_devices()
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
