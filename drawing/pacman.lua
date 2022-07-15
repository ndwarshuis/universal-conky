local common = require 'common'
local pure = require 'pure'
local geometry = require 'geometry'

return function(point)
   local TEXT_SPACING = 20

   local __string_match = string.match
   local __string_gmatch = string.gmatch

   local mk_header = pure.partial(
      common.mk_header,
      'PACMAN',
      geometry.SECTION_WIDTH,
      point.x
   )

   local mk_stats = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         TEXT_SPACING,
         {'Total', 'Explicit', 'Outdated', 'Orphaned', 'Local'}
      )
      local update = function(pacman_stats)
         local stats = __string_match(pacman_stats, '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$')
         if stats then
            local i = 1
            for v in __string_gmatch(stats, '%d+') do
               common.text_rows_set(obj, i, v)
               i = i + 1
            end
         else
            for i = 1, 5 do
               common.text_rows_set(obj, i, 'N/A')
            end
         end
      end
      return common.mk_acc(
         TEXT_SPACING * 4,
         update,
         pure.partial(common.text_rows_draw_static, obj),
         pure.partial(common.text_rows_draw_dynamic, obj)
      )
   end

   return common.reduce_blocks_(
      point.y,
      {
         common.mk_block(mk_header, true, 0),
         common.mk_block(mk_stats, true, 0),
      }
   )
end
