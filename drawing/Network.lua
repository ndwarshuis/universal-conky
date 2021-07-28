local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'
local func = require 'func'

return function(update_freq)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56

   local get_interfaces = function()
      local s = Util.execute_cmd('realpath /sys/class/net/* | grep -v virtual')
      local interfaces = {}
      for iface in string.gmatch(s, '/([^/\n]+)\n') do
         interfaces[#interfaces + 1] = iface
      end
      return interfaces
   end

   local INTERFACES = get_interfaces()

   local INTERFACE_PATHS = func.map(
      function(s)
         local dir = string.format('/sys/class/net/%s/statistics/', s)
         return {rx = dir..'rx_bytes', tx = dir..'tx_bytes'}
      end,
      INTERFACES
   )

   local get_bits = function(path)
      return Util.read_file(path, nil, '*n') * 8
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
      local unit, value = Util.convert_data_val(bits)
      return Util.precision_round_to_string(value, 3)..' '..unit..'b/s'
   end

   local build_plot = function(y, label, init)
      return Common.build_rate_timeseries(
         Geometry.CENTER_RIGHT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         value_format_function,
         Common.converted_y_label_format_generator('b'),
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq,
         init
      )
   end

   -----------------------------------------------------------------------------
   -- header

   local header = Common.Header(
      Geometry.CENTER_RIGHT_X,
      Geometry.TOP_Y,
      Geometry.SECTION_WIDTH,
      'NETWORK'
   )

   -----------------------------------------------------------------------------
   -- download plot

   local rx = build_plot(header.bottom_y, 'Download', init_rx_bits)

   -----------------------------------------------------------------------------
   -- upload plot

   local TX_Y = header.bottom_y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2
   local tx = build_plot(TX_Y, 'Upload', init_tx_bits)

   -----------------------------------------------------------------------------
   -- main drawing functions

   local update = function()
      local rx_bits, tx_bits = read_interfaces()
      Common.update_rate_timeseries(rx, rx_bits)
      Common.update_rate_timeseries(tx, tx_bits)
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.annotated_scale_plot_draw_static(rx, cr)
      Common.annotated_scale_plot_draw_static(tx, cr)
   end

   local draw_dynamic = function(cr)
      -- update()
      Common.annotated_scale_plot_draw_dynamic(rx, cr)
      Common.annotated_scale_plot_draw_dynamic(tx, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
