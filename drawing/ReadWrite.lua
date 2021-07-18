local Util		= require 'Util'
local Common	= require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56

   local __tonumber 	= tonumber
   local __string_match = string.match
   local __math_floor = math.floor

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

   local io_label_function = function(bytes)
      local new_unit, new_value = Util.convert_data_val(bytes)
      return __math_floor(new_value)..' '..new_unit..'B/s'
   end

   local format_value_function = function(bps)
      local unit, value = Util.convert_data_val(bps)
      return Util.precision_round_to_string(value, 3)..' '..unit..'B/s'
   end

   local build_plot = function(y, label)
      return Common.initLabeledScalePlot(
         Geometry.CENTER_LEFT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         format_value_function,
         io_label_function,
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq
      )
   end

   local reads = build_plot(header.bottom_y, 'Reads')

   -----------------------------------------------------------------------------
   -- writes

   local writes = build_plot(
      header.bottom_y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2,
      'Writes'
   )

   -----------------------------------------------------------------------------
   -- update function

   -- TODO add more devices to this
   local BLOCK_SIZE_BYTES = 512
   local STAT_FILE = '/sys/block/sda/stat'

   -- fields 3 and 7 (sectors read and written)
   local RW_REGEX = '%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)'

   local read_stat_file = function()
      local bytes_r, bytes_w = __string_match(Util.read_file(STAT_FILE), RW_REGEX)
      return __tonumber(bytes_r) * BLOCK_SIZE_BYTES, __tonumber(bytes_w) * BLOCK_SIZE_BYTES
   end

   reads.byte_cnt = 0
   writes.byte_cnt = 0
   reads.prev_byte_cnt, writes.prev_byte_cnt = read_stat_file()

   local update_stat = function(cr, stat, byte_cnt)
      local delta_bytes = byte_cnt - stat.prev_byte_cnt
      stat.prev_byte_cnt = byte_cnt

      local plot_value = 0
      if delta_bytes > 0 then
         local bps = delta_bytes * update_freq
         plot_value = bps
      end
      Common.annotated_scale_plot_set(stat, cr, plot_value)
   end

   local update = function(cr)
      local read_byte_cnt, write_byte_cnt = read_stat_file()
      update_stat(cr, reads, read_byte_cnt)
      update_stat(cr, writes, write_byte_cnt)
   end

   -----------------------------------------------------------------------------
   -- main drawing functions

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
