local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local util			= require 'util'
local schema		= require 'default_patterns'

local _TEXT_SPACING_ = 20

local header = Widget.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _G_INIT_DATA_.TOP_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'PACMAN'
}

local labels = Widget.TextColumn{
	x 		= _G_INIT_DATA_.RIGHT_X,
	y 		= header.bottom_y,
	spacing = _TEXT_SPACING_,
	'Total',
	'Explicit',
	'Outdated',
	'Orphaned',
	'Local'
}
local info = Widget.TextColumn{
	x 			= _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH,
	y 			= header.bottom_y,
	spacing 	= _TEXT_SPACING_,
	x_align 	= 'right',
	text_color 	= schema.blue,
	num_rows 	= 5,
}

Widget = nil
schema = nil
_TEXT_SPACING_ = nil

local update = function(cr)
	local _execute_cmd = util.execute_cmd
	local _line_count = util.line_count

	TextColumn.set(info, cr, 1, _line_count(_execute_cmd('pacman -Q')))
	TextColumn.set(info, cr, 2, _line_count(_execute_cmd('pacman -Qe')))
	TextColumn.set(info, cr, 3, _line_count(_execute_cmd('pacman -Qu')))
	TextColumn.set(info, cr, 4, _line_count(_execute_cmd('pacman -Qdt')))
	TextColumn.set(info, cr, 5, _line_count(_execute_cmd('pacman -Qm')))
end

update(_CR)

_CR = nil

local draw = function(cr, current_interface, trigger)
	if trigger == 0 then update(cr) end
	
	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		TextColumn.draw(labels, cr)
		TextColumn.draw(info, cr)
	end
end

return draw
