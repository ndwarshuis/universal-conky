local Util		= require 'Util'
local Common	= require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56

   local __string_gmatch = string.gmatch
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

   local get_bits = function(path)
      return Util.read_file(path, nil, '*n') * 8
   end

   local interface_counters_tbl = {}

   local update = function(cr)
      local dspeed, uspeed = 0, 0

      local rx_delta, tx_delta

      -- iterate through the route file and filter on interfaces that are gateways (flag = 0003)
      local iterator = __string_gmatch(Util.read_file('/proc/net/route'),
                                       '(%w+)%s+%w+%s+%w+%s+0003%s+')

      for interface in iterator do
         local interface_counters = interface_counters_tbl[interface]

         if not interface_counters then
            local rx_path = '/sys/class/net/'..interface..'/statistics/rx_bytes'
            local tx_path = '/sys/class/net/'..interface..'/statistics/tx_bytes'

            interface_counters = {
               rx_path = rx_path,
               tx_path = tx_path,
               prev_rx_byte_cnt = get_bits(rx_path, nil, '*n'),
               prev_tx_byte_cnt = get_bits(tx_path, nil, '*n'),
            }
            interface_counters_tbl[interface] = interface_counters
         end

         local rx_byte_cnt = get_bits(interface_counters.rx_path, nil, '*n')
         local tx_byte_cnt = get_bits(interface_counters.tx_path, nil, '*n')

         rx_delta = rx_byte_cnt - interface_counters.prev_rx_byte_cnt
         tx_delta = tx_byte_cnt - interface_counters.prev_tx_byte_cnt

         interface_counters.prev_rx_byte_cnt = rx_byte_cnt
         interface_counters.prev_tx_byte_cnt = tx_byte_cnt

         -- mask overflow
         if rx_delta > 0 then dspeed = dspeed + rx_delta * update_freq end
         if tx_delta > 0 then uspeed = uspeed + tx_delta * update_freq end
      end

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
