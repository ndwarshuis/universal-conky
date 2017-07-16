local Widget 	= require 'Widget'	
local FillRect 	= require 'FillRect'

local left = Widget.Panel{
	x = G_DIMENSIONS_.LEFT_X - G_DIMENSIONS_.PANEL_MARGIN_X,
	y = G_DIMENSIONS_.TOP_Y - G_DIMENSIONS_.PANEL_MARGIN_Y,
	width = G_DIMENSIONS_.SECTION_WIDTH + G_DIMENSIONS_.PANEL_MARGIN_X * 2,
	height = G_DIMENSIONS_.SIDE_HEIGHT + G_DIMENSIONS_.PANEL_MARGIN_Y * 2,
}
local center = Widget.Panel{
	x = G_DIMENSIONS_.CENTER_LEFT_X - G_DIMENSIONS_.PANEL_MARGIN_X,
	y = G_DIMENSIONS_.TOP_Y - G_DIMENSIONS_.PANEL_MARGIN_Y,
	width = G_DIMENSIONS_.CENTER_WIDTH + G_DIMENSIONS_.PANEL_MARGIN_Y * 2 + G_DIMENSIONS_.CENTER_PAD,
	height = G_DIMENSIONS_.CENTER_HEIGHT + G_DIMENSIONS_.PANEL_MARGIN_Y * 2,
}
local right = Widget.Panel{
	x = G_DIMENSIONS_.RIGHT_X - G_DIMENSIONS_.PANEL_MARGIN_X,
	y = G_DIMENSIONS_.TOP_Y - G_DIMENSIONS_.PANEL_MARGIN_Y,
	width = G_DIMENSIONS_.SECTION_WIDTH + G_DIMENSIONS_.PANEL_MARGIN_X * 2,
	height = G_DIMENSIONS_.SIDE_HEIGHT + G_DIMENSIONS_.PANEL_MARGIN_Y * 2,
}

Widget = nil

local draw = function(cr)
	FillRect.draw(left, cr)
	FillRect.draw(center, cr)
	FillRect.draw(right, cr)
end

return draw
