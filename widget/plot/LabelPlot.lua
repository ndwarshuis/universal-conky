local c = {}

local Plot 		= require 'Plot'
local Text 		= require 'Text'

local _CAIRO_SET_SOURCE	    = cairo_set_source
local _CAIRO_SET_FONT_FACE 	= cairo_set_font_face
local _CAIRO_SET_FONT_SIZE 	= cairo_set_font_size
local _CAIRO_MOVE_TO       	= cairo_move_to
local _CAIRO_SHOW_TEXT     	= cairo_show_text
local _CAIRO_STROKE		    = cairo_stroke

local X_LABEL_PAD = 8
local Y_LABEL_PAD = 5

local draw = function(obj, cr)
	local labels_x = obj.labels.x
	local labels_y = obj.labels.y
	local labels_x_1 = labels_x[1]

	_CAIRO_SET_FONT_FACE(cr, labels_x_1.font_face)
	_CAIRO_SET_FONT_SIZE(cr, labels_x_1.font_size)
	_CAIRO_SET_SOURCE(cr, labels_x_1.source)
	
	for i = 1, #labels_x do
		local current_label = labels_x[i]
		_CAIRO_MOVE_TO(cr, current_label.x, current_label.y)
		_CAIRO_SHOW_TEXT(cr, current_label.text)
	end

	for i = 1, #labels_y do
		local current_label = labels_y[i]
		_CAIRO_MOVE_TO(cr, current_label.x, current_label.y)
		_CAIRO_SHOW_TEXT(cr, current_label.text)
	end

	Plot.draw(obj.plot, cr)
end

local populate_x_labels = function(obj, cr, input_factor)
	local labels_x = obj.labels.x
	local n = #labels_x - 1
	input_factor = input_factor or 1
	for i = 0, n do
		Text.set(labels_x[i + 1], cr, labels_x._func(input_factor * i / n))
	end
	labels_x.height = labels_x[1].height + X_LABEL_PAD
	local plot = obj.plot
	plot.height = obj.height - labels_x.height
	plot.bottom_y = plot.height - plot.y
end

local __get_y_axis_width = function(obj)
	local labels_y = obj.labels.y
	local width = labels_y[1].width
	for i = 2, #labels_y do
		local current_width = labels_y[i].width
		if current_width > width then
			width = current_width
		end
	end
	return width + Y_LABEL_PAD
end

local populate_y_labels = function(obj, cr, input_factor)
	local labels_y = obj.labels.y
	local n = #labels_y - 1
	input_factor = input_factor or 1
	for i = 0, n do
		Text.set(labels_y[i + 1], cr, labels_y._func(input_factor * (n - i) / n))
	end
	labels_y.width = __get_y_axis_width(obj)

	local plot = obj.plot
	plot.x = obj.x + labels_y.width
	plot.width = obj.width - labels_y.width
end

local position_x_labels = function(obj)
	local start_x = obj.plot.x
	local labels_x = obj.labels.x
	local x_intrvl_width = obj.plot.width / (#labels_x - 1)
	for i = 1, #labels_x do
		Text.move_to_x(labels_x[i], start_x + x_intrvl_width * (i - 1))
	end
end

local position_y_labels = function(obj)
	local labels_y = obj.labels.y
	local y_intrvl_height = obj.plot.height / (#labels_y - 1)
	for i = 1, #labels_y do
		Text.move_to_y(labels_y[i], obj.y + y_intrvl_height * (i - 1))
	end
end

local update = function(obj, value)
	Plot.update(obj.plot, value)
end

c.update = update
c.draw = draw
c.position_x_intrvls = Plot.position_x_intrvls
c.position_y_intrvls = Plot.position_y_intrvls
c.position_graph_outline = Plot.position_graph_outline
c.populate_x_labels = populate_x_labels
c.populate_y_labels = populate_y_labels
c.position_x_labels = position_x_labels
c.position_y_labels = position_y_labels

return c
