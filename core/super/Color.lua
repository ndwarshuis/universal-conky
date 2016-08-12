local c = {}

local Gradient 	= require 'Gradient'

local _CAIRO_PATTERN_CREATE_RGBA = cairo_pattern_create_rgba

--Color(hex_rgba, [force_alpha])
local init = function(arg)

	local hex_rgba = arg.hex_rgba

	local obj = {
		r = ((hex_rgba / 0x1000000) % 0x100) / 255.,
		g = ((hex_rgba / 0x10000) % 0x100) / 255.,
		b = ((hex_rgba / 0x100) % 0x100) / 255.,
		a = arg.force_alpha or (hex_rgba % 0x100) / 255.
	}
	obj.userdata = _CAIRO_PATTERN_CREATE_RGBA(obj.r, obj.g, obj.b, obj.a)

	return obj
end

--ColorStop(hex_rgba, stop, [force_alpha])
local initColorStop = function(arg)

	local obj = init{
		hex_rgba = arg.hex_rgba,
		force_alpha = arg.force_alpha
	}
	
	obj.stop = arg.stop

	return obj
end

--Gradient([p1], [p2], [r0], [r1], ... color stops)
local initGradient = function(arg)

	local obj = {
		color_stops = {},
		ptype = 'Gradient'
	}
	
	for i = 1, #arg do obj.color_stops[i] = arg[i] end

	Gradient(obj, arg.p1, arg.p2, arg.r1, arg.r2)

	return obj
end

c.init = init
c.ColorStop = initColorStop
c.Gradient = initGradient

return c
