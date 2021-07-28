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
   local BAT_CURRENT_PATH = '/sys/class/power_supply/BAT0/current_now'
   local BAT_VOLTAGE_PATH = '/sys/class/power_supply/BAT0/voltage_now'

   local read_milli = function(path)
      return Util.read_file(path, nil, '*n') * 0.000001
   end

   local read_pkg0_joules = function()
      return read_milli(PKG0_PATH)
   end

   local read_dram_joules = function()
      return read_milli(DRAM_PATH)
   end

   local read_battery_current = function()
      return read_milli(BAT_CURRENT_PATH)
   end

   local read_battery_voltage = function()
      return read_milli(BAT_VOLTAGE_PATH)
   end

   local read_battery_power = function(is_using_ac)
      if is_using_ac then
         return 0
      else
         return read_battery_current() * read_battery_voltage()
      end
   end

   local power_label_function = function(plot_max)
      local fmt = Common.y_label_format_string(plot_max, 'W')
      return function(watts) return string.format(fmt, watts) end
   end

   local format_rapl = function(watts)
      return Util.precision_round_to_string(watts, 3)..' W'
   end

   local build_rate_plot = function(y, label, init)
      return Common.build_rate_timeseries(
         Geometry.RIGHT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         format_rapl,
         power_label_function,
         PLOT_SEC_BREAK,
         label,
         0,
         update_freq,
         init
      )
   end

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

   local pkg0 = build_rate_plot(header.bottom_y, 'PKG0', read_pkg0_joules())

   -----------------------------------------------------------------------------
   -- DRAM power plot

   local DRAM_Y = header.bottom_y + TEXT_SPACING + PLOT_SEC_BREAK + PLOT_HEIGHT
   local dram = build_rate_plot(DRAM_Y, 'DRAM', read_dram_joules())

   -----------------------------------------------------------------------------
   -- battery power plot

   local format_ac = function(watts)
      if watts == 0 then
         return "A/C"
      else
         return format_rapl(watts)
      end
   end

   local BAT_Y = DRAM_Y + PLOT_SEC_BREAK * 2 + PLOT_HEIGHT
   local bat = Common.initLabeledScalePlot(
      Geometry.RIGHT_X,
      BAT_Y,
      Geometry.SECTION_WIDTH,
      PLOT_HEIGHT,
      format_ac,
      power_label_function,
      PLOT_SEC_BREAK,
      'Battery Draw',
      0,
      update_freq
   )

   -----------------------------------------------------------------------------
   -- main functions

   local update = function(is_using_ac)
      Common.update_rate_timeseries(pkg0, read_pkg0_joules())
      Common.update_rate_timeseries(dram, read_dram_joules())
      Common.annotated_scale_plot_set(bat, read_battery_power(is_using_ac))
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.annotated_scale_plot_draw_static(pkg0, cr)
      Common.annotated_scale_plot_draw_static(dram, cr)
      Common.annotated_scale_plot_draw_static(bat, cr)
   end

   local draw_dynamic = function(cr)
      -- update(is_using_ac)
      Common.annotated_scale_plot_draw_dynamic(pkg0, cr)
      Common.annotated_scale_plot_draw_dynamic(dram, cr)
      Common.annotated_scale_plot_draw_dynamic(bat, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
