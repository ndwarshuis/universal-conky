local M = {}

local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local Util			= require 'Util'

local __string_match = string.match
local __string_gmatch = string.gmatch

local _TEXT_SPACING_ = 20

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _G_INIT_DATA_.TOP_Y,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'PACMAN'
}

local labels = _G_Widget_.TextColumn{
	x 		= _G_INIT_DATA_.RIGHT_X,
	y 		= header.bottom_y,
	spacing = _TEXT_SPACING_,
	'Total',
	'Explicit',
	'Outdated',
	'Orphaned',
	'Local'
}
local info = _G_Widget_.TextColumn{
	x 			= _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH,
	y 			= header.bottom_y,
	spacing 	= _TEXT_SPACING_,
	x_align 	= 'right',
	text_color 	= _G_Patterns_.BLUE,
	num_rows 	= 5
}

_TEXT_SPACING_ = nil

local update = function(cr, pacman_stats)
   local stats = __string_match(pacman_stats, '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$')
   if stats then
      local i = 1
      for v in __string_gmatch(stats, '%d+') do
         TextColumn.set(info, cr, i, v)
         i = i + 1
      end
   else
      for i=1,5 do
         TextColumn.set(info, cr, i, 'N/A')
      end
   end
end

local draw_static = function(cr)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)
   TextColumn.draw(labels, cr)
end

local draw_dynamic = function(cr, pacman_stats)
   update(cr, pacman_stats)
   TextColumn.draw(info, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
