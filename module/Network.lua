local Widget	= require 'Widget'
local Text		= require 'Text'
local Line		= require 'Line'
local ScalePlot = require 'ScalePlot'
local util		= require 'util'
local schema	= require 'default_patterns'

local _STRING_GMATCH = string.gmatch
local _IO_POPEN		= io.popen

--construction params
local PLOT_SEC_BREAK = 20
local PLOT_HEIGHT = 56

local SYSFS_NET = '/sys/class/net/'
local STATS_RX = '/statistics/rx_bytes'
local STATS_TX = '/statistics/tx_bytes'

local __network_label_function = function(bytes)
	local new_unit = util.get_unit(bytes)
	
	local converted = util.convert_bytes(bytes, 'B', new_unit)
	local precision = 0
	if converted < 10 then precision = 1 end
	
	return util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.CENTER_RIGHT_X,
	y = CONSTRUCTION_GLOBAL.TOP_Y,
	width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	header = "NETWORK"
}

local RIGHT_X = CONSTRUCTION_GLOBAL.CENTER_RIGHT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH
local DOWNLOAD_PLOT_Y = header.bottom_y + PLOT_SEC_BREAK

local dnload = {
	label = Widget.Text{
		x = CONSTRUCTION_GLOBAL.CENTER_RIGHT_X,
		y = header.bottom_y,
		text = 'Download',
	},
	speed = Widget.Text{
		x = RIGHT_X,
		y = header.bottom_y,
		x_align = 'right',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = CONSTRUCTION_GLOBAL.CENTER_RIGHT_X,
		y = DOWNLOAD_PLOT_Y,
		width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __network_label_function
	}
}

local UPLOAD_Y = DOWNLOAD_PLOT_Y + PLOT_HEIGHT + PLOT_SEC_BREAK
local UPLOAD_PLOT_Y = UPLOAD_Y + PLOT_SEC_BREAK

local upload = {
	label = Widget.Text{
		x = CONSTRUCTION_GLOBAL.CENTER_RIGHT_X,
		y = UPLOAD_Y,
		text = 'Upload',
	},
	speed = Widget.Text{
		x = RIGHT_X,
		y = UPLOAD_Y,
		x_align = 'right',
		text_color = schema.blue
	},
	plot = Widget.ScalePlot{
		x = CONSTRUCTION_GLOBAL.CENTER_RIGHT_X,
		y = UPLOAD_PLOT_Y,
		width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height = PLOT_HEIGHT,
		y_label_func = __network_label_function
	}
}

local interfaces = {}

local __add_interface = function(iface)
	local rx_path = SYSFS_NET..iface..STATS_RX
	local tx_path = SYSFS_NET..iface..STATS_TX

	interfaces[iface] = {
		rx_path = rx_path,
		tx_path = tx_path,
		rx_cumulative_bytes = 0,
		tx_cumulative_bytes = 0,
		prev_rx_cumulative_bytes = util.read_file(rx_path, nil, '*n'),
		prev_tx_cumulative_bytes = util.read_file(tx_path, nil, '*n'),
	}
end

for iface in _IO_POPEN('ls -1 '..SYSFS_NET):lines() do
	__add_interface(iface)
end

local __update = function(cr, update_frequency)
	local dspeed, uspeed = 0, 0
	local glob = util.execute_cmd('ip route show')

	local rx_bps, tx_bps

	for iface in _STRING_GMATCH(glob, 'default via %d+%.%d+%.%d+%.%d+ dev (%w+) ') do
		local current_iface = interfaces[iface]

		if not current_iface then
			__add_interface(iface)
			current_iface = interfaces[iface]
		end
		
		local new_rx_cumulative_bytes = util.read_file(current_iface.rx_path, nil, '*n')
		local new_tx_cumulative_bytes = util.read_file(current_iface.tx_path, nil, '*n')
		
		rx_bps = (new_rx_cumulative_bytes - current_iface.prev_rx_cumulative_bytes) * update_frequency
		tx_bps = (new_tx_cumulative_bytes - current_iface.prev_tx_cumulative_bytes) * update_frequency

		current_iface.prev_rx_cumulative_bytes = new_rx_cumulative_bytes
		current_iface.prev_tx_cumulative_bytes = new_tx_cumulative_bytes

		--mask overflow
		if rx_bps < 0 then rx_bps = 0 end
		if tx_bps < 0 then tx_bps = 0 end

		dspeed = dspeed + rx_bps
		uspeed = uspeed + tx_bps
	end

	local dspeed_unit = util.get_unit(dspeed)
	local uspeed_unit = util.get_unit(uspeed)
	
	dnload.speed.append_end = ' '..dspeed_unit..'/s'
	upload.speed.append_end = ' '..uspeed_unit..'/s'
	
	Text.set(dnload.speed, cr, util.precision_convert_bytes(dspeed, 'B', dspeed_unit, 3))
	Text.set(upload.speed, cr, util.precision_convert_bytes(uspeed, 'B', uspeed_unit, 3))
	
	ScalePlot.update(dnload.plot, cr, dspeed)
	ScalePlot.update(upload.plot, cr, uspeed)
end

Widget = nil
schema = nil
PLOT_SEC_BREAK = nil
PLOT_HEIGHT = nil
RIGHT_X = nil
DOWNLOAD_PLOT_Y = nil
UPLOAD_Y = nil
UPLOAD_PLOT_Y = nil

local draw = function(cr, current_interface, update_frequency)
	__update(cr, update_frequency)

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
