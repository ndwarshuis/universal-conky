local Util		= require 'Util'
local Common	= require 'Common'
local Geometry = require 'Geometry'

local __string_gmatch = string.gmatch
local __math_floor = math.floor

local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local network_label_function = function(bits)
	local new_unit, new_value = Util.convert_data_val(bits)
	return __math_floor(new_value)..' '..new_unit..'b/s'
end

local value_format_function = function(bits)
   local unit, value = Util.convert_data_val(bits)
   return Util.precision_round_to_string(value, 3)..' '..unit..'b/s'
end



local interface_counters_tbl = {}

local get_bits = function(path)
   return Util.read_file(path, nil, '*n') * 8
end

-- _PLOT_SEC_BREAK_ = nil
-- _PLOT_HEIGHT_ = nil

return function(update_freq)
   local header = Common.Header(
      Geometry.CENTER_RIGHT_X,
      Geometry.TOP_Y,
      Geometry.SECTION_WIDTH,
      'NETWORK'
   )

   local dnload = Common.initLabeledScalePlot(
      Geometry.CENTER_RIGHT_X,
      header.bottom_y,
      Geometry.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      value_format_function,
      network_label_function,
      _PLOT_SEC_BREAK_,
      'Download',
      2,
      update_freq
   )

   local upload = Common.initLabeledScalePlot(
      Geometry.CENTER_RIGHT_X,
      header.bottom_y + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2,
      Geometry.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      value_format_function,
      network_label_function,
      _PLOT_SEC_BREAK_,
      'Upload',
      2,
      update_freq
   )

   local _update = function(cr)
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

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.annotated_scale_plot_draw_static(dnload, cr)
      Common.annotated_scale_plot_draw_static(upload, cr)
   end

   local draw_dynamic = function(cr)
      _update(cr)
      Common.annotated_scale_plot_draw_dynamic(dnload, cr)
      Common.annotated_scale_plot_draw_dynamic(upload, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
