local Util			= require 'Util'
local Common		= require 'Common'
local Geometry = require 'Geometry'

return function()
   local TEXT_SPACING = 20

   local __string_match = string.match

   local header = Common.Header(
      Geometry.LEFT_X,
      Geometry.TOP_Y,
      Geometry.SECTION_WIDTH,
      'SYSTEM'
   )

   local rows = Common.initTextRows(
      Geometry.LEFT_X,
      header.bottom_y,
      Geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'Kernel', 'Uptime', 'Last Upgrade', 'Last Sync'}
   )

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.text_rows_draw_static(rows, cr)
   end

   local draw_dynamic = function(cr, pacman_stats)
      local last_update, last_sync = "N/A", "N/A"
      if pacman_stats then
         last_update, last_sync = __string_match(pacman_stats, "^%d+%s+([^%s]+)%s+([^%s]+).*")
      end
      -- TODO this doesn't need to be update every time
      Common.text_rows_set(rows, cr, 1, Util.conky('$kernel'))
      Common.text_rows_set(rows, cr, 2, Util.conky('$uptime'))
      Common.text_rows_set(rows, cr, 3, last_update)
      Common.text_rows_set(rows, cr, 4, last_sync)
      Common.text_rows_draw_dynamic(rows, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
