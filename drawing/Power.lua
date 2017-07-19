local Widget		= require 'Widget'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local ScalePlot 	= require 'ScalePlot'
local Util			= require 'Util'
local Patterns		= require 'Patterns'

local _MODULE_Y_ = 328
local _SEPARATOR_SPACING_ = 20
local _TEXT_SPACING_ = 20
local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local power_label_function = function(watts) return watts..' W' end

local calculate_power = function(cr, prev_cnt, cnt, update_frequency)
	if cnt > prev_cnt then
		return (cnt - prev_cnt) * update_frequency * 0.000001
	else
		return 0
	end
end

local header = Widget.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'POWER'
}

local _RIGHT_X_ = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local pp01 = {
	labels = Widget.TextColumn{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= header.bottom_y,
		spacing	= _TEXT_SPACING_,
		'Core',
		'iGPU'
	},
	values = Widget.TextColumn{
		x 			= _RIGHT_X_,
		y 			= header.bottom_y,
		spacing		= _TEXT_SPACING_,
		x_align 	= 'right',
		text_color 	= Patterns.BLUE,
		append_end 	= ' W',
		num_rows	= 2
	}
}

local _SEP_Y_ = header.bottom_y + _TEXT_SPACING_ + _SEPARATOR_SPACING_

local separator = Widget.Line{
	p1 = {x = _G_INIT_DATA_.RIGHT_X, y = _SEP_Y_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_}
}

local _PKG0_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local pkg0 = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _PKG0_Y_,
		text    = 'PKG 0'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _PKG0_Y_,
		x_align 	= 'right',
		text_color 	= Patterns.BLUE,
		text        = '<pkg0>',
		append_end	= ' W'
	},
	plot = Widget.ScalePlot{
		x = _G_INIT_DATA_.RIGHT_X,
		y = _PKG0_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = power_label_function,
	}
}

local _DRAM_Y_ = _PKG0_Y_ + _PLOT_SEC_BREAK_ * 2 + _PLOT_HEIGHT_

local dram = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _DRAM_Y_,
		text    = 'DRAM'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _DRAM_Y_,
		x_align 	= 'right',
		text_color 	= Patterns.BLUE,
		text        = '<dram>',
		append_end	= ' W'
	},
	plot = Widget.ScalePlot{
		x = _G_INIT_DATA_.RIGHT_X,
		y = _DRAM_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = power_label_function,
	}
}

local _BATTERY_DRAW_Y_ = _DRAM_Y_ + _PLOT_SEC_BREAK_ * 2 + _PLOT_HEIGHT_

local battery_draw = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _BATTERY_DRAW_Y_,
		spacing = _TEXT_SPACING_,
		text	= 'Battery Draw'
	},
	value = Widget.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _BATTERY_DRAW_Y_,
		x_align 	= 'right',
	},
	plot = Widget.ScalePlot{
		x = _G_INIT_DATA_.RIGHT_X,
		y = _BATTERY_DRAW_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = power_label_function,
	}
}

local PKG0_PATH = '/sys/class/powercap/intel-rapl:0/energy_uj'
local CORE_PATH = '/sys/class/powercap/intel-rapl:0:0/energy_uj'
local IGPU_PATH = '/sys/class/powercap/intel-rapl:0:1/energy_uj'
local DRAM_PATH = '/sys/class/powercap/intel-rapl:0:2/energy_uj'

local prev_pkg0_uj_cnt = Util.read_file(PKG0_PATH, nil, '*n')
local prev_core_uj_cnt = Util.read_file(CORE_PATH, nil, '*n')
local prev_igpu_uj_cnt = Util.read_file(IGPU_PATH, nil, '*n')
local prev_dram_uj_cnt = Util.read_file(DRAM_PATH, nil, '*n')

local update = function(cr, update_frequency, is_using_ac)
	local pkg0_uj_cnt = Util.read_file(PKG0_PATH, nil, '*n')
	local core_uj_cnt = Util.read_file(CORE_PATH, nil, '*n')
	local igpu_uj_cnt = Util.read_file(IGPU_PATH, nil, '*n')
	local dram_uj_cnt = Util.read_file(DRAM_PATH, nil, '*n')

	TextColumn.set(pp01.values, cr, 1, Util.precision_round_to_string(
		calculate_power(cr, prev_core_uj_cnt, core_uj_cnt, update_frequency), 3))

	TextColumn.set(pp01.values, cr, 2, Util.precision_round_to_string(
		calculate_power(cr, prev_igpu_uj_cnt, igpu_uj_cnt, update_frequency), 3))

	local pkg0_power = calculate_power(cr, prev_pkg0_uj_cnt, pkg0_uj_cnt, update_frequency)
	local dram_power = calculate_power(cr, prev_dram_uj_cnt, dram_uj_cnt, update_frequency)

	Text.set(pkg0.value, cr, Util.precision_round_to_string(pkg0_power, 3))
	ScalePlot.update(pkg0.plot, cr, pkg0_power)

	Text.set(dram.value, cr, Util.precision_round_to_string(dram_power, 3))
	ScalePlot.update(dram.plot, cr, dram_power)

	prev_pkg0_uj_cnt = pkg0_uj_cnt
	prev_core_uj_cnt = core_uj_cnt
	prev_igpu_uj_cnt = igpu_uj_cnt
	prev_dram_uj_cnt = dram_uj_cnt

	if is_using_ac then
		Text.set(battery_draw.value, cr, 'A/C')
		ScalePlot.update(battery_draw.plot, cr, 0)
	else
		local current = Util.read_file('/sys/class/power_supply/BAT0/current_now', nil, '*n')
		local voltage = Util.read_file('/sys/class/power_supply/BAT0/voltage_now', nil, '*n')
		local power = current * voltage * 0.000000000001

		Text.set(battery_draw.value, cr, Util.precision_round_to_string(power, 3)..' W')
		ScalePlot.update(battery_draw.plot, cr, power)
	end
end

Widget = nil
Patterns = nil
_MODULE_Y_ = nil
_SEPARATOR_SPACING_ = nil
_TEXT_SPACING_ = nil
_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_RIGHT_X_ = nil
_SEP_Y_ = nil
_PKG0_Y_ = nil
_DRAM_Y_ = nil
_BATTERY_DRAW_Y_ = nil

local draw = function(cr, current_interface, update_frequency, is_using_ac)
	update(cr, update_frequency, is_using_ac)

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
