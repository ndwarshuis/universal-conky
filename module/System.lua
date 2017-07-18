local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local util			= require 'util'
local schema		= require 'default_patterns'

local __string_match = string.match

local _TEXT_SPACING_ = 20

local extract_date = function(cmd)
	local yyyy, mm_dd = __string_match(util.execute_cmd(cmd), '%[(%d-)%-(%d-%-%d-)%s')
	return mm_dd..'-'..yyyy
end

local header = Widget.Header{
	x = _G_INIT_DATA_.LEFT_X,
	y = _G_INIT_DATA_.TOP_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'SYSTEM'
}

local labels = Widget.TextColumn{
	x 		= _G_INIT_DATA_.LEFT_X,
	y 		= header.bottom_y,
	spacing = _TEXT_SPACING_,
	'Kernel',
	'Uptime',
	'Last Upgrade',
	'Last Sync'
}
local info = Widget.TextColumn{
	x 			= _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH,
	y 			= header.bottom_y,
	spacing 	= _TEXT_SPACING_,
	x_align 	= 'right',
	text_color 	= schema.blue,
	util.conky('$kernel'),
	'<row2>',
	'<row3>',
	'<row4>'
}

Widget = nil
schema = nil
_TEXT_SPACING_ = nil

local draw = function(cr, current_interface, log_is_changed)
	TextColumn.set(info, cr, 2, util.conky('$uptime'))
	
	if log_is_changed then
		TextColumn.set(info, cr, 3, extract_date("sed -n "..
		  "'/ starting full system upgrade/p' /var/log/pacman.log | tail -1"))
		TextColumn.set(info, cr, 4, extract_date("sed -n "..
		  "'/ synchronizing package lists/p' /var/log/pacman.log | tail -1"))
	end

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		TextColumn.draw(labels, cr)
		TextColumn.draw(info, cr)
	end
end

return draw
