local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   -- TODO ensure these interfaces actually exist
   local INTERFACES = {'enp7s0f1', 'wlp0s20f3'}

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
         Common.converted_y_label_format_generator('b'),
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

   local compute_speed = function(x0, x1)
      -- mask overflow
      if x1 > x0 then
         return (x1 - x0) * update_freq
      else
         return 0
      end
   end

   local prev_rx_bits, prev_tx_bits = read_interfaces()

   local update = function(cr)
      local rx_bits, tx_bits = read_interfaces()
      Common.annotated_scale_plot_set(
         dnload,
         cr,
         compute_speed(prev_rx_bits, rx_bits)
      )
      Common.annotated_scale_plot_set(
         upload,
         cr,
         compute_speed(prev_tx_bits, tx_bits)
      )
      prev_rx_bits = rx_bits
      prev_tx_bits = tx_bits
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
