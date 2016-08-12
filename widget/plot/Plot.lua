local c = {}

local Poly = require 'Poly'

local _CAIRO_APPEND_PATH    = cairo_append_path
local _CAIRO_MOVE_TO    	= cairo_move_to
local _CAIRO_LINE_TO    	= cairo_line_to
local _CAIRO_SET_LINE_WIDTH = cairo_set_line_width
local _CAIRO_SET_LINE_CAP   = cairo_set_line_cap
local _CAIRO_SET_LINE_JOIN  = cairo_set_line_join
local _CAIRO_SET_SOURCE	    = cairo_set_source
local _CAIRO_FILL_PRESERVE  = cairo_fill_preserve
local _CAIRO_STROKE		    = cairo_stroke
local _CAIRO_PATH_DESTROY	= cairo_path_destroy
local _TABLE_INSERT			= table.insert

local DATA_THICKNESS = 1
local DATA_CAP = CAIRO_LINE_CAP_BUTT
local DATA_JOIN = CAIRO_LINE_JOIN_MITER
local INTRVL_THICKNESS = 1
local INTRVL_CAP = CAIRO_LINE_CAP_BUTT
local OUTLINE_THICKNESS = 2
local OUTLINE_CAP = CAIRO_LINE_CAP_BUTT
local OUTLINE_JOIN = CAIRO_LINE_JOIN_MITER

local update = function(obj, value)
	local data = obj.data
	_TABLE_INSERT(data, 1, obj.y + obj.height * (1 - value))
	if #data == data.n + 2 then data[#data] = nil end
end

local draw = function(obj, cr)

	--draw intervals
	local intrvls = obj.intrvls
	local x_intrvls = intrvls.x
	local y_intrvls = intrvls.y
	
	_CAIRO_SET_LINE_WIDTH(cr, INTRVL_THICKNESS)
	_CAIRO_SET_LINE_CAP(cr, INTRVL_CAP)
	_CAIRO_SET_SOURCE(cr, intrvls.source)
	for i = 1, #x_intrvls do
		_CAIRO_APPEND_PATH(cr, x_intrvls[i])
	end
	for i = 1, #y_intrvls do
		_CAIRO_APPEND_PATH(cr, y_intrvls[i])
	end
	_CAIRO_STROKE(cr)

	--draw data on graph
	local data = obj.data
	local n = #data - 1
	local spacing = obj.width / data.n
	local right = obj.x + obj.width

	_CAIRO_MOVE_TO(cr, right, data[1])
	
	for i = 1, n do
		_CAIRO_LINE_TO(cr, right - i * spacing, data[i+1])
	end
	
	if data.fill_source then
		local bottom = obj.y + obj.height
		_CAIRO_LINE_TO(cr, right - n * spacing, bottom)
		_CAIRO_LINE_TO(cr, right, bottom)
		_CAIRO_SET_SOURCE(cr, data.fill_source)
		_CAIRO_FILL_PRESERVE(cr)
	end
	
	_CAIRO_SET_LINE_WIDTH (cr, DATA_THICKNESS)
	_CAIRO_SET_LINE_CAP(cr, DATA_CAP)
	_CAIRO_SET_LINE_JOIN(cr, DATA_JOIN)
	_CAIRO_SET_SOURCE(cr, data.line_source)
	_CAIRO_STROKE(cr)

	--draw graph outline (goes on top of everything)
	local outline = obj.outline
	
	_CAIRO_APPEND_PATH(cr, outline.path)
	_CAIRO_SET_LINE_WIDTH(cr, OUTLINE_THICKNESS)
	_CAIRO_SET_LINE_JOIN(cr, OUTLINE_JOIN)
	_CAIRO_SET_LINE_CAP(cr, OUTLINE_CAP)
	_CAIRO_SET_SOURCE(cr, outline.source)
	_CAIRO_STROKE(cr)
end

local position_x_intrvls = function(obj)
	local y1 = obj.y - 0.5
	local y2 = y1 + obj.height-- + 0.5
	local x_intrvls = obj.intrvls.x
	local intrvl_width = obj.width / x_intrvls.n
	local p1 = {x = 0, y = 0}
	local p2 = {x = 0, y = 0}

	local obj_x = obj.x

	for i = 1, x_intrvls.n do
		local x1 = obj_x + intrvl_width * i-- + 0.5
		p1.x = x1
		p1.y = y1
		p2.x = x1
		p2.y = y2
		_CAIRO_PATH_DESTROY(x_intrvls[i])
		x_intrvls[i] = Poly.create_path(nil, p1, p2)
	end
end

local position_y_intrvls = function(obj)
	local x1 = obj.x-- + 0.5
	local x2 = obj.x + obj.width-- + 0.5
	local y_intrvls = obj.intrvls.y
	local y_intrvl_height = obj.height / y_intrvls.n
	local p1 = {x = 0, y = 0}
	local p2 = {x = 0, y = 0}
	
	for i = 1, y_intrvls.n do
		local y1 = obj.y + (i - 1) * y_intrvl_height - 0.5
		p1.x = x1
		p1.y = y1
		p2.x = x2
		p2.y = y1
		_CAIRO_PATH_DESTROY(y_intrvls[i])
		y_intrvls[i] = Poly.create_path(nil, p1, p2)
	end
end

local position_graph_outline = function(obj)
	local x1 = obj.x
	local y1 = obj.y - 0.5
	local x2 = obj.x + obj.width + 0.5
	local y2 = obj.y + obj.height + 1.0
	local p1 = {x = x1, y = y1}
	local p2 = {x = x1, y = y2}
	local p3 = {x = x2, y = y2}

	_CAIRO_PATH_DESTROY(obj.outline.path)
	
	obj.outline.path = Poly.create_path(nil, p1, p2, p3)
end

c.draw = draw
c.update = update
c.position_x_intrvls = position_x_intrvls
c.position_y_intrvls = position_y_intrvls
c.position_graph_outline = position_graph_outline

return c
