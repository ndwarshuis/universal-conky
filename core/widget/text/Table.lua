local c = {}

local TextColumn 	= require 'TextColumn'
local Rect 			= require 'Rect'

local _CAIRO_SET_LINE_WIDTH 	  = cairo_set_line_width
local _CAIRO_SET_LINE_CAP   	  = cairo_set_line_cap
local _CAIRO_APPEND_PATH    	  = cairo_append_path
local _CAIRO_STROKE		          = cairo_stroke
local _CAIRO_SET_FONT_FACE 		  = cairo_set_font_face
local _CAIRO_SET_FONT_SIZE 		  = cairo_set_font_size
local _CAIRO_SET_SOURCE	   		  = cairo_set_source
local _CAIRO_MOVE_TO       		  = cairo_move_to
local _CAIRO_SHOW_TEXT     		  = cairo_show_text

local set = function(obj, cr, col_num, row_num, text)
	local column = obj.table.columns[col_num]
	TextColumn.set(column, cr, row_num, text)
end

local draw = function(obj, cr)
	--draw rectangle
	Rect.draw(obj, cr)

	--draw headers
	local tbl = obj.table
	local columns = tbl.columns

	local first_header = columns[1].header
	_CAIRO_SET_SOURCE(cr, first_header.source)
	_CAIRO_SET_FONT_FACE(cr, first_header.font_face)
	_CAIRO_SET_FONT_SIZE(cr, first_header.font_size)
	
	for c = 1, tbl.num_columns do
		local header = columns[c].header
		_CAIRO_MOVE_TO(cr, header.x, header.y)
		_CAIRO_SHOW_TEXT(cr, header.text)
	end

	--draw rows
	local first_cell = columns[1].rows[1]
	_CAIRO_SET_SOURCE(cr, first_cell.source)
	_CAIRO_SET_FONT_FACE(cr, first_cell.font_face)
	_CAIRO_SET_FONT_SIZE(cr, first_cell.font_size)
	
	for c = 1, tbl.num_columns do
		local rows = columns[c].rows
		for r = 1, rows.n do
			local row = rows[r]
			_CAIRO_MOVE_TO(cr, row.x, row.y)
			_CAIRO_SHOW_TEXT(cr, row.text)
		end
	end

	--draw separators
	local separators = tbl.separators

	local first_separator = separators[1]
	_CAIRO_SET_SOURCE(cr, first_separator.source)
	_CAIRO_SET_LINE_WIDTH(cr, first_separator.thickness)
	_CAIRO_SET_LINE_CAP(cr, first_separator.cap)
	
	for i = 1, separators.n do
		local line = separators[i]
		_CAIRO_APPEND_PATH(cr, line.path)
		_CAIRO_STROKE(cr)
	end
end

c.set = set
c.draw = draw

return c
