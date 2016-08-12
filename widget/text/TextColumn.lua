local c = {}

local Text = require 'Text'

local _CAIRO_SET_FONT_FACE 		  = cairo_set_font_face
local _CAIRO_SET_FONT_SIZE 		  = cairo_set_font_size
local _CAIRO_SET_SOURCE	   		  = cairo_set_source
local _CAIRO_MOVE_TO       		  = cairo_move_to
local _CAIRO_SHOW_TEXT     		  = cairo_show_text
local _STRING_SUB				  = string.sub

local set = function(obj, cr, row_num, text)
	if obj.max_length then
		Text.set(obj.rows[row_num], cr, Text.trim_to_length(text, obj.max_length))
	else
		Text.set(obj.rows[row_num], cr, text)
	end
end

local draw = function(obj, cr)
	local rep_row = obj.rows[1]
	_CAIRO_SET_FONT_FACE(cr, rep_row.font_face)
	_CAIRO_SET_FONT_SIZE(cr, rep_row.font_size)
	_CAIRO_SET_SOURCE(cr, rep_row.source)

	local rows = obj.rows
	
	for i = 1, rows.n do
		local row = rows[i]
		_CAIRO_MOVE_TO(cr, row.x, row.y)
		_CAIRO_SHOW_TEXT(cr, row.text)
	end
end

c.set = set
c.draw = draw

return c
