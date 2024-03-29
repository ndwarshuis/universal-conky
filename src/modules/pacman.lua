local pure = require 'pure'

return function(main_state, config, common, width, point)
   local text_spacing = config.geometry.text_spacing

   local __string_match = string.match
   local __string_gmatch = string.gmatch

   local mk_stats = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         width,
         text_spacing,
         {'Total', 'Explicit', 'Outdated', 'Orphaned', 'Local'}
      )
      local update = function()
         if main_state.pacman_stats then
            local stats = __string_match(
               main_state.pacman_stats,
               '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$'
            )
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
         width,
         text_spacing * 4,
         update,
         pure.partial(common.text_rows_draw_static, obj),
         pure.partial(common.text_rows_draw_dynamic, obj)
      )
   end

   return {
      header = 'PACMAN',
      point = point,
      width = width,
      set_state = nil,
      top = {{mk_stats, true, 0}}
   }
end
