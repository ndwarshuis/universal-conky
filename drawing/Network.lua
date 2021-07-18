local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local INTERFACES = {'enp7s0f1', 'wlp0s20f3'}

   local __math_floor = math.floor

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

   local network_label_function = function(bits)
      local new_unit, new_value = Util.convert_data_val(bits)
      return __math_floor(new_value)..' '..new_unit..'b/s'
   end

   local value_format_function = function(bits)
      local unit, value = Util.convert_data_val(bits)
      return Util.precision_round_to_string(value, 3)..' '..unit..'b/s'
   end

   local build_plot = function(y, label)
      return Common.initLabeledScalePlot(
         Geometry.CENTER_RIGHT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         value_format_function,
         network_label_function,
         PLOT_SEC_BREAK,
         label,
         2,
         update_freq
      )
   end

   local dnload = build_plot(header.bottom_y, 'Download')

   -----------------------------------------------------------------------------
   -- upload plot

   local upload = build_plot(
      header.bottom_y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2,
      'Upload'
   )

   -----------------------------------------------------------------------------
   -- update function

   local INTERFACE_PATHS = {}
   for i = 1, #INTERFACES do
      local dir = string.format('/sys/class/net/%s/statistics/', INTERFACES[i])
      INTERFACE_PATHS[i] = {
         rx = dir..'rx_bytes',
         tx = dir..'tx_bytes',
      }
   end

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

   local prev_rx_bits, prev_tx_bits = read_interfaces()

   local update = function(cr)
      local dspeed, uspeed = 0, 0
      local rx_bits, tx_bits = read_interfaces()

      -- mask overflow
      if rx_bits > prev_rx_bits then
         dspeed = (rx_bits - prev_rx_bits) * update_freq
      end
      if tx_bits > prev_tx_bits then
         uspeed = (tx_bits - prev_tx_bits) * update_freq
      end
      prev_rx_bits = rx_bits
      prev_tx_bits = tx_bits

      Common.annotated_scale_plot_set(dnload, cr, dspeed)
      Common.annotated_scale_plot_set(upload, cr, uspeed)
   end

   -----------------------------------------------------------------------------
   -- main drawing functions

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.annotated_scale_plot_draw_static(dnload, cr)
      Common.annotated_scale_plot_draw_static(upload, cr)
   end

   local draw_dynamic = function(cr)
      update(cr)
      Common.annotated_scale_plot_draw_dynamic(dnload, cr)
      Common.annotated_scale_plot_draw_dynamic(upload, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
