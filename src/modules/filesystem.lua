local i_o = require 'i_o'
local pure = require 'pure'
local impure = require 'impure'

return function(config, main_state, common, width, point)
   local SPACING = 20
   local BAR_PAD = 100
   local SEPARATOR_SPACING = 20

   -----------------------------------------------------------------------------
   -- smartd

   i_o.assert_exe_exists('pidof')

   local mk_smart = function(y)
      local obj = common.make_text_row(point.x, y, width, 'SMART Daemon')
      local update = function()
         if main_state.trigger10 == 0 then
            local pid = i_o.execute_cmd('pidof smartd', nil, '*n')
            common.text_row_set(obj, (pid == '') and 'Error' or 'Running')
         end
      end
      return common.mk_acc(
         width,
         0,
         update,
         pure.partial(common.text_row_draw_static, obj),
         pure.partial(common.text_row_draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- filesystem bar chart

   local mk_bars = function(y)
      local paths = pure.map_keys('path', config.fs_paths)
      local names = pure.map_keys('name', config.fs_paths)
      -- TODO this might not be enough (conky might actually need +x permissions
      -- to decend into the dir and read its contents)
      impure.each(i_o.assert_file_exists, paths)
      local CONKY_CMDS = pure.map(
         pure.partial(string.format, '${fs_used_perc %s}', true),
         paths
      )
      local obj = common.make_compound_bar(
         point.x,
         y,
         width,
         BAR_PAD,
         names,
         SPACING,
         12,
         80
      )
      local read_fs = function(index, cmd)
         common.compound_bar_set(obj, index, i_o.conky_numeric(cmd))
      end
      local update = function()
         if main_state.trigger10 == 0 then
            impure.ieach(read_fs, CONKY_CMDS)
         end
      end
      return common.mk_acc(
         width,
         (#config.fs_paths - 1) * SPACING,
         update,
         pure.partial(common.compound_bar_draw_static, obj),
         pure.partial(common.compound_bar_draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- main functions

   return {
      header = 'FILE SYSTEMS',
      point = point,
      width = width,
      set_state = nil,
      top = {{mk_smart, config.show_smart, SEPARATOR_SPACING}},
      common.mk_section(SEPARATOR_SPACING, {mk_bars, true, 0})
   }
end
