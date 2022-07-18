local format = require 'format'
local pure = require 'pure'
local i_o = require 'i_o'
local sys = require 'sys'

return function(update_freq, common, width, point)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local INTERFACE_PATHS = sys.get_net_interface_paths()

   local get_bits = function(path)
      return i_o.read_file(path, nil, '*n') * 8
   end

   local mod_state = {rx_bits = 0, tx_bits = 0}

   local read_interfaces = function()
      mod_state.rx_bits = 0
      mod_state.tx_bits = 0
      for i = 1, #INTERFACE_PATHS do
         local p = INTERFACE_PATHS[i]
         mod_state.rx_bits = mod_state.rx_bits + get_bits(p.rx)
         mod_state.tx_bits = mod_state.tx_bits + get_bits(p.tx)
      end
   end

   -- prime initial state
   read_interfaces()

   local value_format_function = function(bits)
      local unit, value = format.convert_data_val(bits)
      return format.precision_round_to_string(value, 3)..' '..unit..'b/s'
   end

   -----------------------------------------------------------------------------
   -- down/up plots

   local mk_plot = function(label, key, y)
      local obj = common.make_rate_timeseries(
         point.x,
         y,
         width,
         PLOT_HEIGHT,
         value_format_function,
         common.converted_y_label_format_generator('b'),
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq,
         mod_state[key]
      )
      return common.mk_acc(
         width,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         function() common.update_rate_timeseries(obj, mod_state[key]) end,
         pure.partial(common.tagged_scaled_timeseries_draw_static, obj),
         pure.partial(common.tagged_scaled_timeseries_draw_dynamic, obj)
      )
   end

   local mk_rx = pure.partial(mk_plot, 'Download', 'rx_bits')
   local mk_tx = pure.partial(mk_plot, 'Upload', 'tx_bits')

   -----------------------------------------------------------------------------
   -- main drawing functions

   return {
      header = 'NETWORK',
      point = point,
      width = width,
      set_state = read_interfaces,
      top = {
         {mk_rx, true, PLOT_SEC_BREAK},
         {mk_tx, true, 0},
      }
   }
end
