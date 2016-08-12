local Widget 	= require 'Widget'	
local FillRect 	= require 'FillRect'

local PAD_X = 20
local PAD_Y = 10

local left = Widget.Panel{
	x = CONSTRUCTION_GLOBAL.LEFT_X - PAD_X,
	y = CONSTRUCTION_GLOBAL.TOP_Y - PAD_Y,
	width = CONSTRUCTION_GLOBAL.SIDE_WIDTH + PAD_X * 2,
	height = CONSTRUCTION_GLOBAL.SIDE_HEIGHT + PAD_Y * 2,
}
local center = Widget.Panel{
	x = CONSTRUCTION_GLOBAL.CENTER_X - PAD_X,
	y = CONSTRUCTION_GLOBAL.TOP_Y - PAD_Y,
	width = CONSTRUCTION_GLOBAL.CENTER_WIDTH + PAD_X * 2,
	height = CONSTRUCTION_GLOBAL.CENTER_HEIGHT + PAD_Y * 2,
}
local right = Widget.Panel{
	x = CONSTRUCTION_GLOBAL.RIGHT_X - PAD_X,
	y = CONSTRUCTION_GLOBAL.TOP_Y - PAD_Y,
	width = CONSTRUCTION_GLOBAL.SIDE_WIDTH + PAD_X * 2,
	height = CONSTRUCTION_GLOBAL.SIDE_HEIGHT + PAD_Y * 2,
}

Widget = nil

local draw = function(cr)
	FillRect.draw(left, cr)
	FillRect.draw(center, cr)
	FillRect.draw(right, cr)
end

return draw
