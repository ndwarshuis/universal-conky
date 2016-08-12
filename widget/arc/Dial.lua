local c = {}

local Arc = require 'Arc'

local _CAIRO_SET_SOURCE  = cairo_set_source
local _CAIRO_STROKE 	 = cairo_stroke
local _CAIRO_APPEND_PATH = cairo_append_path

local set = function(obj, percent)
	obj.percent = percent
	obj.dial_path = obj._make_dial_path(percent)

	if obj.critical.enabled(obj.percent) then
		obj.current_source = obj.critical.source
	else
		obj.current_source = obj.indicator_source
	end
end

local draw = function(obj, cr)
	Arc.draw(obj, cr)
	_CAIRO_SET_SOURCE(cr, obj.current_source)
	_CAIRO_APPEND_PATH(cr, obj.dial_path)
	_CAIRO_STROKE(cr)
end

c.set = set
c.draw = draw

return c
