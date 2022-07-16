local i_o = require 'i_o'
local pure = require 'pure'
local common = require 'common'
local geometry = require 'geometry'

return function(main_state, point)
   local TEXT_SPACING = 20

   local __string_match = string.match

   local mk_stats = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         TEXT_SPACING,
         {'Kernel', 'Uptime', 'Last Upgrade', 'Last Sync'}
      )
      local update = function()
         local last_update, last_sync
         if main_state.pacman_stats then
            last_update, last_sync = __string_match(
               main_state.pacman_stats,
               "^%d+%s+([^%s]+)%s+([^%s]+).*"
            )
         end
         -- TODO this doesn't need to be update every time
         common.text_rows_set(obj, 1, i_o.conky('$kernel'))
         common.text_rows_set(obj, 2, i_o.conky('$uptime'))
         common.text_rows_set(obj, 3, last_update)
         common.text_rows_set(obj, 4, last_sync)
      end
      local static = pure.partial(common.text_rows_draw_static, obj)
      local dynamic = pure.partial(common.text_rows_draw_dynamic, obj)
      return common.mk_acc(
         geometry.SECTION_WIDTH,
         TEXT_SPACING * 3,
         update,
         static,
         dynamic
      )
   end

   return common.reduce_blocks_(
      'SYSTEM',
      point,
      geometry.SECTION_WIDTH,
      {common.mk_block(mk_stats, true, 0)}
   )
end
