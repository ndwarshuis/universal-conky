local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local CriticalText 	= require 'CriticalText'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local util			= require 'util'
local schema		= require 'default_patterns'

local _STRING_FIND 		= string.find
local _STRING_MATCH 	= string.match
local _STRING_GMATCH 	= string.gmatch

local NUM_ROWS = 12

local USERNAME_FORMAT = '(%S+)%s+'
local START_TIME_FORMAT = '%S+%s+%S+%s+%S+%s+(%S+)%s+'

--construction params
local SPACING = 20
local SEPARATOR_SPACING = 17
local MODULE_Y = 285

local header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.RIGHT_X,
	y = MODULE_Y,
	width = CONSTRUCTION_GLOBAL.SIDE_WIDTH,
	header = 'REMOTE CONNECTIONS'
}

local FIREWALL_Y = header.bottom_y
local TUNNEL_Y = FIREWALL_Y + SEPARATOR_SPACING * 2
local SOCKS_Y = TUNNEL_Y + SPACING + SEPARATOR_SPACING * 2

local TABLE_Y = SOCKS_Y + SPACING + SEPARATOR_SPACING * 2
local TABLE_BODY_Y = TABLE_Y + SPACING + 6

local RIGHT_X = CONSTRUCTION_GLOBAL.RIGHT_X + CONSTRUCTION_GLOBAL.SIDE_WIDTH

local firewall = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.RIGHT_X,
		y 		= FIREWALL_Y,
		text 	= 'Firewall Status',
	},
	info = Widget.CriticalText{
		x 			= RIGHT_X,
		y 			= FIREWALL_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
	}
}

local tunnel = {
	labels = Widget.TextColumn{
		x 		= CONSTRUCTION_GLOBAL.RIGHT_X,
		y 		= TUNNEL_Y,
		spacing = SPACING,
		'Tunnel Loaded',
		'Tunnel Running',
	},
	info = Widget.TextColumn{
		x 			= RIGHT_X,
		y 			= TUNNEL_Y,
		spacing 	= SPACING,
		x_align 	= 'right',
		text_color 	= schema.blue,
		num_rows 	= 2,
	}
}

local socks = {
	labels = Widget.TextColumn{
		x 		= CONSTRUCTION_GLOBAL.RIGHT_X,
		y 		= SOCKS_Y,
		spacing = SPACING,
		'Socks Loaded',
		'Socks Running',
	},
	info = Widget.TextColumn{
		x 			= RIGHT_X,
		y 			= SOCKS_Y,
		spacing 	= SPACING,
		x_align 	= 'right',
		text_color 	= schema.blue,
		num_rows 	= 2,
	}
}

local tbl = {
	headers = {
		Widget.Text{
			x = CONSTRUCTION_GLOBAL.RIGHT_X,
			y = TABLE_Y,
			text = 'Username',
			text_color = schema.blue
		},
		Widget.Text{
			x = RIGHT_X,
			y = TABLE_Y,
			text = 'Date / Time',
			text_color = schema.blue,
			x_align = 'right'
		}
	},
	columns = {
		Widget.TextColumn{
			x = CONSTRUCTION_GLOBAL.RIGHT_X,
			y = TABLE_BODY_Y,
			spacing = SPACING,
			num_rows = NUM_ROWS,
			font_size = 10,
			max_length = 9
		},
		Widget.TextColumn{
			x = RIGHT_X,
			y = TABLE_BODY_Y,
			spacing = SPACING,
			num_rows = NUM_ROWS,
			font_size = 10,
			x_align = 'right',
		}
	}
}

local separators = {
	Widget.Line{
		p1 = {
			x = CONSTRUCTION_GLOBAL.RIGHT_X,
			y = TUNNEL_Y - SEPARATOR_SPACING
		},
		p2 = {
			x = RIGHT_X,
			y = TUNNEL_Y - SEPARATOR_SPACING
		}
	},
	Widget.Line{
		p1 = {
			x = CONSTRUCTION_GLOBAL.RIGHT_X,
			y = SOCKS_Y - SEPARATOR_SPACING
		},
		p2 = {
			x = RIGHT_X,
			y = SOCKS_Y - SEPARATOR_SPACING
		}
	},
	Widget.Line{
		p1 = {
			x = CONSTRUCTION_GLOBAL.RIGHT_X,
			y = TABLE_Y - SEPARATOR_SPACING
		},
		p2 = {
			x = RIGHT_X,
			y = TABLE_Y - SEPARATOR_SPACING
		}
	}
}

