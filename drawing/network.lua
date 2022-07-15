local format = require 'format'
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

   local read_interfaces = function()
      local rx = 0
      local tx = 0
      for i = 1, #INTERFACE_PATHS do
         local p = INTERFACE_PATHS[i]
         rx = rx + get_bits(p.rx)
         tx = tx + get_bits(p.tx)
      end
      return rx, tx
   end

   local init_rx_bits, init_tx_bits = read_interfaces()

   local value_format_function = function(bits)
      local unit, value = format.convert_data_val(bits)
      return format.precision_round_to_string(value, 3)..' '..unit..'b/s'
   end

   local make_plot = function(y, label, init)
      return common.make_rate_timeseries(
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
         init
      )
   end

   -----------------------------------------------------------------------------
   -- header

   local header = common.make_header(
      point.x,
      point.y,
      geometry.SECTION_WIDTH,
      'NETWORK'
   )

   -----------------------------------------------------------------------------
   -- download plot

   local rx = make_plot(header.bottom_y, 'Download', init_rx_bits)

   -----------------------------------------------------------------------------
   -- upload plot

   local TX_Y = header.bottom_y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2
   local tx = make_plot(TX_Y, 'Upload', init_tx_bits)

   -----------------------------------------------------------------------------
   -- main drawing functions

   local update = function()
      local rx_bits, tx_bits = read_interfaces()
      common.update_rate_timeseries(rx, rx_bits)
      common.update_rate_timeseries(tx, tx_bits)
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)
      common.tagged_scaled_timeseries_draw_static(rx, cr)
      common.tagged_scaled_timeseries_draw_static(tx, cr)
   end

   local draw_dynamic = function(cr)
      common.tagged_scaled_timeseries_draw_dynamic(rx, cr)
      common.tagged_scaled_timeseries_draw_dynamic(tx, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
