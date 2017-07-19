local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local CompoundBar	= require 'CompoundBar'
local Util			= require 'Util'

local __string_match 	= string.match

local _FS_PATHS_ = {'/', '/boot', '/var', '/home', '/mnt/data', '/usr/local/opt'}
local _MODULE_Y_ = 165
local _SPACING_ = 20
local _BAR_PAD_ = 100

local FS_NUM = #_FS_PATHS_

local header = Widget.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'FILE SYSTEMS'
}

local labels = Widget.TextColumn{
	x 		= _G_INIT_DATA_.RIGHT_X,
	y 		= header.bottom_y,
	spacing = _SPACING_,
	'root',
	'boot',
	'var',
	'home',
	'data',
	'lopt'
}

local conky_used_perc = {}

for i, v in pairs(_FS_PATHS_) do
	conky_used_perc[i] = '${fs_used_perc '..v..'}'
end

local bars = Widget.CompoundBar{
	x 				= _G_INIT_DATA_.RIGHT_X + _BAR_PAD_,
	y 				= header.bottom_y,
	length 			= _G_INIT_DATA_.SECTION_WIDTH - _BAR_PAD_,
	spacing 		= _SPACING_,
	num_bars 		= FS_NUM,
	critical_limit	= '>0.8'
}

Widget = nil

_SPACING_ = nil
_BAR_PAD_ = nil
_FS_PATHS_ = nil

local update = function(cr)
	for i = 1, FS_NUM do
		local percent = Util.conky_numeric(conky_used_perc[i])
		CompoundBar.set(bars, i, percent * 0.01)
	end
end

local draw = function(cr, current_interface, trigger)
	if trigger == 0 then update(cr) end

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		TextColumn.draw(labels, cr)
		CompoundBar.draw(bars, cr)
	end
end

return draw
