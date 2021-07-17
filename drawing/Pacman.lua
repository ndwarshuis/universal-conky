local Common		= require 'Common'
local Geometry = require 'Geometry'

local __string_match = string.match
local __string_gmatch = string.gmatch

local _TEXT_SPACING_ = 20

local header = Common.Header(
	Geometry.RIGHT_X,
	Geometry.TOP_Y,
	Geometry.SECTION_WIDTH,
	'PACMAN'
)

local rows = Common.initTextRows(
   Geometry.RIGHT_X,
   header.bottom_y,
   Geometry.SECTION_WIDTH,
   _TEXT_SPACING_,
   {'Total', 'Explicit', 'Outdated', 'Orphaned', 'Local'}
)

_TEXT_SPACING_ = nil

local update = function(cr, pacman_stats)
   local stats = __string_match(pacman_stats, '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$')
   if stats then
      local i = 1
      for v in __string_gmatch(stats, '%d+') do
         Common.text_rows_set(rows, cr, i, v)
         i = i + 1
      end
   else
      for i=1, 5 do
         Common.text_rows_set(rows, cr, i, 'N/A')
      end
   end
end

local draw_static = function(cr)
   Common.drawHeader(cr, header)
   Common.text_rows_draw_static(rows, cr)
end

local draw_dynamic = function(cr, pacman_stats)
   update(cr, pacman_stats)
   Common.text_rows_draw_dynamic(rows, cr)
end

return function()
   return {static = draw_static, dynamic = draw_dynamic}
end
