local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'

return function()
   local TEXT_SPACING = 20

   local __string_match = string.match

   local header = common.make_header(
      geometry.LEFT_X,
      geometry.TOP_Y,
      geometry.SECTION_WIDTH,
      'SYSTEM'
   )

   local rows = common.make_text_rows(
      geometry.LEFT_X,
      header.bottom_y,
      geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'Kernel', 'Uptime', 'Last Upgrade', 'Last Sync'}
   )

   local update = function(pacman_stats)
      local last_update, last_sync = "N/A", "N/A"
      if pacman_stats then
         last_update, last_sync = __string_match(pacman_stats, "^%d+%s+([^%s]+)%s+([^%s]+).*")
      end
      -- TODO this doesn't need to be update every time
      common.text_rows_set(rows, 1, i_o.conky('$kernel'))
      common.text_rows_set(rows, 2, i_o.conky('$uptime'))
      common.text_rows_set(rows, 3, last_update)
      common.text_rows_set(rows, 4, last_sync)
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
