local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local util			= require 'util'
local schema		= require 'default_patterns'

local PACMAN_TABLE = {
	'pacman -Qq',
	'pacman -Qeq',
	'pacman -Quq',
	'pacman -Qdtq',
	'pacman -Qmq'
}

local _INITIAL_PGK_CNT_ = {}
for i, cmd in pairs(PACMAN_TABLE) do
	_INITIAL_PGK_CNT_[i] = util.line_count(util.execute_cmd(cmd))
end

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
	unpack(_INITIAL_PGK_CNT_)
}

Widget = nil
schema = nil
_TEXT_SPACING_ = nil
_INITIAL_PGK_CNT_ = nil

local update = function(cr)
	for i, cmd in pairs(PACMAN_TABLE) do
		TextColumn.set(info, cr, i, util.line_count(util.execute_cmd(cmd)))
	end
end

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
