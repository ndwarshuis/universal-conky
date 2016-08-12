local c = {}

local _CR = require 'CR'

local _CAIRO_NEW_PATH 	    = cairo_new_path
local _CAIRO_MOVE_TO 	    = cairo_move_to
local _CAIRO_LINE_TO 	    = cairo_line_to
local _CAIRO_CLOSE_PATH     = cairo_close_path
local _CAIRO_APPEND_PATH    = cairo_append_path
local _CAIRO_COPY_PATH 	    = cairo_copy_path
local _CAIRO_SET_LINE_WIDTH = cairo_set_line_width
local _CAIRO_SET_LINE_CAP   = cairo_set_line_cap
local _CAIRO_SET_LINE_JOIN  = cairo_set_line_join
local _CAIRO_SET_SOURCE	    = cairo_set_source
local _CAIRO_STROKE		    = cairo_stroke

local create_path = function(closed, ...)
	_CAIRO_NEW_PATH(_CR)
	_CAIRO_MOVE_TO(_CR, arg[1].x, arg[1].y)
	for i = 2, #arg do
		_CAIRO_LINE_TO(_CR, arg[i].x, arg[i].y)
	end
	if closed then _CAIRO_CLOSE_PATH(_CR) end
	return _CAIRO_COPY_PATH(_CR)
end

local draw = function(obj, cr)
	_CAIRO_APPEND_PATH(cr, obj.path)
	_CAIRO_SET_LINE_WIDTH(cr, obj.thickness)
	_CAIRO_SET_LINE_JOIN(cr, obj.join)
	_CAIRO_SET_LINE_CAP(cr, obj.cap)
	_CAIRO_SET_SOURCE(cr, obj.source)
	_CAIRO_STROKE(cr)
end

c.create_path = create_path
c.draw = draw

return c
