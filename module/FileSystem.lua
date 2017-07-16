local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local CriticalText	= require 'CriticalText'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local CompoundBar	= require 'CompoundBar'
local util			= require 'util'
local schema		= require 'default_patterns'

local _PAIRS 		= pairs
local _STRING_MATCH = string.match

local FS_PATHS = {'/', '/boot', '/var', '/home', '/mnt/data', '/usr/local/opt'}
local FS_NUM = #FS_PATHS
local FS_REGEX = '^([%d%p]-)(%a+)'

local MODULE_Y = 165
local SPACING = 20
local BAR_PAD = 100

local header = Widget.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = MODULE_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'FILE SYSTEMS'
}

local HEADER_BOTTOM_Y = header.bottom_y

local labels = Widget.TextColumn{
	x 		= _G_INIT_DATA_.RIGHT_X,
	y 		= HEADER_BOTTOM_Y,
	spacing = SPACING,
	'root',
	'boot',
	'var',
	'home',
	'data',
	'lopt'
}

local conky_used_perc = {}

for i, v in _PAIRS(FS_PATHS) do
	conky_used_perc[i] = '${fs_used_perc '..v..'}'
end

local bars = Widget.CompoundBar{
	x 				= _G_INIT_DATA_.RIGHT_X + BAR_PAD,
	y 				= HEADER_BOTTOM_Y,
	length 			= _G_INIT_DATA_.SECTION_WIDTH - BAR_PAD,
	spacing 		= SPACING,
	num_bars 		= FS_NUM,
	critical_limit	= '>0.8'
}

Widget = nil
_PAIRS = nil
schema = nil

SPACING = nil
TEXT_WIDTH = nil
BAR_PAD = nil
FS_PATHS = nil
HEADER_BOTTOM_Y = nil

local __update = function(cr)
	for i = 1, FS_NUM do
		local percent = util.conky_numeric(conky_used_perc[i])
		CompoundBar.set(bars, i, percent * 0.01)
	end
end

__update(_CR)

_CR = nil

local draw = function(cr, current_interface, trigger)
	if trigger == 0 then __update(cr) end

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		TextColumn.draw(labels, cr)
		CompoundBar.draw(bars, cr)
	end
end

return draw
