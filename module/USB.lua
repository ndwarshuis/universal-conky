local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local ScalePlot		= require 'ScalePlot'
local util			= require 'util'
local schema		= require 'default_patterns'

local _STRING_MATCH 	= string.match
local _STRING_GMATCH 	= string.gmatch
local _STRING_GSUB		= string.gsub
local _TONUMBER			= tonumber
local _OS_EXECUTE		= os.execute
local _IO_OPEN			= io.open

local USB_IO_PATH = '/tmp/usbdump.txt'
local USBDUMP_CMD = 'timeout 2 usbdump > '..USB_IO_PATH..' &'
local RIGHT_USB_PCI = '/sys/devices/pci0000:00/0000:00:1c.4/0000:0b:00.0/'
local LEFT_USB_PCI = '/sys/devices/pci0000:00/0000:00:1d.0/'

local FIND_RIGHT_PORTS = 'find '..RIGHT_USB_PCI..'usb[1-4]/[1-4]-[1,2] -maxdepth 0 -type d 2> /dev/null'
local FIND_PORT_3 = 'find '..LEFT_USB_PCI..'usb[1-4]/[1-4]-1/[1-4]-1.2 -maxdepth 0 -type d 2> /dev/null'
local FIND_SD_SLOT = 'find '..LEFT_USB_PCI..'usb[1-4]/[1-4]-1/[1-4]-1.6 -maxdepth 0 -type d 2> /dev/null'

local N_COLUMNS = 3
local N_ROWS = 4

local STATUS_PCI_UNLOADED = 'No PCI Module'
local STATUS_USBMON_UNLOADED = 'Usbmon Unloaded'

--construction params
local SPACING = 20
local PLOT_SEC_BREAK = 20
local PLOT_HEIGHT = 56
local SECTION_PAD = 5
local DEVICE_HEIGHT = (PLOT_HEIGHT + PLOT_SEC_BREAK + SPACING) * 2 + SPACING + SECTION_PAD + 10

local __usb_label_function = function(bytes)
	local new_unit = util.get_unit(bytes)
	local converted = util.convert_bytes(bytes, 'B', new_unit)

	local precision = 0
	if converted < 10 then precision = 1 end
	
	return util.round_to_string(converted, precision)..' '..new_unit..'/s'
end

local __create_io_plot = function(x_offset, y_offset, label)
	local obj = {
		label = Widget.Text{
			x = x_offset,
			y = y_offset,
			text = label
		},
		speed = Widget.Text{
			x = x_offset + CONSTRUCTION_GLOBAL.SIDE_WIDTH,
			y = y_offset,
			x_align = 'right',
			text_color = schema.blue
		},
		plot = Widget.ScalePlot{
			x = x_offset,
			y = y_offset + PLOT_SEC_BREAK,
			width = CONSTRUCTION_GLOBAL.SIDE_WIDTH,
			height = PLOT_HEIGHT,
			y_label_func = __usb_label_function
		},
	}

	return obj
end

local __create_device_display = function(x_offset, y_offset, title)
	local INPUT_Y = y_offset + SPACING + SECTION_PAD
	local OUTPUT_Y = INPUT_Y + SPACING + PLOT_HEIGHT + PLOT_SEC_BREAK
	
	local obj = {
		title = Widget.Text{
			x = x_offset,
			y = y_offset,
			text = title,
			text_color = schema.blue
		},
		link_speed = Widget.Text{
			x = x_offset + CONSTRUCTION_GLOBAL.SIDE_WIDTH,
			y = y_offset,
			x_align = 'right',
			text_color = schema.blue
		},
		idata = __create_io_plot(x_offset, INPUT_Y, 'Input'),
		odata = __create_io_plot(x_offset, OUTPUT_Y, 'Output'),
	}

	return obj
end

