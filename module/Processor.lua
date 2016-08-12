local Widget		= require 'Widget'
local Arc 			= require 'Arc'
local CompoundDial 	= require 'CompoundDial'
local CriticalText	= require 'CriticalText'
local TextColumn	= require 'TextColumn'
local Text			= require 'Text'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local util			= require 'util'
local schema		= require 'default_patterns'

local MODULE_Y = 375

local CPU_CONKY = {
	'${cpu cpu1}',
	'${cpu cpu2}',
	'${cpu cpu3}',
	'${cpu cpu4}',
}

local TABLE_CONKY = {{}, {}, {}}

for r = 1, 5 do
	TABLE_CONKY[1][r] = '${top name '..r..'}'
	TABLE_CONKY[2][r] = '${top pid '..r..'}'
	TABLE_CONKY[3][r] = '${top cpu '..r..'}'
end

--construction params
local DIAL_INNER_RADIUS = 28
local DIAL_OUTER_RADIUS = 48
local DIAL_SPACING = 1

local TEXT_Y_OFFSET = 15
local TEXT_LEFT_X_OFFSET = 25
local TEXT_SPACING = 20
local SEPARATOR_SPACING = 15
local PLOT_SECTION_BREAK = 20
local PLOT_HEIGHT = 56
local TABLE_SECTION_BREAK = 20
local TABLE_HEIGHT = 114

local header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.LEFT_X,
	y = MODULE_Y,
	width = CONSTRUCTION_GLOBAL.SIDE_WIDTH,
	header = "PROCESSOR"
}

local HEADER_BOTTOM_Y = header.bottom_y

local DIAL_X = CONSTRUCTION_GLOBAL.LEFT_X + DIAL_OUTER_RADIUS
local DIAL_Y = HEADER_BOTTOM_Y + DIAL_OUTER_RADIUS

local dials = Widget.CompoundDial{
	x 				= DIAL_X,
	y 				= DIAL_Y,			
	inner_radius 	= DIAL_INNER_RADIUS,
	outer_radius 	= DIAL_OUTER_RADIUS,
	spacing 		= DIAL_SPACING,
	num_dials 		= 4,
	critical_limit	= '>0.8'
}
local total_load = Widget.CriticalText{
	x 			= DIAL_X,
	y 			= DIAL_Y,
	x_align 	= 'center',
	y_align 	= 'center',
	append_end 	= '%'
}

local inner_ring = Widget.Arc{
	x = DIAL_X,
	y = DIAL_Y,
	radius = DIAL_INNER_RADIUS - 2,
	theta0 = 0,
	theta1 = 360
}

local LINE_1_Y = HEADER_BOTTOM_Y + TEXT_Y_OFFSET
local TEXT_LEFT_X = CONSTRUCTION_GLOBAL.LEFT_X + dials.width + TEXT_LEFT_X_OFFSET
local RIGHT_X = CONSTRUCTION_GLOBAL.LEFT_X + CONSTRUCTION_GLOBAL.SIDE_WIDTH

local core = {
	labels = Widget.TextColumn{
		x 		= TEXT_LEFT_X,
		y 		= LINE_1_Y,
		spacing = TEXT_SPACING,
		'Core 0',
		'Core 1'
	},
	temp1 = Widget.CriticalText{
		x 				= RIGHT_X,
		y 				= LINE_1_Y,
		x_align 		= 'right',
		append_end 		= '°C',
		critical_limit 	= '>86'
	},
	temp2 = Widget.CriticalText{
		x 			= RIGHT_X,
		y 			= LINE_1_Y + TEXT_SPACING,
		x_align 	= 'right',
		append_end 	= '°C',
		critical_limit 	= '>86'
	}
}

local SEP_Y = LINE_1_Y + TEXT_SPACING + SEPARATOR_SPACING

local separator = Widget.Line{
	p1 = {x = TEXT_LEFT_X, y = SEP_Y},
	p2 = {x = RIGHT_X, y = SEP_Y}
}

local PROCESS_Y = SEP_Y + SEPARATOR_SPACING

