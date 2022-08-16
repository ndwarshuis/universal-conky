local format = require 'format'
local pure = require 'pure'
local sys = require 'sys'

return function(update_freq, config, common, width, point)
   local geo = config.geometry
   local TEXT_SPACING = geo.text_spacing
   local PLOT_SEC_BREAK = geo.plot.sec_break
   local PLOT_HEIGHT = geo.plot.height

   local power_label_function = function(plot_max)
      local fmt = common.y_label_format_string(plot_max, 'W')
      return function(watts) return string.format(fmt, watts) end
   end

   local format_rapl = function(watts)
      return format.precision_round_to_string(watts, 3)..' W'
   end

   local mk_static = function(obj)
      return pure.partial(common.tagged_scaled_timeseries_draw_static, obj)
   end

   local mk_dynamic = function(obj)
      return pure.partial(common.tagged_scaled_timeseries_draw_dynamic, obj)
   end

   local mk_rate_plot = function(label, address, y)
      local read_joules = sys.intel_powercap_reader(address)
      local obj = common.make_rate_timeseries(
         point.x,
         y,
         width,
         PLOT_HEIGHT,
         format_rapl,
         power_label_function,
         PLOT_SEC_BREAK,
         label,
         0,
         update_freq,
         read_joules()
      )
      return common.mk_acc(
         width,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         function(_) common.update_rate_timeseries(obj, read_joules()) end,
         mk_static(obj),
         mk_dynamic(obj)
      )
   end

   local mk_rate_blockspec = function(spec)
      local f = pure.partial(mk_rate_plot, spec.name, spec.address)
      return {f, true, TEXT_SPACING}
   end

   -----------------------------------------------------------------------------
   -- battery power plot


   local format_ac = function(watts)
      return watts == 0 and "A/C" or format_rapl(watts)
   end

   local mk_bat = function(y)
      local _read_battery_power = sys.battery_power_reader(config.battery)

      local read_battery_power = function(is_using_ac)
         return is_using_ac and 0 or _read_battery_power()
      end
      local read_bat_status = sys.battery_status_reader(config.battery)
      local obj = common.make_tagged_scaled_timeseries(
         point.x,
         y,
         width,
         PLOT_HEIGHT,
         format_ac,
         power_label_function,
         PLOT_SEC_BREAK,
         'Battery Draw',
         0,
         update_freq
      )
      return common.mk_acc(
         width,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         function()
            common.tagged_scaled_timeseries_set(
               obj,
               read_battery_power(read_bat_status())
            )
         end,
         mk_static(obj),
         mk_dynamic(obj)
      )
   end

   -----------------------------------------------------------------------------
   -- main functions

   return {
      header = 'POWER',
      point = point,
      width = width,
      set_state = nil,
      top = pure.concat(
         pure.map(mk_rate_blockspec, config.rapl_specs),
         {{mk_bat, config.battery ~= '', 0}}
      )
   }
end
