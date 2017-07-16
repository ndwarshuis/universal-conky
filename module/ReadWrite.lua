local Widget	= require 'Widget'
local Text		= require 'Text'
local Line		= require 'Line'
local ScalePlot = require 'ScalePlot'
local util		= require 'util'
local schema	= require 'default_patterns'

local _TONUMBER 	= tonumber
local _STRING_MATCH = string.match

local HW_BLOCK_SIZE = 512 											--bytes
local STAT_FILE = '/sys/block/sda/stat'
local RW_REGEX = '%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)'	--fields 3 and 7 (sectors read and written)

--construction params
local PLOT_SEC_BREAK = 20
local PLOT_HEIGHT = 56

local __read_stat_file = function()
	local bytes_read, bytes_written = _STRING_MATCH(util.read_file(STAT_FILE), RW_REGEX)
	return _TONUMBER(bytes_read) * HW_BLOCK_SIZE, _TONUMBER(bytes_written) * HW_BLOCK_SIZE
end

local __update_stat = function(cr, stat, cumulative, update_frequency)
	local bytes = (cumulative - stat.prev_cumulative) * update_frequency
	stat.prev_cumulative = cumulative
	
	if bytes < 0 then bytes = 0 end  --mask wrap

	local unit = util.get_unit(bytes)
	
	stat.rate.append_end = ' '..unit..'/s'
	Text.set(stat.rate, cr, util.precision_convert_bytes(bytes, 'B', unit, 3))
	ScalePlot.update(stat.plot, cr, bytes)	
end

local __io_label_function = function(bytes)
	local new_unit = util.get_unit(bytes)
	
	local converted = util.convert_bytes(bytes, 'B', new_unit)
	local precision = 0
	if converted < 10 then precision = 1 end
	
	return util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
	y = CONSTRUCTION_GLOBAL.TOP_Y,
	width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	header = "INPUT / OUTPUT"
}

local HEADER_BOTTOM_Y = header.bottom_y
local RIGHT_X = CONSTRUCTION_GLOBAL.CENTER_LEFT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH
local READS_PLOT_Y = header.bottom_y + PLOT_SEC_BREAK

local reads = {
	label = Widget.Text{
		x = CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
		y = HEADER_BOTTOM_Y,
		text = 'Reads',
	},
	rate = Widget.Text{
		x = RIGHT_X,
		y = HEADER_BOTTOM_Y,
		x_align = 'right',
		append_end=' B/s',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
		y = READS_PLOT_Y,
		width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __io_label_function,
	}
}

local WRITE_Y = READS_PLOT_Y + PLOT_HEIGHT + PLOT_SEC_BREAK
local WRITES_PLOT_Y = WRITE_Y + PLOT_SEC_BREAK

local writes = {
	label = Widget.Text{
		x = CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
		y = WRITE_Y,
		text = 'Writes',
	},
	rate = Widget.Text{
		x = RIGHT_X,
		y = WRITE_Y,
		x_align = 'right',
		append_end =' B/s',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
		y = WRITES_PLOT_Y,
		width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __io_label_function,
	}
}

Widget = nil
schema = nil
PLOT_SEC_BREAK = nil
PLOT_HEIGHT = nil
HEADER_BOTTOM_Y = nil
RIGHT_X = nil
READS_PLOT_Y = nil
WRITE_Y = nil
WRITES_PLOT_Y = nil

reads.cumulative = 0
writes.cumulative = 0
reads.prev_cumulative, writes.prev_cumulative = __read_stat_file()

local __update = function(cr, update_frequency)
	local cumulative_reads, cumulative_writes = __read_stat_file()
	__update_stat(cr, reads, cumulative_reads, update_frequency)
	__update_stat(cr, writes, cumulative_writes, update_frequency)
end

local draw = function(cr, current_interface, update_frequency)
	__update(cr, update_frequency)

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
