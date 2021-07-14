local M = {}

local Util		= require 'Util'
local Common	= require 'Common'

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

local header = Common.Header(
	_G_INIT_DATA_.CENTER_RIGHT_X,
	_G_INIT_DATA_.TOP_Y,
	_G_INIT_DATA_.SECTION_WIDTH,
	'NETWORK'
)

local dnload = Common.initLabeledScalePlot(
      _G_INIT_DATA_.CENTER_RIGHT_X,
      header.bottom_y,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      value_format_function,
      network_label_function,
      _PLOT_SEC_BREAK_,
      'Download',
      2
)

local upload = Common.initLabeledScalePlot(
      _G_INIT_DATA_.CENTER_RIGHT_X,
      header.bottom_y + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2,
      _G_INIT_DATA_.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      value_format_function,
      network_label_function,
      _PLOT_SEC_BREAK_,
      'Upload',
      2
)

local interface_counters_tbl = {}

local get_bits = function(path)
   return Util.read_file(path, nil, '*n') * 8
end

local update = function(cr, update_frequency)
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
		if rx_delta > 0 then dspeed = dspeed + rx_delta * update_frequency end
		if tx_delta > 0 then uspeed = uspeed + tx_delta * update_frequency end
	end

	-- local dspeed_unit, dspeed_value = Util.convert_data_val(dspeed)
	-- local uspeed_unit, uspeed_value = Util.convert_data_val(uspeed)

    Common.annotated_scale_plot_set(
       dnload,
       cr,
       -- Util.precision_round_to_string(dspeed_value, 3)..' '..dspeed_unit..'b/s',
       dspeed
    )
    Common.annotated_scale_plot_set(
       upload,
       cr,
       -- Util.precision_round_to_string(uspeed_value, 3)..' '..uspeed_unit..'b/s',
       uspeed
    )
end

_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil

local draw_static = function(cr)
   Common.drawHeader(cr, header)
   Common.annotated_scale_plot_draw_static(dnload, cr)
   Common.annotated_scale_plot_draw_static(upload, cr)
end

local draw_dynamic = function(cr, update_frequency)
   update(cr, update_frequency)
   Common.annotated_scale_plot_draw_dynamic(dnload, cr)
   Common.annotated_scale_plot_draw_dynamic(upload, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
