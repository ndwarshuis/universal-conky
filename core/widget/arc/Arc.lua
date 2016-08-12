local c = {}

local _CR = require 'CR'

local _CAIRO_NEW_PATH  		= cairo_new_path
local _CAIRO_ARC 	   		= cairo_arc
local _CAIRO_COPY_PATH 		= cairo_copy_path
local _CAIRO_APPEND_PATH 	= cairo_append_path
local _CAIRO_SET_LINE_WIDTH = cairo_set_line_width
local _CAIRO_SET_LINE_CAP 	= cairo_set_line_cap
local _CAIRO_SET_SOURCE 	= cairo_set_source
local _CAIRO_STROKE 		= cairo_stroke

local draw = function(obj, cr)
	_CAIRO_APPEND_PATH(cr, obj.path)
	_CAIRO_SET_LINE_WIDTH(cr, obj.thickness)
	_CAIRO_SET_LINE_CAP(cr, obj.cap)
	_CAIRO_SET_SOURCE(cr, obj.source)
	_CAIRO_STROKE(cr)
end

local create_path = function(x, y, radius, theta0, theta1)
	_CAIRO_NEW_PATH(_CR)
	_CAIRO_ARC(_CR, x, y, radius, theta0, theta1)
	return _CAIRO_COPY_PATH(_CR)
end

c.draw = draw
c.create_path = create_path

return c
