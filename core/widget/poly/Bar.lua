local c = {}

local _CAIRO_APPEND_PATH    = cairo_append_path
local _CAIRO_SET_LINE_WIDTH = cairo_set_line_width
local _CAIRO_SET_LINE_CAP   = cairo_set_line_cap
local _CAIRO_SET_SOURCE	    = cairo_set_source
local _CAIRO_STROKE		    = cairo_stroke

local set = function(obj, percent)
	obj.percent = percent
	obj.bar_path = obj._make_bar_path(percent)
	
	if obj.critical.enabled(percent) then
		obj.current_source = obj.critical.source
	else
		obj.current_source = obj.indicator_source
	end
end

local draw = function(obj, cr)
	_CAIRO_SET_LINE_WIDTH(cr, obj.thickness)
	_CAIRO_SET_LINE_CAP(cr, obj.cap)
	
	_CAIRO_APPEND_PATH(cr, obj.path)
	_CAIRO_SET_SOURCE(cr, obj.source)
	_CAIRO_STROKE(cr)

	_CAIRO_APPEND_PATH(cr, obj.bar_path)
	_CAIRO_SET_SOURCE(cr, obj.current_source)
	_CAIRO_STROKE(cr)
end

c.set = set
c.draw = draw

return c