local usb = {
	header = Widget.Header{
		x = CONSTRUCTION_GLOBAL.LEFT_X,
		y = CONSTRUCTION_GLOBAL.TOP_Y,
		width = CONSTRUCTION_GLOBAL.SIDE_WIDTH,
		header = 'USB PORTS'
	}
}

local HEADER_BOTTOM_Y = usb.header.bottom_y

usb[1] = __create_device_display(CONSTRUCTION_GLOBAL.LEFT_X, HEADER_BOTTOM_Y, 'PORT 1')
usb[2] = __create_device_display(CONSTRUCTION_GLOBAL.LEFT_X, HEADER_BOTTOM_Y + DEVICE_HEIGHT, 'PORT 2')
usb[3] = __create_device_display(CONSTRUCTION_GLOBAL.LEFT_X, HEADER_BOTTOM_Y + DEVICE_HEIGHT * 2, 'PORT 3')

local usbtop = {
	header = Widget.Header{
		x = CONSTRUCTION_GLOBAL.CENTER_X,
		y = CONSTRUCTION_GLOBAL.TOP_Y,
		width = CONSTRUCTION_GLOBAL.CENTER_WIDTH,
		header = 'USB DEVICES'
	},
	columns = {},
	separators = {}
}

HEADER_BOTTOM_Y = usbtop.header.bottom_y

local HEADERS = {'Port / Slot',	'Device', 'Total I / O'}
local COLUMN_WIDTHS = {150, 323, 150}

local current_x = CONSTRUCTION_GLOBAL.CENTER_X
local columns = usbtop.columns

for i = 1, N_COLUMNS do
	local column_x = current_x + 0.5 * COLUMN_WIDTHS[i]

	columns[i] = {
		header = Widget.Text{
			x = column_x,
			y = HEADER_BOTTOM_Y,
			x_align = 'center',
			text = HEADERS[i],
			text_color = schema.blue
		},
		column = Widget.TextColumn{
			x = column_x,
			y = HEADER_BOTTOM_Y + SPACING + 6,
			x_align = 'center',
			spacing = SPACING,
			num_rows = N_ROWS,
			font_size = 10,
			max_length = 30
		}
	}
	current_x = current_x + COLUMN_WIDTHS[i]
end

current_x = CONSTRUCTION_GLOBAL.CENTER_X
local separators = usbtop.separators

for i = 1, N_COLUMNS - 1 do
	current_x = current_x + COLUMN_WIDTHS[i]
	separators[i] = Widget.Line{
		p1 = {
			x = current_x,
			y = HEADER_BOTTOM_Y
		},
		p2 = {
			x = current_x,
			y = HEADER_BOTTOM_Y + N_ROWS * SPACING + 6
		},
	}
end

HEADERS = nil
COLUMN_WIDTHS = nil

current_x = nil
columns = nil
separators = nil

local card_slot = {
	header = Widget.Header{
		x = CONSTRUCTION_GLOBAL.RIGHT_X,
		y = CONSTRUCTION_GLOBAL.TOP_Y,
		width = CONSTRUCTION_GLOBAL.SIDE_WIDTH,
		header = "SD CARD SLOT"
	}
}

HEADER_BOTTOM_Y = card_slot.header.bottom_y

card_slot.port = __create_device_display(CONSTRUCTION_GLOBAL.RIGHT_X, HEADER_BOTTOM_Y, 'Status')

Widget = nil
schema = nil

SPACING = nil
PLOT_SEC_BREAK = nil
PLOT_HEIGHT = nil
SECTION_PAD = nil
DEVICE_HEIGHT = nil
HEADER_BOTTOM_Y = nil

local USBTOP_LIST = {}

local __draw_device = function(device, cr)
	Text.draw(device.title, cr)
	Text.draw(device.link_speed, cr)
	
	local device_plot = device.idata

	Text.draw(device_plot.label, cr)
	Text.draw(device_plot.speed, cr)
	ScalePlot.draw(device_plot.plot, cr)
	
	local device_plot = device.odata
	
	Text.draw(device_plot.label, cr)
	Text.draw(device_plot.speed, cr)
	ScalePlot.draw(device_plot.plot, cr)
