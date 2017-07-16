local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local util			= require 'util'
local schema		= require 'default_patterns'

--construction params
local TEXT_SPACING = 20

local header = Widget.Header{
	x = G_DIMENSIONS_.RIGHT_X,
	y = G_DIMENSIONS_.TOP_Y,
	width = G_DIMENSIONS_.SECTION_WIDTH,
	header = "PACMAN"
}

local labels = Widget.TextColumn{
	x 		= G_DIMENSIONS_.RIGHT_X,
	y 		= header.bottom_y,
	spacing = TEXT_SPACING,
	'Total',
	'Explicit',
	'Outdated',
	'Orphaned',
	'Local'
}
local info = Widget.TextColumn{
	x 			= G_DIMENSIONS_.RIGHT_X + G_DIMENSIONS_.SECTION_WIDTH,
	y 			= header.bottom_y,
	spacing 	= TEXT_SPACING,
	x_align 	= 'right',
	text_color 	= schema.blue,
	num_rows 	= 5,
}

Widget = nil
schema = nil
TEXT_SPACING = nil

local __update = function(cr)
	local execute_cmd = util.execute_cmd
	local line_count = util.line_count

	TextColumn.set(info, cr, 1, line_count(execute_cmd('pacman -Q')))
	TextColumn.set(info, cr, 2, line_count(execute_cmd('pacman -Qe')))
	TextColumn.set(info, cr, 3, line_count(execute_cmd('pacman -Qu')))
	TextColumn.set(info, cr, 4, line_count(execute_cmd('pacman -Qdt')))
	TextColumn.set(info, cr, 5, line_count(execute_cmd('pacman -Qm')))
end

__update(_CR)

_CR = nil

local draw = function(cr, current_interface, trigger)
	if trigger == 0 then __update(cr) end
	
	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		TextColumn.draw(labels, cr)
		TextColumn.draw(info, cr)
	end
end

return draw
