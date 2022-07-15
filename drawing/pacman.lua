local common		= require 'common'
local geometry = require 'geometry'

return function(point)
   local TEXT_SPACING = 20

   local __string_match = string.match
   local __string_gmatch = string.gmatch

   local header = common.make_header(
      point.x,
      point.y,
      geometry.SECTION_WIDTH,
      'PACMAN'
   )

   local rows = common.make_text_rows(
      point.x,
      header.bottom_y,
      geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'Total', 'Explicit', 'Outdated', 'Orphaned', 'Local'}
   )

   local update = function(pacman_stats)
      local stats = __string_match(pacman_stats, '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$')
      if stats then
         local i = 1
         for v in __string_gmatch(stats, '%d+') do
            common.text_rows_set(rows, i, v)
            i = i + 1
         end
      else
         for i=1, 5 do
            common.text_rows_set(rows, i, 'N/A')
         end
      end
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)
      common.text_rows_draw_static(rows, cr)
   end

   local draw_dynamic = function(cr)
      common.text_rows_draw_dynamic(rows, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