end

local __populate_active_port = function(port, cr, data_glob, bus_num, path, name)
	Text.set(port.link_speed, cr, util.read_file(path..'/speed', nil, '*n') * 0.125 ..' MiB/s')

	local idata_sum = 0
	local odata_sum = 0

	for devnum_path in _STRING_GMATCH(util.execute_cmd('find '..path..' -name devnum'), '(.-)\n') do

		local devnum = util.read_file(devnum_path, nil, '*n')
		local idata, odata = _STRING_MATCH(data_glob, devnum..':'..bus_num..':(%d+):(%d+)')

		if idata and odata then
			idata_sum = idata_sum + _TONUMBER(idata)
			odata_sum = odata_sum + _TONUMBER(odata)
			
			local io_sum = idata + odata
			local io_sum_unit = util.get_unit(io_sum)

			USBTOP_LIST[#USBTOP_LIST + 1] = {
				name = name,
				device = util.read_file(_STRING_GSUB(devnum_path, 'devnum$', 'product'), '(.-)\n'),
				io_sum_numeric = io_sum,
				io_sum = util.precision_convert_bytes(io_sum, 'B', io_sum_unit, 3)..' '..io_sum_unit..'/s',
				path = devnum_path
			}
		end
	end

	local iunit = util.get_unit(idata_sum)
	local ounit = util.get_unit(odata_sum)

	Text.set(port.idata.speed, cr, util.precision_convert_bytes(idata_sum, 'B', iunit, 3)..' '..iunit..'/s')
	Text.set(port.odata.speed, cr, util.precision_convert_bytes(odata_sum, 'B', ounit, 3)..' '..ounit..'/s')

	ScalePlot.update(port.idata.plot, cr, idata_sum)
	ScalePlot.update(port.odata.plot, cr, odata_sum)
end

local __populate_inactive_port = function(port, cr, msg)
	Text.set(port.link_speed, cr, msg)
	Text.set(port.idata.speed, cr, '--')
	Text.set(port.odata.speed, cr, '--')
	ScalePlot.update(port.idata.plot, cr, 0)
	ScalePlot.update(port.odata.plot, cr, 0)
end

local __get_power_status = function(pci_path)
	if util.read_file(util.execute_cmd('find '..pci_path..
	  'usb[1-4]/power/runtime_status -print -quit 2> /dev/null', '(.-)\n')) == 'active\n' then
		return 'Disconnected'
	else
		return 'Suspended'
	end
end

