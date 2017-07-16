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
local schema		= require 'default_patterns'

local _STRING_MATCH = string.match
local _MATH_RAD		= math.rad

local _CAIRO_PATH_DESTROY = cairo_path_destroy

local MODULE_Y = 712

local MEM_TOTAL = tonumber(util.read_file('/proc/meminfo', 'MemTotal:%s+(%d+)')) 	--in kB

local DIAL_RADIUS = 32
local DIAL_THETA0 = 90
local DIAL_THETA1 = 360

local TABLE_CONKY = {}
for c = 1, 3 do TABLE_CONKY[c] = {} end
for r = 1, 5 do TABLE_CONKY[1][r] = '${top_mem name '..r..'}' end
for r = 1, 5 do TABLE_CONKY[2][r] = '${top_mem pid '..r..'}' end
for r = 1, 5 do TABLE_CONKY[3][r] = '${top_mem mem '..r..'}' end

--construction params
local DIAL_THICKNESS = 8
local DIAL_SPACING = 1
local TEXT_Y_OFFSET = 7
local TEXT_LEFT_X_OFFSET = 30
local TEXT_SPACING = 20
local SEPARATOR_SPACING = 15
local PLOT_SECTION_BREAK = 30
local PLOT_HEIGHT = 56
local TABLE_SECTION_BREAK = 20
local TABLE_HEIGHT = 114

local header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.RIGHT_X,
	y = MODULE_Y,
	width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	header = "MEMORY"
}

local HEADER_BOTTOM_Y = header.bottom_y

--don't nil these
local DIAL_X = CONSTRUCTION_GLOBAL.RIGHT_X + DIAL_RADIUS + DIAL_THICKNESS * 0.5
local DIAL_Y = HEADER_BOTTOM_Y + DIAL_RADIUS + DIAL_THICKNESS * 0.5

local dial = Widget.Dial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	radius 			= DIAL_RADIUS,
	thickness 		= DIAL_THICKNESS,
	critical_limit 	= '>0.8'
}
local cache_arc = Widget.Arc{
	x 			= DIAL_X,
	y 			= DIAL_Y,			
	radius 		= DIAL_RADIUS,
	thickness 	= DIAL_THICKNESS,
	arc_pattern	= schema.purple_rounded
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
	radius 	= DIAL_RADIUS - DIAL_THICKNESS / 2 - 2,
	theta0	= 0,
	theta1	= 360
}

local LINE_1_Y = HEADER_BOTTOM_Y + TEXT_Y_OFFSET
local TEXT_LEFT_X = CONSTRUCTION_GLOBAL.RIGHT_X + DIAL_RADIUS * 2 + TEXT_LEFT_X_OFFSET
local RIGHT_X = CONSTRUCTION_GLOBAL.RIGHT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH

local swap= {
	label = Widget.Text{
		x 		= TEXT_LEFT_X,
		y 		= LINE_1_Y,
		spacing = TEXT_SPACING,
		text	= 'Swap Usage'
	},
	percent = Widget.CriticalText{
		x 			= RIGHT_X,
		y 			= LINE_1_Y,
		x_align 	= 'right',
		append_end 	= ' %',
	},
}

local cache = {
	labels = Widget.TextColumn{
		x 		= TEXT_LEFT_X,
		y 		= LINE_1_Y + TEXT_SPACING,
		spacing = TEXT_SPACING,
		'Page Cache',
		'Buffers',
		'Kernel Slab'
	},
	percents = Widget.TextColumn{
		x 			= RIGHT_X,
		y 			= LINE_1_Y + TEXT_SPACING,
		x_align 	= 'right',
		append_end 	= ' %',
		text_color	= schema.purple,
		'<page_cache>',
		'<buffers>',
		'<kernel_slab>'
	},
}

local PLOT_Y = PLOT_SECTION_BREAK + HEADER_BOTTOM_Y + DIAL_RADIUS * 2

local plot = Widget.LabelPlot{
	x = CONSTRUCTION_GLOBAL.RIGHT_X,
	y = PLOT_Y,
	width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	height = PLOT_HEIGHT
}

local TABLE_Y = PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK

local tbl = Widget.Table{
	x = CONSTRUCTION_GLOBAL.RIGHT_X,
	y = TABLE_Y,
	width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	height = TABLE_HEIGHT,
	'Name',
	'PID',
	'Mem (%)'
}

DIAL_THETA0 = _MATH_RAD(DIAL_THETA0)
DIAL_THETA1 = _MATH_RAD(DIAL_THETA1)

local __update = function(cr)
	local MEM_TOTAL = MEM_TOTAL

	local round = util.round
	local precision_round_to_string = util.precision_round_to_string
	local glob = util.read_file('/proc/meminfo')	--kB

	--see source for "free" for formulas and stuff ;)

	local swap_free		= _STRING_MATCH(glob, 'SwapFree:%s+(%d+)' )
	local swap_total 	= _STRING_MATCH(glob, 'SwapTotal:%s+(%d+)')
	local page_cache 	= _STRING_MATCH(glob, 'Cached:%s+(%d+)'   )
	local slab 			= _STRING_MATCH(glob, 'Slab:%s+(%d+)'     )
	local buffers 		= _STRING_MATCH(glob, 'Buffers:%s+(%d+)'  )
	local free 			= _STRING_MATCH(glob, 'MemFree:%s+(%d+)'  )

	local used_percent = util.round((MEM_TOTAL - free - page_cache - buffers - slab) / MEM_TOTAL, 2)

	Dial.set(dial, used_percent)
	CriticalText.set(total_used, cr, used_percent * 100)

	local cache_theta = (DIAL_THETA0 - DIAL_THETA1) / MEM_TOTAL * free + DIAL_THETA1
	_CAIRO_PATH_DESTROY(cache_arc.path)
	cache_arc.path = Arc.create_path(DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)
	
	CriticalText.set(swap.percent, cr, precision_round_to_string((swap_total - swap_free) /	swap_total * 100))

	local percents = cache.percents
	TextColumn.set(percents, cr, 1, precision_round_to_string(page_cache / MEM_TOTAL * 100))
	TextColumn.set(percents, cr, 2, precision_round_to_string(buffers / MEM_TOTAL * 100))
	TextColumn.set(percents, cr, 3, precision_round_to_string(slab / MEM_TOTAL * 100))

	LabelPlot.update(plot, used_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, 5 do
			Table.set(tbl, cr, c, r, util.conky(column[r], '(%S+)'))
		end
	end
end

Widget = nil
schema = nil
MODULE_Y = nil
DIAL_THICKNESS = nil
DIAL_SPACING = nil
TEXT_Y_OFFSET = nil
TEXT_LEFT_X_OFFSET = nil
TEXT_SPACING = nil
PLOT_SECTION_BREAK = nil
PLOT_HEIGHT = nil
TABLE_SECTION_BREAK = nil
TABLE_HEIGHT = nil
HEADER_BOTTOM_Y = nil
LINE_1_Y = nil
TEXT_LEFT_X = nil
RIGHT_X = nil
PLOT_Y = nil
TABLE_Y = nil

local draw = function(cr, current_interface)
	__update(cr)

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
