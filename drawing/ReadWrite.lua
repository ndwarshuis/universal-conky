local M = {}

local Util		= require 'Util'
local Common	= require 'Common'

local __tonumber 	= tonumber
local __string_match = string.match

local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local BLOCK_SIZE_BYTES = 512
local STAT_FILE = '/sys/block/sda/stat'

-- fields 3 and 7 (sectors read and written)
local RW_REGEX = '%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)'

local read_stat_file = function()
	local bytes_r, bytes_w = __string_match(Util.read_file(STAT_FILE), RW_REGEX)
	return __tonumber(bytes_r) * BLOCK_SIZE_BYTES, __tonumber(bytes_w) * BLOCK_SIZE_BYTES
end

local update_stat = function(cr, stat, byte_cnt, update_frequency)
	local delta_bytes = byte_cnt - stat.prev_byte_cnt
	stat.prev_byte_cnt = byte_cnt

    -- local text_value = '0.00 B/s'
    local plot_value = 0
	if delta_bytes > 0 then
		local bps = delta_bytes * update_frequency
		-- local unit, value = Util.convert_data_val(bps)
        -- text_value = Util.precision_round_to_string(value, 3)..' '..unit..'B/s'
        plot_value = bps
	end
    -- Common.annotated_scale_plot_set(stat, cr, text_value, plot_value)
    Common.annotated_scale_plot_set(stat, cr, plot_value)
end

local io_label_function = function(bytes)
	local new_unit, new_value = Util.convert_data_val(bytes)

	local precision = 0
	if new_value < 10 then precision = 1 end

	return Util.round_to_string(new_value, precision)..' '..new_unit..'B/s'
end

local format_value_function = function(bps)
   local unit, value = Util.convert_data_val(bps)
   return Util.precision_round_to_string(value, 3)..' '..unit..'B/s'
end

local header = Common.Header(
	_G_INIT_DATA_.CENTER_LEFT_X,
	_G_INIT_DATA_.TOP_Y,
	_G_INIT_DATA_.SECTION_WIDTH,
	'INPUT / OUTPUT'
)

local reads = Common.initLabeledScalePlot(
      _G_INIT_DATA_.CENTER_LEFT_X,
      header.bottom_y,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      format_value_function,
      io_label_function,
      _PLOT_SEC_BREAK_,
      'Reads',
      2

)

local writes = Common.initLabeledScalePlot(
      _G_INIT_DATA_.CENTER_LEFT_X,
      header.bottom_y + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      format_value_function,
      io_label_function,
      _PLOT_SEC_BREAK_,
      'Writes',
      2
)


_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil

reads.byte_cnt = 0
writes.byte_cnt = 0
reads.prev_byte_cnt, writes.prev_byte_cnt = read_stat_file()

local update = function(cr, update_frequency)
	local read_byte_cnt, write_byte_cnt = read_stat_file()
	update_stat(cr, reads, read_byte_cnt, update_frequency)
	update_stat(cr, writes, write_byte_cnt, update_frequency)
end

local draw_static = function(cr)
   Common.drawHeader(cr, header)
   Common.annotated_scale_plot_draw_static(reads, cr)
   Common.annotated_scale_plot_draw_static(writes, cr)
end

local draw_dynamic = function(cr, update_frequency)
   update(cr, update_frequency)
   Common.annotated_scale_plot_draw_dynamic(reads, cr)
   Common.annotated_scale_plot_draw_dynamic(writes, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
