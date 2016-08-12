local c = {}

local Bar = require 'Bar'

local _CAIRO_SET_LINE_WIDTH = cairo_set_line_width
local _CAIRO_SET_LINE_CAP 	= cairo_set_line_cap
local _CAIRO_SET_SOURCE   	= cairo_set_source
local _CAIRO_STROKE 	  	= cairo_stroke
local _CAIRO_APPEND_PATH  	= cairo_append_path

local set = function(obj, index, percent)
	Bar.set(obj.bars[index], percent)
end

local draw = function(obj, cr)
	local first_bar = obj.bars[1]
	_CAIRO_SET_LINE_WIDTH(cr, first_bar.thickness)
	_CAIRO_SET_LINE_CAP(cr, first_bar.cap)
	
	for i = 1, obj.bars.n do
		local bar = obj.bars[i]
		_CAIRO_SET_SOURCE(cr, bar.source)
		_CAIRO_APPEND_PATH(cr, bar.path)
		_CAIRO_STROKE(cr)
		_CAIRO_SET_SOURCE(cr, bar.current_source)
		_CAIRO_APPEND_PATH(cr, bar.bar_path)
		_CAIRO_STROKE(cr)
	end
end

c.set = set
c.draw = draw

return c
