local M = {}

local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local Util			= require 'Util'

local __string_match = string.match

local _TEXT_SPACING_ = 20

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.LEFT_X,
	y = _G_INIT_DATA_.TOP_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'SYSTEM'
}

local labels = _G_Widget_.TextColumn{
	x 		= _G_INIT_DATA_.LEFT_X,
	y 		= header.bottom_y,
	spacing = _TEXT_SPACING_,
	'Kernel',
	'Uptime',
	'Last Upgrade',
	'Last Sync'
}
local kernel = _G_Widget_.Text{
   x          = _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH,
   y          = header.bottom_y,
   x_align    = 'right',
   text       = Util.conky('$kernel'),
   text_color = _G_Patterns_.BLUE
}
local info = _G_Widget_.TextColumn{
	x 			= _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH,
	y 			= header.bottom_y + _TEXT_SPACING_,
	spacing 	= _TEXT_SPACING_,
	x_align 	= 'right',
	text_color 	= _G_Patterns_.BLUE,
	'<row1>',
	'<row2>',
	'<row3>'
}

_TEXT_SPACING_ = nil

local draw_static = function(cr)
   Text.draw(header.text, cr)
   Text.draw(kernel, cr)
   Line.draw(header.underline, cr)
   TextColumn.draw(labels, cr)
end

local draw_dynamic = function(cr, pacman_stats)
   TextColumn.set(info, cr, 1, Util.conky('$uptime'))

   if pacman_stats then
      local last_update, last_sync = __string_match(pacman_stats, "^%d+%s+([^%s]+)%s+([^%s]+).*")
      TextColumn.set(info, cr, 2, last_update)
      TextColumn.set(info, cr, 3, last_sync)
   end

   TextColumn.draw(info, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
