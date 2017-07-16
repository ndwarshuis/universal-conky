local Widget		= require 'Widget'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local ScalePlot 	= require 'ScalePlot'
local util			= require 'util'
local schema		= require 'default_patterns'

local _STRING_MATCH = string.match
local _MATH_RAD		= math.rad

--construction params
local MODULE_Y = 328
local SEPARATOR_SPACING = 20
local TEXT_SPACING = 20
local PLOT_SEC_BREAK = 20
local PLOT_HEIGHT = 56

local __power_label_function = function(watts)
	return watts..' W'
end

local __calculate_power = function(cr, prev_cnt, cnt, update_frequency)
	return cnt > prev_cnt and (cnt - prev_cnt) * update_frequency * 0.000001 or 0
end

local header = Widget.Header{
	x = G_DIMENSIONS_.RIGHT_X,
	y = MODULE_Y,
	width = G_DIMENSIONS_.SECTION_WIDTH,
	header = 'POWER'
}

local RIGHT_X = G_DIMENSIONS_.RIGHT_X + G_DIMENSIONS_.SECTION_WIDTH

local pp01 = {
	labels = Widget.TextColumn{
		x 		= G_DIMENSIONS_.RIGHT_X,
		y 		= header.bottom_y,
		spacing	= TEXT_SPACING,
		'Core',
		'iGPU'
	},
	values = Widget.TextColumn{
		x 			= RIGHT_X,
		y 			= header.bottom_y,
		spacing		= TEXT_SPACING,
		x_align 	= 'right',
		text_color 	= schema.blue,
		append_end 	= ' W',
		num_rows	= 2
	}
}

local SEP_Y = header.bottom_y + TEXT_SPACING + SEPARATOR_SPACING

local separator = Widget.Line{
	p1 = {x = G_DIMENSIONS_.RIGHT_X, y = SEP_Y},
	p2 = {x = RIGHT_X, y = SEP_Y}
}

local PKG0_Y = SEP_Y + SEPARATOR_SPACING

local pkg0 = {
	label = Widget.Text{
		x 		= G_DIMENSIONS_.RIGHT_X,
		y 		= PKG0_Y,
		text    = 'PKG 0'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= PKG0_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<pkg0>',
		append_end	= ' W'
	},
	plot = Widget.ScalePlot{
		x = G_DIMENSIONS_.RIGHT_X,
		y = PKG0_Y + PLOT_SEC_BREAK,
		width = G_DIMENSIONS_.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __power_label_function,
	}
}

local DRAM_Y = PKG0_Y + PLOT_SEC_BREAK * 2 + PLOT_HEIGHT

local dram = {
	label = Widget.Text{
		x 		= G_DIMENSIONS_.RIGHT_X,
		y 		= DRAM_Y,
		text    = 'DRAM'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= DRAM_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<dram>',
		append_end	= ' W'
	},
	plot = Widget.ScalePlot{
		x = G_DIMENSIONS_.RIGHT_X,
		y = DRAM_Y + PLOT_SEC_BREAK,
		width = G_DIMENSIONS_.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __power_label_function,
	}
}

local BATTERY_DRAW_Y = DRAM_Y + PLOT_SEC_BREAK * 2 + PLOT_HEIGHT

local battery_draw = {
	label = Widget.Text{
		x 		= G_DIMENSIONS_.RIGHT_X,
		y 		= BATTERY_DRAW_Y,
		spacing = TEXT_SPACING,
		text	= 'Battery Draw'
	},
	value = Widget.CriticalText{
		x 			= RIGHT_X,
		y 			= BATTERY_DRAW_Y,
		x_align 	= 'right',
	},
	plot = Widget.ScalePlot{
		x = G_DIMENSIONS_.RIGHT_X,
		y = BATTERY_DRAW_Y + PLOT_SEC_BREAK,
		width = G_DIMENSIONS_.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __power_label_function,
	}
}

local PKG0_PATH = '/sys/class/powercap/intel-rapl:0/energy_uj'
local CORE_PATH = '/sys/class/powercap/intel-rapl:0:0/energy_uj'
local IGPU_PATH = '/sys/class/powercap/intel-rapl:0:1/energy_uj'
local DRAM_PATH = '/sys/class/powercap/intel-rapl:0:2/energy_uj'

local PKG0_PREV_CNT = util.read_file(PKG0_PATH, nil, '*n')
local CORE_PREV_CNT = util.read_file(CORE_PATH, nil, '*n')
local IGPU_PREV_CNT = util.read_file(IGPU_PATH, nil, '*n')
local DRAM_PREV_CNT = util.read_file(DRAM_PATH, nil, '*n')

local __update = function(cr, update_frequency, ac_active)
	local pkg0_cnt = util.read_file(PKG0_PATH, nil, '*n')
	local core_cnt = util.read_file(CORE_PATH, nil, '*n')
	local igpu_cnt = util.read_file(IGPU_PATH, nil, '*n')
	local dram_cnt = util.read_file(DRAM_PATH, nil, '*n')

	TextColumn.set(pp01.values, cr, 1, util.precision_round_to_string(
		__calculate_power(cr, CORE_PREV_CNT, core_cnt, update_frequency), 3))

	TextColumn.set(pp01.values, cr, 2, util.precision_round_to_string(
		__calculate_power(cr, IGPU_PREV_CNT, igpu_cnt, update_frequency), 3))

	local pkg0_power = __calculate_power(cr, PKG0_PREV_CNT, pkg0_cnt, update_frequency)
	local dram_power = __calculate_power(cr, DRAM_PREV_CNT, dram_cnt, update_frequency)

	Text.set(pkg0.value, cr, util.precision_round_to_string(pkg0_power, 3))
	ScalePlot.update(pkg0.plot, cr, pkg0_power)

	Text.set(dram.value, cr, util.precision_round_to_string(dram_power, 3))
	ScalePlot.update(dram.plot, cr, dram_power)

	PKG0_PREV_CNT = pkg0_cnt
	CORE_PREV_CNT = core_cnt
	IGPU_PREV_CNT = igpu_cnt
	DRAM_PREV_CNT = dram_cnt

	if ac_active then
		Text.set(battery_draw.value, cr, 'A / C')
		ScalePlot.update(battery_draw.plot, cr, 0)
	else
		local current = util.read_file('/sys/class/power_supply/BAT0/current_now', nil, '*n')
		local voltage = util.read_file('/sys/class/power_supply/BAT0/voltage_now', nil, '*n')
		local power = current * voltage * 0.000000000001

		Text.set(battery_draw.value, cr, util.precision_round_to_string(power, 3)..' W')
		ScalePlot.update(battery_draw.plot, cr, power)
	end
end

local draw = function(cr, current_interface, update_frequency, ac_active)
	__update(cr, update_frequency, ac_active)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)

		TextColumn.draw(pp01.labels, cr)
		TextColumn.draw(pp01.values, cr)

		Line.draw(separator, cr)
		
		Text.draw(pkg0.label, cr)
		Text.draw(pkg0.value, cr)
		ScalePlot.draw(pkg0.plot, cr)
		
		Text.draw(dram.label, cr)
		Text.draw(dram.value, cr)
		ScalePlot.draw(dram.plot, cr)

		Text.draw(battery_draw.label, cr)
		Text.draw(battery_draw.value, cr)
		ScalePlot.draw(battery_draw.plot, cr)
	end
end

return draw
