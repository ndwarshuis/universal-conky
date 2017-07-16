local Widget 	= require 'Widget'	
local FillRect 	= require 'FillRect'

local left = Widget.Panel{
	x = __G_INIT_DATA__.LEFT_X - __G_INIT_DATA__.PANEL_MARGIN_X,
	y = __G_INIT_DATA__.TOP_Y - __G_INIT_DATA__.PANEL_MARGIN_Y,
	width = __G_INIT_DATA__.SECTION_WIDTH + __G_INIT_DATA__.PANEL_MARGIN_X * 2,
	height = __G_INIT_DATA__.SIDE_HEIGHT + __G_INIT_DATA__.PANEL_MARGIN_Y * 2,
}
local center = Widget.Panel{
	x = __G_INIT_DATA__.CENTER_LEFT_X - __G_INIT_DATA__.PANEL_MARGIN_X,
	y = __G_INIT_DATA__.TOP_Y - __G_INIT_DATA__.PANEL_MARGIN_Y,
	width = __G_INIT_DATA__.CENTER_WIDTH + __G_INIT_DATA__.PANEL_MARGIN_Y * 2 + __G_INIT_DATA__.CENTER_PAD,
	height = __G_INIT_DATA__.CENTER_HEIGHT + __G_INIT_DATA__.PANEL_MARGIN_Y * 2,
}
local right = Widget.Panel{
	x = __G_INIT_DATA__.RIGHT_X - __G_INIT_DATA__.PANEL_MARGIN_X,
	y = __G_INIT_DATA__.TOP_Y - __G_INIT_DATA__.PANEL_MARGIN_Y,
	width = __G_INIT_DATA__.SECTION_WIDTH + __G_INIT_DATA__.PANEL_MARGIN_X * 2,
	height = __G_INIT_DATA__.SIDE_HEIGHT + __G_INIT_DATA__.PANEL_MARGIN_Y * 2,
}

Widget = nil

local draw = function(cr)
	FillRect.draw(left, cr)
	FillRect.draw(center, cr)
	FillRect.draw(right, cr)
end

return draw
