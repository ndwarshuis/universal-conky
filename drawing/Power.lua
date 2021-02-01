local M = {}

local Patterns      = require 'Patterns'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local ScalePlot 	= require 'ScalePlot'
local Util			= require 'Util'

local _MODULE_Y_ = 320
local _TEXT_SPACING_ = 20
local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 73

local power_label_function = function(watts) return watts..' W' end

local calculate_power = function(cr, prev_cnt, cnt, update_frequency)
	if cnt > prev_cnt then
		return (cnt - prev_cnt) * update_frequency * 0.000001
	else
		return 0
	end
end

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'POWER'
}

local _RIGHT_X_ = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local pkg0 = {
   label = _G_Widget_.Text{
	  x 	= _G_INIT_DATA_.RIGHT_X,
	  y 	= header.bottom_y,
	  text = 'PKG0',
   },
   value = _G_Widget_.Text{
	  x 			= _RIGHT_X_,
	  y 			= header.bottom_y,
	  x_align 	= 'right',
	  text_color  = Patterns.BLUE,
	  text        = '<core>',
	  append_end	= ' W',
   },
   plot = _G_Widget_.ScalePlot{
	  x = _G_INIT_DATA_.RIGHT_X,
	  y = header.bottom_y + _PLOT_SEC_BREAK_,
	  width = _G_INIT_DATA_.SECTION_WIDTH,
	  height = _PLOT_HEIGHT_,
	  y_label_func = power_label_function,
      num_y_intrvl = 5,
   },
}

local _CORE_Y_ = header.bottom_y + _TEXT_SPACING_ + _PLOT_SEC_BREAK_ + _PLOT_HEIGHT_

local dram = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _CORE_Y_,
		text    = 'DRAM'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _CORE_Y_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.BLUE,
		text        = '<dram>',
		append_end	= ' W'
	},
	plot = _G_Widget_.ScalePlot{
		x = _G_INIT_DATA_.RIGHT_X,
		y = _CORE_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = power_label_function,
        num_y_intrvl = 5,
	}
}

local _BATTERY_DRAW_Y_ = _CORE_Y_ + _PLOT_SEC_BREAK_ * 2 + _PLOT_HEIGHT_

local battery_draw = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.RIGHT_X,
		y 		= _BATTERY_DRAW_Y_,
		spacing = _TEXT_SPACING_,
		text	= 'Battery Draw'
	},
	value = _G_Widget_.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _BATTERY_DRAW_Y_,
		x_align 	= 'right',
	},
	plot = _G_Widget_.ScalePlot{
		x = _G_INIT_DATA_.RIGHT_X,
		y = _BATTERY_DRAW_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = power_label_function,
        num_y_intrvl = 5,
	}
}

local PKG0_PATH = '/sys/class/powercap/intel-rapl:0/energy_uj'
local DRAM_PATH = '/sys/class/powercap/intel-rapl:0:2/energy_uj'

local prev_pkg0_uj_cnt = Util.read_file(PKG0_PATH, nil, '*n')
local prev_dram_uj_cnt = Util.read_file(DRAM_PATH, nil, '*n')

local update = function(cr, update_frequency, is_using_ac)
	local pkg0_uj_cnt = Util.read_file(PKG0_PATH, nil, '*n')
	local dram_uj_cnt = Util.read_file(DRAM_PATH, nil, '*n')
	
	local pkg0_power = calculate_power(cr, prev_pkg0_uj_cnt, pkg0_uj_cnt, update_frequency)

	Text.set(pkg0.value, cr, Util.precision_round_to_string(pkg0_power, 3))
	
	ScalePlot.update(pkg0.plot, cr, pkg0_power)

	local dram_power = calculate_power(cr, prev_dram_uj_cnt, dram_uj_cnt, update_frequency)
	
	Text.set(dram.value, cr, Util.precision_round_to_string(dram_power, 3))
	ScalePlot.update(dram.plot, cr, dram_power)

	prev_pkg0_uj_cnt = pkg0_uj_cnt
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

Patterns = nil
_MODULE_Y_ = nil
_TEXT_SPACING_ = nil
_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_RIGHT_X_ = nil
_CORE_Y_ = nil
_BATTERY_DRAW_Y_ = nil

local draw_static = function(cr)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)

   Text.draw(pkg0.label, cr)

   Text.draw(dram.label, cr)
   Text.draw(battery_draw.label, cr)
end

local draw_dynamic = function(cr, update_frequency, is_using_ac)
   update(cr, update_frequency, is_using_ac)

   Text.draw(pkg0.value, cr)
   ScalePlot.draw_dynamic(pkg0.plot, cr)
		
   Text.draw(dram.value, cr)
   ScalePlot.draw_dynamic(dram.plot, cr)

   Text.draw(battery_draw.value, cr)
   ScalePlot.draw_dynamic(battery_draw.plot, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