local __set_ssh_status = function(status, obj, cr)
	TextColumn.set(obj, cr, 1, _STRING_MATCH(status, '/autossh') and 'Yes' or 'No')
	TextColumn.set(obj, cr, 2, _STRING_MATCH(status, '/ssh') and 'Yes' or 'No')
end

local __parse_log_line = function(log_line)
	if not log_line then return end
	
	local username = _STRING_MATCH(log_line, USERNAME_FORMAT)
	local start_date = _STRING_MATCH(log_line, START_TIME_FORMAT)

	local start_time_unix = util.execute_cmd('date --date="'..start_date..'" +"%s"', nil, '*n')

	local start_time_formatted = util.execute_cmd(
	  'date --date="'..start_date..'" +"%-m-%-d-%y (%H:%M)"', '(.+)\n')

	if _STRING_FIND(log_line, 'still logged in', 1, true) then
		return username, start_time_unix, '*!* '..start_time_formatted..' *!*'
	else
		return username, start_time_unix, start_time_formatted
	end
end

local __update = function(cr)
	__set_ssh_status(util.execute_cmd('systemctl status tunnel'), tunnel.info, cr)
	__set_ssh_status(util.execute_cmd('systemctl status socks'), socks.info, cr)

	if util.execute_cmd('systemctl is-active ufw') == 'active\n' then
		CriticalText.set(firewall.info, cr, 'Up', 1)
	else
		CriticalText.set(firewall.info, cr, 'Down', 0)
	end

	local next_wtmp = _STRING_GMATCH(util.execute_cmd(
	  "last -iw --time-format iso | grep -v '0.0.0.0' | head -n -2"), '[^\n]+')
	  
	local next_btmp = _STRING_GMATCH(util.execute_cmd(
	  "lastb -iw --time-format iso | grep -v '0.0.0.0' | head -n -2"), '[^\n]+')

	local wtmp_username, wtmp_time, wtmp_str = __parse_log_line(next_wtmp())
	local btmp_username, btmp_time, btmp_str = __parse_log_line(next_btmp())

	local column1 = tbl.columns[1]
	local column2 = tbl.columns[2]

	for r = 1, NUM_ROWS do
		if wtmp_time and btmp_time then
			if wtmp_time > btmp_time then
				TextColumn.set(column1, cr, r, wtmp_username)
				TextColumn.set(column2, cr, r, wtmp_str)
				wtmp_username, wtmp_time, wtmp_str = __parse_log_line(next_wtmp())
			else
				TextColumn.set(column1, cr, r, '*'..btmp_username)
				TextColumn.set(column2, cr, r, btmp_str)
				btmp_username, btmp_time, btmp_str = __parse_log_line(next_btmp())
			end
		elseif wtmp_time then
			TextColumn.set(column1, cr, r, wtmp_username)
			TextColumn.set(column2, cr, r, wtmp_str)
			wtmp_username, wtmp_time, wtmp_str = __parse_log_line(next_wtmp())
		elseif btmp_time then
			TextColumn.set(column1, cr, r, '*'..btmp_username)
			TextColumn.set(column2, cr, r, btmp_str)
			btmp_username, btmp_time, btmp_str = __parse_log_line(next_btmp())
		else
			TextColumn.set(column1, cr, r, '--')
			TextColumn.set(column2, cr, r, '--')
		end
	end
end

__update(_CR)

Widget = nil
schema = nil
SPACING = nil
SEPARATOR_SPACING = nil
MODULE_Y = nil
RIGHT_X = nil
TUNNEL_Y = nil
SOCKS_Y = nil
FIREWALL_Y = nil
TABLE_Y = nil
TABLE_BODY_Y = nil
_CR = nil

local draw = function(cr, current_interface, trigger)
	if trigger == 0 then __update(cr) end

	if current_interface == 1 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		
		TextColumn.draw(tunnel.labels, cr)
		TextColumn.draw(tunnel.info, cr)

		Line.draw(separators[1], cr)
		
		TextColumn.draw(socks.labels, cr)
		TextColumn.draw(socks.info, cr)

		Line.draw(separators[2], cr)
		
		Text.draw(firewall.label, cr)
		CriticalText.draw(firewall.info, cr)

		Line.draw(separators[3], cr)

		local headers = tbl.headers

		Text.draw(headers[1], cr)
		Text.draw(headers[2], cr)

		local column1 = tbl.columns[1]
		local column2 = tbl.columns[2]

		TextColumn.draw(column1, cr)
		TextColumn.draw(column2, cr)
	end
end

return draw
