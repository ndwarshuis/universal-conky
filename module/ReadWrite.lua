local Widget	= require 'Widget'
local Text		= require 'Text'
local Line		= require 'Line'
local ScalePlot = require 'ScalePlot'
local util		= require 'util'
local schema	= require 'default_patterns'

local __tonumber 	= tonumber
local __string_match = string.match

local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local BLOCK_SIZE_BYTES = 512
local STAT_FILE = '/sys/block/sda/stat'

-- fields 3 and 7 (sectors read and written)
local RW_REGEX = '%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)'

local read_stat_file = function()
	local bytes_r, bytes_w = __string_match(util.read_file(STAT_FILE), RW_REGEX)
	return __tonumber(bytes_r) * BLOCK_SIZE_BYTES, __tonumber(bytes_w) * BLOCK_SIZE_BYTES
end

local update_stat = function(cr, stat, byte_cnt, update_frequency)
	local delta_bytes = byte_cnt - stat.prev_byte_cnt
	stat.prev_byte_cnt = byte_cnt
	
	if delta_bytes > 0 then
		local bps = delta_bytes / update_frequency
		local unit = util.get_unit(bps)
		stat.rate.append_end = ' '..unit..'/s'
		Text.set(stat.rate, cr, util.precision_convert_bytes(bps, 'B', unit, 3))
		ScalePlot.update(stat.plot, cr, bps)	
	else
		stat.rate.append_end = ' B/s'
		Text.set(stat.rate, cr, '0.00')
		ScalePlot.update(stat.plot, cr, 0)	
	end
end

local io_label_function = function(bytes)
	local new_unit = util.get_unit(bytes)
	
	local converted = util.convert_bytes(bytes, 'B', new_unit)
	local precision = 0
	if converted < 10 then precision = 1 end
	
	return util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local header = Widget.Header{
	x = _G_INIT_DATA_.CENTER_LEFT_X,
	y = _G_INIT_DATA_.TOP_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'INPUT / OUTPUT'
}

local _RIGHT_X_ = _G_INIT_DATA_.CENTER_LEFT_X + _G_INIT_DATA_.SECTION_WIDTH

local reads = {
	label = Widget.Text{
		x = _G_INIT_DATA_.CENTER_LEFT_X,
		y = header.bottom_y,
		text = 'Reads',
	},
	rate = Widget.Text{
		x = _RIGHT_X_,
		y = header.bottom_y,
		x_align = 'right',
		append_end=' B/s',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = _G_INIT_DATA_.CENTER_LEFT_X,
		y = header.bottom_y + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = io_label_function,
	}
}

local _WRITE_Y_ = header.bottom_y + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local writes = {
	label = Widget.Text{
		x = _G_INIT_DATA_.CENTER_LEFT_X,
		y = _WRITE_Y_,
		text = 'Writes',
	},
	rate = Widget.Text{
		x = _RIGHT_X_,
		y = _WRITE_Y_,
		x_align = 'right',
		append_end =' B/s',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = _G_INIT_DATA_.CENTER_LEFT_X,
		y = _WRITE_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = io_label_function,
	}
}

Widget = nil
schema = nil
_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_RIGHT_X_ = nil
_WRITE_Y_ = nil

reads.byte_cnt = 0
writes.byte_cnt = 0
reads.prev_byte_cnt, writes.prev_byte_cnt = read_stat_file()

local update = function(cr, update_frequency)
	local read_byte_cnt, write_byte_cnt = read_stat_file()
	update_stat(cr, reads, read_byte_cnt, update_frequency)
	update_stat(cr, writes, write_byte_cnt, update_frequency)
end

local draw = function(cr, current_interface, update_frequency)
	update(cr, update_frequency)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		
		Text.draw(reads.label, cr)
		Text.draw(reads.rate, cr)
		ScalePlot.draw(reads.plot, cr)
		
		Text.draw(writes.label, cr)
		Text.draw(writes.rate, cr)
		ScalePlot.draw(writes.plot, cr)
	end
end

return draw
