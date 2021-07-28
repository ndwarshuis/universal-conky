local Common		= require 'Common'
local Geometry = require 'Geometry'

return function()
   local TEXT_SPACING = 20

   local __string_match = string.match
   local __string_gmatch = string.gmatch

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
      TEXT_SPACING,
      {'Total', 'Explicit', 'Outdated', 'Orphaned', 'Local'}
   )

   local update = function(pacman_stats)
      local stats = __string_match(pacman_stats, '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$')
      if stats then
         local i = 1
         for v in __string_gmatch(stats, '%d+') do
            Common.text_rows_set(rows, i, v)
            i = i + 1
         end
      else
         for i=1, 5 do
            Common.text_rows_set(rows, i, 'N/A')
         end
      end
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.text_rows_draw_static(rows, cr)
   end

   local draw_dynamic = function(cr)
      -- update(pacman_stats)
      Common.text_rows_draw_dynamic(rows, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
