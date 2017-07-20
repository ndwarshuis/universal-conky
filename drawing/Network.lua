local Text		= require 'Text'
local Line		= require 'Line'
local ScalePlot = require 'ScalePlot'
local Util		= require 'Util'

local __string_gmatch = string.gmatch

local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local network_label_function = function(bytes)
	local new_unit = Util.get_unit(bytes)
	
	local converted = Util.convert_bytes(bytes, 'B', new_unit)
	local precision = 0
	if converted < 10 then precision = 1 end
	
	return Util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.CENTER_RIGHT_X,
	y = _G_INIT_DATA_.TOP_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'NETWORK'
}

local _RIGHT_X_ = _G_INIT_DATA_.CENTER_RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local dnload = {
	label = _G_Widget_.Text{
		x = _G_INIT_DATA_.CENTER_RIGHT_X,
		y = header.bottom_y,
		text = 'Download',
	},
	speed = _G_Widget_.Text{
		x = _RIGHT_X_,
		y = header.bottom_y,
		x_align = 'right',
		text_color = _G_Patterns_.BLUE
	},
	plot = _G_Widget_.ScalePlot{
		x = _G_INIT_DATA_.CENTER_RIGHT_X,
		y = header.bottom_y + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = network_label_function
	}
}

local _UPLOAD_Y_ = header.bottom_y + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local upload = {
	label = _G_Widget_.Text{
		x = _G_INIT_DATA_.CENTER_RIGHT_X,
		y = _UPLOAD_Y_,
		text = 'Upload',
	},
	speed = _G_Widget_.Text{
		x = _RIGHT_X_,
		y = _UPLOAD_Y_,
		x_align = 'right',
		text_color = _G_Patterns_.BLUE
	},
	plot = _G_Widget_.ScalePlot{
		x = _G_INIT_DATA_.CENTER_RIGHT_X,
		y = _UPLOAD_Y_ + _PLOT_SEC_BREAK_,
		width = _G_INIT_DATA_.SECTION_WIDTH,
		height = _PLOT_HEIGHT_,
		y_label_func = network_label_function
	}
}

local interface_counters_tbl = {}

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
				prev_rx_byte_cnt = Util.read_file(rx_path, nil, '*n'),
				prev_tx_byte_cnt = Util.read_file(tx_path, nil, '*n'),
			}
			interface_counters_tbl[interface] = interface_counters
		end
		
		local rx_byte_cnt = Util.read_file(interface_counters.rx_path, nil, '*n')
		local tx_byte_cnt = Util.read_file(interface_counters.tx_path, nil, '*n')
		
		rx_delta = rx_byte_cnt - interface_counters.prev_rx_byte_cnt
		tx_delta = tx_byte_cnt - interface_counters.prev_tx_byte_cnt

		interface_counters.prev_rx_byte_cnt = rx_byte_cnt
		interface_counters.prev_tx_byte_cnt = tx_byte_cnt

		-- mask overflow
		if rx_delta > 0 then dspeed = dspeed + rx_delta * update_frequency end
		if tx_delta > 0 then uspeed = uspeed + tx_delta * update_frequency end
	end

	local dspeed_unit = Util.get_unit(dspeed)
	local uspeed_unit = Util.get_unit(uspeed)
	
	dnload.speed.append_end = ' '..dspeed_unit..'/s'
	upload.speed.append_end = ' '..uspeed_unit..'/s'
	
	Text.set(dnload.speed, cr, Util.precision_convert_bytes(dspeed, 'B', dspeed_unit, 3))
	Text.set(upload.speed, cr, Util.precision_convert_bytes(uspeed, 'B', uspeed_unit, 3))
	
	ScalePlot.update(dnload.plot, cr, dspeed)
	ScalePlot.update(upload.plot, cr, uspeed)
end

_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_RIGHT_X_ = nil
_UPLOAD_Y_ = nil

local draw = function(cr, current_interface, update_frequency)
	update(cr, update_frequency)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		
		Text.draw(dnload.label, cr)
		Text.draw(dnload.speed, cr)
		ScalePlot.draw(dnload.plot, cr)
		
		Text.draw(upload.label, cr)
		Text.draw(upload.speed, cr)
		ScalePlot.draw(upload.plot, cr)
	end
end

return draw
