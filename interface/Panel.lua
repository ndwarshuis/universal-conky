local Widget 	= require 'Widget'	
local FillRect 	= require 'FillRect'

local left = Widget.Panel{
	x = _G_INIT_DATA_.LEFT_X - _G_INIT_DATA_.PANEL_MARGIN_X,
	y = _G_INIT_DATA_.TOP_Y - _G_INIT_DATA_.PANEL_MARGIN_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH + _G_INIT_DATA_.PANEL_MARGIN_X * 2,
	height = _G_INIT_DATA_.SIDE_HEIGHT + _G_INIT_DATA_.PANEL_MARGIN_Y * 2,
}
local center = Widget.Panel{
	x = _G_INIT_DATA_.CENTER_LEFT_X - _G_INIT_DATA_.PANEL_MARGIN_X,
	y = _G_INIT_DATA_.TOP_Y - _G_INIT_DATA_.PANEL_MARGIN_Y,
	width = _G_INIT_DATA_.CENTER_WIDTH + _G_INIT_DATA_.PANEL_MARGIN_Y * 2 + _G_INIT_DATA_.CENTER_PAD,
	height = _G_INIT_DATA_.CENTER_HEIGHT + _G_INIT_DATA_.PANEL_MARGIN_Y * 2,
}
local right = Widget.Panel{
	x = _G_INIT_DATA_.RIGHT_X - _G_INIT_DATA_.PANEL_MARGIN_X,
	y = _G_INIT_DATA_.TOP_Y - _G_INIT_DATA_.PANEL_MARGIN_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH + _G_INIT_DATA_.PANEL_MARGIN_X * 2,
	height = _G_INIT_DATA_.SIDE_HEIGHT + _G_INIT_DATA_.PANEL_MARGIN_Y * 2,
}

Widget = nil

local draw = function(cr)
	FillRect.draw(left, cr)
	FillRect.draw(center, cr)
	FillRect.draw(right, cr)
end

return draw
