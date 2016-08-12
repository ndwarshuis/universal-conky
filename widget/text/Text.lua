local c = {}

local _STRING_SUB				= string.sub
local _CAIRO_SET_FONT_FACE 		= cairo_set_font_face
local _CAIRO_SET_FONT_SIZE 		= cairo_set_font_size
local _CAIRO_SET_SOURCE	   		= cairo_set_source
local _CAIRO_MOVE_TO       		= cairo_move_to
local _CAIRO_SHOW_TEXT     		= cairo_show_text
local _CAIRO_TEXT_EXTENTS  		= cairo_text_extents

local te = cairo_text_extents_t:create()
tolua.takeownership(te)

local trim_to_length = function(text, len)
	if #text > len then
		return _STRING_SUB(text, 1, len)..'...'
	else
		return text
	end
end

local draw = function(obj, cr)
	_CAIRO_SET_FONT_FACE(cr, obj.font_face)
	_CAIRO_SET_FONT_SIZE(cr, obj.font_size)
	_CAIRO_SET_SOURCE(cr, obj.current_source)
	_CAIRO_MOVE_TO(cr, obj.x, obj.y)
	_CAIRO_SHOW_TEXT(cr, obj.text)
end

local set = function(obj, cr, text)
	if text and text ~= obj.pretext then
		obj.pretext = text

		if obj.append_front then text = obj.append_front..text end
		if obj.append_end then text = text..obj.append_end end

		if text ~= obj.text then
			local x_align = obj.x_align
			local te = te
			
			_CAIRO_SET_FONT_SIZE(cr, obj.font_size)
			_CAIRO_SET_FONT_FACE(cr, obj.font_face)
			_CAIRO_TEXT_EXTENTS(cr, text, te)
			
			obj.width = te.width
			
			if		x_align == 'left'	then obj.delta_x = -te.x_bearing
			elseif 	x_align == 'center' then obj.delta_x = -(te.x_bearing + obj.width * 0.5)
			elseif 	x_align == 'right'  then obj.delta_x = -(te.x_bearing + obj.width)
			end
			
			obj.x = obj.x_ref + obj.delta_x
		end
		obj.text = text
	end
end

local move_to_x = function(obj, x)
	if x ~= obj.x then
		obj.x_ref = x
		obj.x = x + obj.delta_x
	end
end

local move_to_y = function(obj, y)
	if y ~= obj.y then
		obj.y_ref = y
		obj.y = y + obj.delta_y
	end
end

local move_to = function(obj, x, y)
	move_to_X(obj, x)
	move_to_Y(obj, y)
end

c.trim_to_length = trim_to_length
c.set = set
c.draw = draw
c.move_to = move_to
c.move_to_x = move_to_x
c.move_to_y = move_to_y

return c
