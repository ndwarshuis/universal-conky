local Widget		= require 'Widget'
local Arc			= require 'Arc'
local Dial 			= require 'Dial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local util			= require 'util'
local Patterns		= require 'Patterns'

local __string_match		= string.match
local __cairo_path_destroy 	= cairo_path_destroy

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

local MEM_TOTAL_KB = tonumber(util.read_file('/proc/meminfo', '^MemTotal:%s+(%d+)'))

local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
                      '\nBuffers:%s+(%d+).+'..
                      '\nCached:%s+(%d+).+'..
                      '\nSwapTotal:%s+(%d+).+'..
                      '\nSwapFree:%s+(%d+).+'..
                      '\nSReclaimable:%s+(%d+)'

local NUM_ROWS = 5
local TABLE_CONKY = {{}, {}, {}}

for r = 1, NUM_ROWS do
	TABLE_CONKY[1][r] = '${top_mem name '..r..'}'
	TABLE_CONKY[2][r] = '${top_mem pid '..r..'}'
	TABLE_CONKY[3][r] = '${top_mem mem '..r..'}'
end

local header = Widget.Header{
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

local dial = Widget.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= _DIAL_THICKNESS_,
	critical_limit 	= '>0.8'
}
local cache_arc = Widget.Arc{
	x 			= DIAL_X,
	y 			= DIAL_Y,			
	radius 		= DIAL_RADIUS,
	thickness 	= _DIAL_THICKNESS_,
	arc_pattern	= Patterns.PURPLE_ROUNDED
}

local total_used = Widget.CriticalText{
	x 			= DIAL_X,
	y 			= DIAL_Y,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%'
}

local inner_ring = Widget.Arc{
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
	label = Widget.Text{
		x 		= _TEXT_LEFT_X_,
		y 		= _LINE_1_Y_,
		spacing = _TEXT_SPACING_,
		text	= 'Swap Usage'
	},
	percent = Widget.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _LINE_1_Y_,
		x_align 	= 'right',
		append_end 	= ' %',
	},
}

local cache = {
	labels = Widget.TextColumn{
		x 		= _TEXT_LEFT_X_,
		y 		= _LINE_1_Y_ + _TEXT_SPACING_,
		spacing = _TEXT_SPACING_,
		'Page Cache',
		'Buffers',
		'Kernel Slab'
	},
	percents = Widget.TextColumn{
		x 			= _RIGHT_X_,
		y 			= _LINE_1_Y_ + _TEXT_SPACING_,
		x_align 	= 'right',
		append_end 	= ' %',
		text_color	= Patterns.PURPLE,
		'<cached_kb>',
		'<buffers_kb>',
		'<kernel_slab>'
	},
}

local _PLOT_Y_ = _PLOT_SECTION_BREAK_ + header.bottom_y + DIAL_RADIUS * 2

local plot = Widget.LabelPlot{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _PLOT_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	height = _PLOT_HEIGHT_
}

local tbl = Widget.Table{
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
	  slab_reclaimable_kb = __string_match(util.read_file('/proc/meminfo'), MEMINFO_REGEX)

	local used_percent = (MEM_TOTAL_KB - memfree_kb - cached_kb - buffers_kb - slab_reclaimable_kb) / MEM_TOTAL_KB

	Dial.set(dial, used_percent)
	CriticalText.set(total_used, cr, util.round(used_percent * 100))

	local cache_theta = (DIAL_THETA_0 - DIAL_THETA_1) / MEM_TOTAL_KB * memfree_kb + DIAL_THETA_1
	__cairo_path_destroy(cache_arc.path)
	cache_arc.path = Arc.create_path(cr, DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)
	
	CriticalText.set(swap.percent, cr, util.precision_round_to_string(
	  (swap_total_kb - swap_free_kb) /	swap_total_kb * 100))

	local _percents = cache.percents
	
	TextColumn.set(_percents, cr, 1, util.precision_round_to_string(
	  cached_kb / MEM_TOTAL_KB * 100))
	  
	TextColumn.set(_percents, cr, 2, util.precision_round_to_string(
	  buffers_kb / MEM_TOTAL_KB * 100))
	  
	TextColumn.set(_percents, cr, 3, util.precision_round_to_string(
	  slab_reclaimable_kb / MEM_TOTAL_KB * 100))

	LabelPlot.update(plot, used_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, NUM_ROWS do
			Table.set(tbl, cr, c, r, util.conky(column[r], '(%S+)'))
		end
	end
end

Widget = nil
Patterns = nil
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
