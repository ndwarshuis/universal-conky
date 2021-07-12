local M = {}

local Util			= require 'Util'
local Common		= require 'Common'

local _MODULE_Y_ = 380
local _TEXT_SPACING_ = 20
local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local power_label_function = function(watts) return watts..' W' end

local calculate_power = function(prev_cnt, cnt, update_frequency)
	if cnt > prev_cnt then
		return (cnt - prev_cnt) * update_frequency * 0.000001
	else
		return 0
	end
end

local power_format_function = function(watts)
   return Util.precision_round_to_string(watts, 3).." W"
end

local ac_format_function = function(watts)
   if watts == 0 then
      return "A/C"
   else
      return power_format_function(watts)
   end
end

local header = Common.Header(
	_G_INIT_DATA_.RIGHT_X,
	_MODULE_Y_,
	_G_INIT_DATA_.SECTION_WIDTH,
	'POWER'
)

local pkg0 = Common.initLabeledScalePlot(
      _G_INIT_DATA_.RIGHT_X,
      header.bottom_y,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      power_format_function,
      power_label_function,
      _PLOT_SEC_BREAK_,
      'PKG0'
)

local _CORE_Y_ = header.bottom_y + _TEXT_SPACING_ + _PLOT_SEC_BREAK_ + _PLOT_HEIGHT_

local dram = Common.initLabeledScalePlot(
      _G_INIT_DATA_.RIGHT_X,
      _CORE_Y_,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      power_format_function,
      power_label_function,
      _PLOT_SEC_BREAK_,
      'DRAM'
)
dram.value.append_end = ' W'

local battery_draw = Common.initLabeledScalePlot(
      _G_INIT_DATA_.RIGHT_X,
      _CORE_Y_ + _PLOT_SEC_BREAK_ * 2 + _PLOT_HEIGHT_,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      ac_format_function,
      power_label_function,
      _PLOT_SEC_BREAK_,
      'Battery Draw'
)

local PKG0_PATH = '/sys/class/powercap/intel-rapl:0/energy_uj'
local DRAM_PATH = '/sys/class/powercap/intel-rapl:0:2/energy_uj'

local prev_pkg0_uj_cnt = Util.read_file(PKG0_PATH, nil, '*n')
local prev_dram_uj_cnt = Util.read_file(DRAM_PATH, nil, '*n')

local update = function(cr, update_frequency, is_using_ac)
   local pkg0_uj_cnt = Util.read_file(PKG0_PATH, nil, '*n')
   local dram_uj_cnt = Util.read_file(DRAM_PATH, nil, '*n')

   local pkg0_power = calculate_power(prev_pkg0_uj_cnt, pkg0_uj_cnt, update_frequency)

   -- Common.annotated_scale_plot_set(pkg0, cr, Util.precision_round_to_string(pkg0_power, 3), pkg0_power)
   Common.annotated_scale_plot_set(pkg0, cr, pkg0_power)

   local dram_power = calculate_power(prev_dram_uj_cnt, dram_uj_cnt, update_frequency)

   -- Common.annotated_scale_plot_set(dram, cr, Util.precision_round_to_string(dram_power, 3), dram_power)
   Common.annotated_scale_plot_set(dram, cr, dram_power)

   prev_pkg0_uj_cnt = pkg0_uj_cnt
   prev_dram_uj_cnt = dram_uj_cnt

   if is_using_ac then
      -- Common.annotated_scale_plot_set(battery_draw, cr, 'A/C', 0)
      Common.annotated_scale_plot_set(battery_draw, cr, 0)
   else
      local current = Util.read_file('/sys/class/power_supply/BAT0/current_now', nil, '*n')
      local voltage = Util.read_file('/sys/class/power_supply/BAT0/voltage_now', nil, '*n')
      local power = current * voltage * 0.000000000001
      -- local t = Util.precision_round_to_string(power, 3)..' W'
      -- Common.annotated_scale_plot_set(battery_draw, cr, t, power)
      Common.annotated_scale_plot_set(battery_draw, cr, power)
   end
end

_MODULE_Y_ = nil
_TEXT_SPACING_ = nil
_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_CORE_Y_ = nil

M.draw_static = function(cr)
   Common.drawHeader(cr, header)
   Common.annotated_scale_plot_draw_static(pkg0, cr)
   Common.annotated_scale_plot_draw_static(dram, cr)
   Common.annotated_scale_plot_draw_static(battery_draw, cr)
end

M.draw_dynamic = function(cr, update_frequency, is_using_ac)
   update(cr, update_frequency, is_using_ac)
   Common.annotated_scale_plot_draw_dynamic(pkg0, cr)
   Common.annotated_scale_plot_draw_dynamic(dram, cr)
   Common.annotated_scale_plot_draw_dynamic(battery_draw, cr)
end

return M
