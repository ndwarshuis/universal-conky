local c = {}

local Dial = require 'Dial'

local _CAIRO_SET_LINE_WIDTH = cairo_set_line_width
local _CAIRO_SET_LINE_CAP 	= cairo_set_line_cap
local _CAIRO_SET_SOURCE   	= cairo_set_source
local _CAIRO_STROKE 	  	= cairo_stroke
local _CAIRO_APPEND_PATH  	= cairo_append_path

local set = function(obj, index, percent)
	Dial.set(obj.dials[index], percent)
end

local draw = function(obj, cr)
	local dials = obj.dials
	_CAIRO_SET_LINE_WIDTH(cr, dials[1].thickness)
	_CAIRO_SET_LINE_CAP(cr, dials[1].cap)
	
	for i = 1, #dials do
		local current_dial = dials[i]
		_CAIRO_SET_SOURCE(cr, current_dial.source)
		_CAIRO_APPEND_PATH(cr, current_dial.path)
		_CAIRO_STROKE(cr)
		_CAIRO_SET_SOURCE(cr, current_dial.current_source)
		_CAIRO_APPEND_PATH(cr, current_dial.dial_path)
		_CAIRO_STROKE(cr)
	end
end

c.set = set
c.draw = draw

return c
