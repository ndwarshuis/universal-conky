local i_o = require 'i_o'
local pure = require 'pure'

return function(main_state, common, width, point)
   local TEXT_SPACING = 20

   local __string_match = string.match

   local mk_stats = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         width,
         TEXT_SPACING,
         {'Kernel', 'Uptime', 'Last Upgrade', 'Last Sync'}
      )
      -- just update this once
      common.text_rows_set(obj, 1, i_o.conky('$kernel'))
      local update = function()
         local last_update, last_sync
         common.text_rows_set(obj, 2, i_o.conky('$uptime'))
         if main_state.pacman_stats then
            last_update, last_sync = __string_match(
               main_state.pacman_stats,
               "^%d+%s+([^%s]+)%s+([^%s]+).*"
            )
	    common.text_rows_set(obj, 3, last_update)
	    common.text_rows_set(obj, 4, last_sync)
	 else
	    common.text_rows_set(obj, 3, 'N/A')
	    common.text_rows_set(obj, 4, 'N/A')
         end
      end
      local static = pure.partial(common.text_rows_draw_static, obj)
      local dynamic = pure.partial(common.text_rows_draw_dynamic, obj)
      return common.mk_acc(
         width,
         TEXT_SPACING * 3,
         update,
         static,
         dynamic
      )
   end

   return {
      header = 'SYSTEM',
      point = point,
      width = width,
      set_state = nil,
      top = {{mk_stats, true, 0}}
   }
end
