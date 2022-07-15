local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'
local pure = require 'pure'
local impure = require 'impure'

return function(pathspecs, point)
   local SPACING = 20
   local BAR_PAD = 100
   local SEPARATOR_SPACING = 20

   -----------------------------------------------------------------------------
   -- header

   local mk_header = pure.partial(
      common.mk_header,
      'FILE SYSTEMS',
      geometry.SECTION_WIDTH,
      point.x
   )

   -----------------------------------------------------------------------------
   -- smartd

   local mk_smart = function(y)
      local obj = common.make_text_row(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         'SMART Daemon'
      )
      local update = function(trigger)
         if trigger == 0 then
            local pid = i_o.execute_cmd('pidof smartd', nil, '*n')
            common.text_row_set(obj, (pid == '') and 'Error' or 'Running')
         end
      end
      return common.mk_acc(
         0,
         update,
         pure.partial(common.text_row_draw_static, obj),
         pure.partial(common.text_row_draw_dynamic, obj)
      )
   end

   local mk_sep = pure.partial(
      common.mk_seperator,
      geometry.SECTION_WIDTH,
      point.x
   )

   -----------------------------------------------------------------------------
   -- filesystem bar chart

   local mk_bars = function(y)
      local paths, names = table.unpack(pure.unzip(pathspecs))
      local CONKY_CMDS = pure.map(
         pure.partial(string.format, '${fs_used_perc %s}', true),
         paths
      )
      local obj = common.make_compound_bar(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         BAR_PAD,
         names,
         SPACING,
         12,
         80
      )
      local read_fs = function(index, cmd)
         common.compound_bar_set(obj, index, i_o.conky_numeric(cmd))
      end
      local update = function(trigger)
         if trigger == 0 then
            impure.ieach(read_fs, CONKY_CMDS)
         end
      end
      return common.mk_acc(
         (#pathspecs - 1) * SPACING,
         update,
         pure.partial(common.compound_bar_draw_static, obj),
         pure.partial(common.compound_bar_draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- main functions

   return common.reduce_blocks_(
      point.y,
      {
         common.mk_block(mk_header, true, 0),
         common.mk_block(mk_smart, true, 0),
         common.mk_block(mk_sep, true, SEPARATOR_SPACING),
         common.mk_block(mk_bars, true, SEPARATOR_SPACING),
      }
   )
end
