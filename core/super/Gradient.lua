local _CAIRO_PATTERN_CREATE_RADIAL 		 	= cairo_pattern_create_radial
local _CAIRO_PATTERN_CREATE_LINEAR 		 	= cairo_pattern_create_linear
local _CAIRO_PATTERN_ADD_COLOR_STOP_RGBA 	= cairo_pattern_add_color_stop_rgba
local _PAIRS 								= pairs

local set_dimensions = function(gradient, p1, p2, r1, r2)
	if p1 and p2 then
		local pattern = (r1 and r2) and
			_CAIRO_PATTERN_CREATE_RADIAL(p1.x, p1.y, r1, p2.x, p2.y, r2) or
			_CAIRO_PATTERN_CREATE_LINEAR(p1.x, p1.y, p2.x, p2.y)
		
		for _, color_stop in _PAIRS(gradient.color_stops) do
			_CAIRO_PATTERN_ADD_COLOR_STOP_RGBA(pattern,	color_stop.stop, color_stop.r,
				color_stop.g, color_stop.b, color_stop.a)
		end
		gradient.userdata = pattern
	end
end

return set_dimensions
