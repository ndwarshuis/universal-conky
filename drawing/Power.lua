local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local MODULE_Y = 380
   local TEXT_SPACING = 20
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local PKG0_PATH = '/sys/class/powercap/intel-rapl:0/energy_uj'
   local DRAM_PATH = '/sys/class/powercap/intel-rapl:0:2/energy_uj'

   -----------------------------------------------------------------------------
   -- header

   local header = Common.Header(
      Geometry.RIGHT_X,
      MODULE_Y,
      Geometry.SECTION_WIDTH,
      'POWER'
   )

   -----------------------------------------------------------------------------
   -- package 0 power plot

   local power_label_function = function(watts) return watts..' W' end

   local power_format_function = function(watts)
      return Util.precision_round_to_string(watts, 3).." W"
   end

   local build_plot = function(y, label, format_fun)
      return Common.initLabeledScalePlot(
         Geometry.RIGHT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         format_fun,
         power_label_function,
         PLOT_SEC_BREAK,
         label,
         0,
         update_freq
      )
   end

   local pkg0 = build_plot(header.bottom_y, 'PKG0', power_format_function)

   -----------------------------------------------------------------------------
   -- DRAM power plot

   local CORE_Y = header.bottom_y + TEXT_SPACING + PLOT_SEC_BREAK + PLOT_HEIGHT

   local dram = build_plot(CORE_Y, 'DRAM', power_format_function)

   -----------------------------------------------------------------------------
   -- battery power plot

   local ac_format_function = function(watts)
      if watts == 0 then
         return "A/C"
      else
         return power_format_function(watts)
      end
   end

   local battery_draw = build_plot(
      CORE_Y + PLOT_SEC_BREAK * 2 + PLOT_HEIGHT,
      'Battery Draw',
      ac_format_function
   )

   -----------------------------------------------------------------------------
   -- update functions

   local read_uj = function(path)
      return Util.read_file(path, nil, '*n')
   end

   local prev_pkg0_uj_cnt = read_uj(PKG0_PATH)
   local prev_dram_uj_cnt = read_uj(DRAM_PATH)

   local calculate_power = function(prev_cnt, cnt, update_frequency)
      if cnt > prev_cnt then
         return (cnt - prev_cnt) * update_frequency * 0.000001
      else
         return 0
      end
   end

   local update = function(cr, is_using_ac)
      local pkg0_uj_cnt = read_uj(PKG0_PATH)
      local dram_uj_cnt = read_uj(DRAM_PATH)

      local pkg0_power = calculate_power(prev_pkg0_uj_cnt, pkg0_uj_cnt, update_freq)

      Common.annotated_scale_plot_set(pkg0, cr, pkg0_power)

      local dram_power = calculate_power(prev_dram_uj_cnt, dram_uj_cnt, update_freq)

      Common.annotated_scale_plot_set(dram, cr, dram_power)

      prev_pkg0_uj_cnt = pkg0_uj_cnt
      prev_dram_uj_cnt = dram_uj_cnt

      if is_using_ac then
         Common.annotated_scale_plot_set(battery_draw, cr, 0)
      else
         local current = Util.read_file('/sys/class/power_supply/BAT0/current_now', nil, '*n')
         local voltage = Util.read_file('/sys/class/power_supply/BAT0/voltage_now', nil, '*n')
         local power = current * voltage * 0.000000000001
         Common.annotated_scale_plot_set(battery_draw, cr, power)
      end
   end

   -----------------------------------------------------------------------------
   -- main functions

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.annotated_scale_plot_draw_static(pkg0, cr)
      Common.annotated_scale_plot_draw_static(dram, cr)
      Common.annotated_scale_plot_draw_static(battery_draw, cr)
   end

   local draw_dynamic = function(cr, is_using_ac)
      update(cr, is_using_ac)
      Common.annotated_scale_plot_draw_dynamic(pkg0, cr)
      Common.annotated_scale_plot_draw_dynamic(dram, cr)
      Common.annotated_scale_plot_draw_dynamic(battery_draw, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