local process = {
	labels = Widget.TextColumn{
		x 		= TEXT_LEFT_X,
		y 		= PROCESS_Y,
		spacing = TEXT_SPACING,
		'R / S',
		'D / T / Z'
	},
	totals = Widget.TextColumn{
		x 			= RIGHT_X,
		y 			= PROCESS_Y,
		spacing 	= TEXT_SPACING,
		x_align 	= 'right',
		text_color 	= schema.blue,
		'<proc>',
		'<thread>'
	}
}

local PLOT_Y = PLOT_SECTION_BREAK + HEADER_BOTTOM_Y + dials.height

local plot = Widget.LabelPlot{
	x 		= CONSTRUCTION_GLOBAL.LEFT_X,
	y 		= PLOT_Y,
	width 	= CONSTRUCTION_GLOBAL.SIDE_WIDTH,
	height 	= PLOT_HEIGHT
}

local TABLE_Y = PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK

local tbl = Widget.Table{
	x 		= CONSTRUCTION_GLOBAL.LEFT_X,
	y 		= TABLE_Y,
	width 	= CONSTRUCTION_GLOBAL.SIDE_WIDTH,
	height 	= TABLE_HEIGHT,
	'Name',
	'PID',
	'CPU (%)'
}

local __update = function(cr)
	local conky = util.conky
	local char_count = util.char_count

	local sum = 0
	for i = 1, #CPU_CONKY do
		local percent = util.conky_numeric(CPU_CONKY[i]) * 0.01
		CompoundDial.set(dials, i, percent)
		sum = sum + percent
	end
	
	local load_percent = util.round(sum * 0.25, 2)
	CriticalText.set(total_load, cr, load_percent * 100)

	CriticalText.set(core.temp1, cr, util.round(0.001 * util.read_file(
		'/sys/class/thermal/thermal_zone0/temp', nil, '*n')))
	CriticalText.set(core.temp2, cr, util.round(0.001 * util.read_file(
		'/sys/class/thermal/thermal_zone1/temp', nil, '*n')))

	local process_glob = util.execute_cmd('ps -A -o s')
	
	local running 				= char_count(process_glob, 'R')
	local uninterrupted_sleep 	= char_count(process_glob, 'D')
	local interrupted_sleep 	= char_count(process_glob, 'S')
	local stopped 				= char_count(process_glob, 'T')
	local zombie 				= char_count(process_glob, 'Z')

	--subtract one b/c ps will always be "running"
	running = running - 1

	local totals = process.totals
	TextColumn.set(totals, cr, 1, running..' / '..interrupted_sleep)
	TextColumn.set(totals, cr, 2, uninterrupted_sleep..' / '..stopped..' / '..zombie)

	LabelPlot.update(plot, load_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, 5 do
			Table.set(tbl, cr, c, r, conky(column[r], '(%S+)'))
		end
	end
end

Widget = nil
schema = nil
MODULE_Y = nil
DIAL_INNER_RADIUS = nil
DIAL_OUTER_RADIUS = nil
DIAL_SPACING = nil
TEXT_Y_OFFSET = nil
TEXT_LEFT_X_OFFSET = nil
TEXT_SPACING = nil
SEPARATOR_SPACING = nil
PLOT_SECTION_BREAK = nil
PLOT_HEIGHT = nil
TABLE_SECTION_BREAK = nil
TABLE_HEIGHT = nil
HEADER_BOTTOM_Y = nil
DIAL_X = nil
DIAL_Y = nil
LINE_1_Y = nil
TEXT_LEFT_X = nil
RIGHT_X = nil
SEP_Y = nil
PROCESS_Y = nil
PLOT_Y = nil
TABLE_Y = nil

local draw = function(cr, current_interface)
	__update(cr)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		CompoundDial.draw(dials, cr)
		Arc.draw(inner_ring, cr)
		CriticalText.draw(total_load, cr)

		TextColumn.draw(core.labels, cr)
		CriticalText.draw(core.temp1, cr)
		CriticalText.draw(core.temp2, cr)

		Line.draw(separator, cr)

		TextColumn.draw(process.labels, cr)
		TextColumn.draw(process.totals, cr)

		LabelPlot.draw(plot, cr)

		Table.draw(tbl, cr)
	end
end

return draw
