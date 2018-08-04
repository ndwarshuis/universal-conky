local Arc			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __string_match		= string.match
local __cairo_path_destroy 	= cairo_path_destroy
local __io_popen            = io.popen

local _MODULE_Y_ = 712
local _DIAL_THICKNESS_ = 8
local _DIAL_SPACING_ = 1
local _TEXT_Y_OFFSET_ = 7
local _TEXT_LEFT_X_OFFSET_ = 30
local _TEXT_SPACING_ = 20
local _PLOT_SECTION_BREAK_ = 30
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 20
local _TABLE_HEIGHT_ = 114

local MEM_TOTAL_KB = tonumber(Util.read_file('/proc/meminfo', '^MemTotal:%s+(%d+)'))

local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
                      '\nBuffers:%s+(%d+).+'..
                      '\nCached:%s+(%d+).+'..
                      '\nSwapTotal:%s+(%d+).+'..
                      '\nSwapFree:%s+(%d+).+'..
                      '\nSReclaimable:%s+(%d+)'

local NUM_ROWS = 5

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'MEMORY'
}

local DIAL_RADIUS = 32
local DIAL_THETA_0 = math.rad(90)
local DIAL_THETA_1 = math.rad(360)
local DIAL_X = _G_INIT_DATA_.RIGHT_X + DIAL_RADIUS + _DIAL_THICKNESS_ / 2
local DIAL_Y = header.bottom_y + DIAL_RADIUS + _DIAL_THICKNESS_ / 2

local dial = _G_Widget_.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= _DIAL_THICKNESS_,
	critical_limit 	= '>0.8'
}
local cache_arc = _G_Widget_.Arc{
	x 			= DIAL_X,
	y 			= DIAL_Y,			
	radius 		= DIAL_RADIUS,
	thickness 	= _DIAL_THICKNESS_,
	arc_pattern	= _G_Patterns_.PURPLE_ROUNDED
}

local total_used = _G_Widget_.CriticalText{
	x 			= DIAL_X,
	y 			= DIAL_Y,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%'
}

local inner_ring = _G_Widget_.Arc{
	x 		= DIAL_X,
	y 		= DIAL_Y,
	radius 	= DIAL_RADIUS - _DIAL_THICKNESS_ / 2 - 2,
	theta0	= 0,
	theta1	= 360
}

local _LINE_1_Y_ = header.bottom_y + _TEXT_Y_OFFSET_
local _TEXT_LEFT_X_ = _G_INIT_DATA_.RIGHT_X + DIAL_RADIUS * 2 + _TEXT_LEFT_X_OFFSET_
local _RIGHT_X_ = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local swap= {
	label = _G_Widget_.Text{
		x 		= _TEXT_LEFT_X_,
		y 		= _LINE_1_Y_,
		spacing = _TEXT_SPACING_,
		text	= 'Swap Usage'
	},
	percent = _G_Widget_.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _LINE_1_Y_,
		x_align 	= 'right',
		append_end 	= ' %',
	},
}

local cache = {
	labels = _G_Widget_.TextColumn{
		x 		= _TEXT_LEFT_X_,
		y 		= _LINE_1_Y_ + _TEXT_SPACING_,
		spacing = _TEXT_SPACING_,
		'Page Cache',
		'Buffers',
		'Kernel Slab'
	},
	percents = _G_Widget_.TextColumn{
		x 			= _RIGHT_X_,
		y 			= _LINE_1_Y_ + _TEXT_SPACING_,
		x_align 	= 'right',
		append_end 	= ' %',
		text_color	= _G_Patterns_.PURPLE,
		'<cached_kb>',
		'<buffers_kb>',
		'<kernel_slab>'
	},
}

local _PLOT_Y_ = _PLOT_SECTION_BREAK_ + header.bottom_y + DIAL_RADIUS * 2

local plot = _G_Widget_.LabelPlot{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _PLOT_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	height = _PLOT_HEIGHT_
}

local tbl = _G_Widget_.Table{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	height = _TABLE_HEIGHT_,
	'Name',
	'PID',
	'Mem (%)'
}

local update = function(cr)
	-- see source for the 'free' command (sysinfo.c) for formulas

	local memfree_kb, buffers_kb, cached_kb, swap_total_kb, swap_free_kb,
	  slab_reclaimable_kb = __string_match(Util.read_file('/proc/meminfo'), MEMINFO_REGEX)

	local used_percent = (MEM_TOTAL_KB - memfree_kb - cached_kb - buffers_kb - slab_reclaimable_kb) / MEM_TOTAL_KB

	Dial.set(dial, used_percent)
	CriticalText.set(total_used, cr, Util.round(used_percent * 100))

	local cache_theta = (DIAL_THETA_0 - DIAL_THETA_1) / MEM_TOTAL_KB * memfree_kb + DIAL_THETA_1
	__cairo_path_destroy(cache_arc.path)
	cache_arc.path = Arc.create_path(cr, DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)
	
	CriticalText.set(swap.percent, cr, Util.precision_round_to_string(
	  (swap_total_kb - swap_free_kb) /	swap_total_kb * 100))

	local _percents = cache.percents
	
	TextColumn.set(_percents, cr, 1, Util.precision_round_to_string(
	  cached_kb / MEM_TOTAL_KB * 100))
	  
	TextColumn.set(_percents, cr, 2, Util.precision_round_to_string(
	  buffers_kb / MEM_TOTAL_KB * 100))
	  
	TextColumn.set(_percents, cr, 3, Util.precision_round_to_string(
	  slab_reclaimable_kb / MEM_TOTAL_KB * 100))

	LabelPlot.update(plot, used_percent)

	local ps_glob = __io_popen('ps -A -o "pmem,pid,comm" --sort=-pmem h')

	for r = 1, NUM_ROWS do
	   local ps_line = ps_glob:read()
	   local pmem, pid, comm = __string_match(ps_line, '(%d+%.%d+)%s+(%d+)%s+(.+)$')
	   Table.set(tbl, cr, 1, r, comm)
	   Table.set(tbl, cr, 2, r, pid)
	   Table.set(tbl, cr, 3, r, pmem)
	end

	ps_glob:close()
end

_MODULE_Y_ = nil
_DIAL_THICKNESS_ = nil
_DIAL_SPACING_ = nil
_TEXT_Y_OFFSET_ = nil
_TEXT_LEFT_X_OFFSET_ = nil
_TEXT_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_LINE_1_Y_ = nil
_TEXT_LEFT_X_ = nil
_RIGHT_X_ = nil
_PLOT_Y_ = nil

local draw = function(cr, current_interface)
	update(cr)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		Dial.draw(dial, cr)
		Arc.draw(cache_arc, cr)
		Arc.draw(inner_ring, cr)
		CriticalText.draw(total_used, cr)

		Text.draw(swap.label, cr)
		CriticalText.draw(swap.percent, cr)
		TextColumn.draw(cache.labels, cr)
		TextColumn.draw(cache.percents, cr)

		LabelPlot.draw(plot, cr)

		Table.draw(tbl, cr)
	end
end

return draw