local __update = function(cr)
	_OS_EXECUTE("killall -q usbdump")

	for i = 1, #USBTOP_LIST do USBTOP_LIST[i] = nil end
	
	local data_glob = util.read_file(USB_IO_PATH)

	if _IO_OPEN('/sys/module/usbmon/') then
		_OS_EXECUTE(USBDUMP_CMD)
		if _IO_OPEN('/sys/module/xhci_pci/') then
			--right ports
			local port_1_bus, port_2_bus
			
			local right_glob = util.execute_cmd(FIND_RIGHT_PORTS)

			for path in _STRING_GMATCH(right_glob, '(.-)\n') do
				local bus_num, port_num = _STRING_MATCH(path, '.-(%d)-(%d)')

				if port_num == '1' then
					port_1_bus = bus_num
					__populate_active_port(usb[1], cr, data_glob, bus_num, path, 'Port 1')
				elseif port_num == '2' then
					port_2_bus = bus_num
					__populate_active_port(usb[2], cr, data_glob, bus_num, path, 'Port 2')
				end
			end

			if not (port_1_bus and port_2_bus) then
				local power_status = __get_power_status(RIGHT_USB_PCI)
				
				if not port_1_bus then __populate_inactive_port(usb[1], cr, power_status) end
				if not port_2_bus then __populate_inactive_port(usb[2], cr, power_status) end
			end
		else
			__populate_inactive_port(usb[1], cr, STATUS_PCI_UNLOADED)
			__populate_inactive_port(usb[2], cr, STATUS_PCI_UNLOADED)
		end

		if _IO_OPEN('/sys/module/ehci_pci/') then
			--left port
			local left_path = util.execute_cmd(FIND_PORT_3, '(.-)\n')

			local left_hub_power_status

			if left_path == '' then
				left_hub_power_status = __get_power_status(LEFT_USB_PCI)
				__populate_inactive_port(usb[3], cr, left_hub_power_status)
			else
				__populate_active_port(usb[3], cr, data_glob,
				   _STRING_MATCH(left_path, 'usb(%d)'), left_path, 'Port 3')
			end

			--sd port
			local sd_path = util.execute_cmd(FIND_SD_SLOT, '(.-)\n')

			if sd_path == '' then
				__populate_inactive_port(card_slot.port, cr, left_hub_power_status or
				  __get_power_status(LEFT_USB_PCI))
			else
				__populate_active_port(card_slot.port, cr, data_glob,
				  _STRING_MATCH(sd_path, 'usb(%d)'), sd_path, 'SD Slot')
			end
		else
			__populate_inactive_port(usb[3], cr, STATUS_PCI_UNLOADED)
			__populate_inactive_port(card_slot.port, cr, STATUS_PCI_UNLOADED)
		end
	else
		__populate_inactive_port(usb[1], cr, STATUS_USBMON_UNLOADED)
		__populate_inactive_port(usb[2], cr, STATUS_USBMON_UNLOADED)
		__populate_inactive_port(usb[3], cr, STATUS_USBMON_UNLOADED)
		__populate_inactive_port(card_slot.port, cr, STATUS_USBMON_UNLOADED)
	end

	local list_len = #USBTOP_LIST

	--sort usbtop_list (selection sort)
	if list_len > 1 then
		for i = 1, list_len do
			local iMax = i
			for j = i + 1, list_len do
				if USBTOP_LIST[j].io_sum_numeric > USBTOP_LIST[iMax].io_sum_numeric then
					iMax = j
				end
			end
			if iMax ~= i then
				local tmp = USBTOP_LIST[i]
				USBTOP_LIST[i] = USBTOP_LIST[iMax]
				USBTOP_LIST[iMax] = tmp
			end
		end
	end

	local columns = usbtop.columns

	for i = 1, N_ROWS do
		local current_entry = USBTOP_LIST[i]

		if current_entry then
			TextColumn.set(columns[1].column, cr, i, current_entry.name)
			TextColumn.set(columns[2].column, cr, i, current_entry.device)
			TextColumn.set(columns[3].column, cr, i, current_entry.io_sum)
		else
			TextColumn.set(columns[1].column, cr, i, '--')
			TextColumn.set(columns[2].column, cr, i, '--')
			TextColumn.set(columns[3].column, cr, i, '--')
		end
	end
end

_OS_EXECUTE(USBDUMP_CMD)

local draw = function(cr, interface, trigger)
	__update(cr)

	if interface == 1 then
		Text.draw(usb.header.text, cr)
		Line.draw(usb.header.underline, cr)
		
		__draw_device(usb[1], cr)
		__draw_device(usb[2], cr)
		__draw_device(usb[3], cr)

		Text.draw(card_slot.header.text, cr)
		Line.draw(card_slot.header.underline, cr)
		
		__draw_device(card_slot.port, cr)

		Text.draw(usbtop.header.text, cr)
		Line.draw(usbtop.header.underline, cr)

		local columns = usbtop.columns
		local separators = usbtop.separators

		for i = 1, N_COLUMNS do
			local column = columns[i]
			Text.draw(column.header, cr)
			TextColumn.draw(column.column, cr)
		end

		for i = 1, N_COLUMNS - 1 do
			Line.draw(separators[i], cr)
		end
	end
end

return draw
