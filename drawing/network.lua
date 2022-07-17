local format = require 'format'
local pure = require 'pure'
local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'
local sys = require 'sys'

return function(update_freq, point)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local INTERFACE_PATHS = sys.get_net_interface_paths()

   local get_bits = function(path)
      return i_o.read_file(path, nil, '*n') * 8
   end

   local state = {rx_bits = 0, tx_bits = 0}

   local read_interfaces = function()
      state.rx_bits = 0
      state.tx_bits = 0
      for i = 1, #INTERFACE_PATHS do
         local p = INTERFACE_PATHS[i]
         state.rx_bits = state.rx_bits + get_bits(p.rx)
         state.tx_bits = state.tx_bits + get_bits(p.tx)
      end
      return state
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
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         value_format_function,
         common.converted_y_label_format_generator('b'),
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq,
         state[key]
      )
      return common.mk_acc(
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         function(s) common.update_rate_timeseries(obj, s[key]) end,
         pure.partial(common.tagged_scaled_timeseries_draw_static, obj),
         pure.partial(common.tagged_scaled_timeseries_draw_dynamic, obj)
      )
   end

   local mk_rx = pure.partial(mk_plot, 'Download', 'rx_bits')
   local mk_tx = pure.partial(mk_plot, 'Upload', 'tx_bits')

   -----------------------------------------------------------------------------
   -- main drawing functions

   local rbs = common.reduce_blocks_(
      'NETWORK',
      point,
      geometry.SECTION_WIDTH,
      {
         {mk_rx, true, PLOT_SEC_BREAK},
         {mk_tx, true, 0},
      }
   )

   return pure.map_at("update", function(f) return function(_) f(read_interfaces()) end end, rbs)
end
