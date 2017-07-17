local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local util			= require 'util'
local schema		= require 'default_patterns'

local __string_match = string.match

local DATE_REGEX = '%[(%d-)%-(%d-%-%d-)%s'

local UPGRADE_CMD = "sed -n '/ starting full system upgrade/p' /var/log/pacman.log | tail -1"
local SYNC_CMD = "sed -n '/ synchronizing package lists/p' /var/log/pacman.log | tail -1"

local _TEXT_SPACING_ = 20

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
	num_rows 	= 4,
}

TextColumn.set(info, _CR, 1, util.conky('$kernel'))

local update_dates = function(cr)
	local yyyy, mm_dd = __string_match(util.execute_cmd(UPGRADE_CMD), DATE_REGEX)
	TextColumn.set(info, cr, 3, mm_dd..'-'..yyyy)
	
	yyyy, mm_dd = __string_match(util.execute_cmd(SYNC_CMD), DATE_REGEX)
	TextColumn.set(info, cr, 4, mm_dd..'-'..yyyy)
end

local update_uptime = function(cr)
	TextColumn.set(info, cr, 2, util.conky('$uptime'))
end

update_dates(_CR)

Widget = nil
schema = nil
_TEXT_SPACING_ = nil
_CR = nil

local draw = function(cr, current_interface, trigger)
	update_uptime(cr)
	if trigger == 0 then update_dates(cr) end

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		TextColumn.draw(labels, cr)
		TextColumn.draw(info, cr)
	end
end

return draw
