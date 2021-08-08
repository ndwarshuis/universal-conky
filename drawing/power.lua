local format = require 'format'
-- local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'
local sys = require 'sys'

return function(update_freq, battery)
   local MODULE_Y = 380
   local TEXT_SPACING = 20
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local read_pkg0_joules = sys.intel_powercap_reader('intel-rapl:0')
   local read_dram_joules = sys.intel_powercap_reader('intel-rapl:0:2')

   local _read_battery_power = sys.battery_power_reader(battery)

   local read_battery_power = function(is_using_ac)
      if is_using_ac then
         return 0
      else
         return _read_battery_power()
      end
   end

   local power_label_function = function(plot_max)
      local fmt = common.y_label_format_string(plot_max, 'W')
      return function(watts) return string.format(fmt, watts) end
   end

   local format_rapl = function(watts)
      return format.precision_round_to_string(watts, 3)..' W'
   end

   local make_rate_plot = function(y, label, init)
      return common.make_rate_timeseries(
         geometry.RIGHT_X,
         y,
         geometry.SECTION_WIDTH,
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

   local header = common.make_header(
      geometry.RIGHT_X,
      MODULE_Y,
      geometry.SECTION_WIDTH,
      'POWER'
   )

   -----------------------------------------------------------------------------
   -- package 0 power plot

   local pkg0 = make_rate_plot(header.bottom_y, 'PKG0', read_pkg0_joules())

   -----------------------------------------------------------------------------
   -- DRAM power plot

   local DRAM_Y = header.bottom_y + TEXT_SPACING + PLOT_SEC_BREAK + PLOT_HEIGHT
   local dram = make_rate_plot(DRAM_Y, 'DRAM', read_dram_joules())

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
   local bat = common.make_tagged_scaled_timeseries(
      geometry.RIGHT_X,
      BAT_Y,
      geometry.SECTION_WIDTH,
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
      common.update_rate_timeseries(pkg0, read_pkg0_joules())
      common.update_rate_timeseries(dram, read_dram_joules())
      common.tagged_scaled_timeseries_set(bat, read_battery_power(is_using_ac))
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)
      common.tagged_scaled_timeseries_draw_static(pkg0, cr)
      common.tagged_scaled_timeseries_draw_static(dram, cr)
      common.tagged_scaled_timeseries_draw_static(bat, cr)
   end

   local draw_dynamic = function(cr)
      common.tagged_scaled_timeseries_draw_dynamic(pkg0, cr)
      common.tagged_scaled_timeseries_draw_dynamic(dram, cr)
      common.tagged_scaled_timeseries_draw_dynamic(bat, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
