local pure = require 'pure'

return function(main_state, common, width, point)
   local TEXT_SPACING = 20

   local __string_match = string.match
   local __string_gmatch = string.gmatch

   local mk_stats = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         width,
         TEXT_SPACING,
         {'Total', 'Explicit', 'Outdated', 'Orphaned', 'Local'}
      )
      local update = function()
         local stats = __string_match(
            main_state.pacman_stats,
            '%d+%s+[^%s]+%s+[^%s]+%s+(.*)$'
         )
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
         width,
         TEXT_SPACING * 4,
         update,
         pure.partial(common.text_rows_draw_static, obj),
         pure.partial(common.text_rows_draw_dynamic, obj)
      )
   end

   return common.compile_module(
      'PACMAN',
      point,
      width,
      {{mk_stats, true, 0}}
   )
end
