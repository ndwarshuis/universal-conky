local Line = require 'Line'
local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function()
   local FS_PATHS = {'/', '/boot', '/home', '/mnt/data', '/mnt/dcache', "/tmp"}
   local MODULE_Y = 170
   local SPACING = 20
   local BAR_PAD = 100
   local SEPARATOR_SPACING = 20

   -----------------------------------------------------------------------------
   -- header

   local header = Common.Header(
      Geometry.RIGHT_X,
      MODULE_Y,
      Geometry.SECTION_WIDTH,
      'FILE SYSTEMS'
   )

   -----------------------------------------------------------------------------
   -- smartd

   local smart = Common.initTextRow(
      Geometry.RIGHT_X,
      header.bottom_y,
      Geometry.SECTION_WIDTH,
      'SMART Daemon'
   )

   local SEP_Y = header.bottom_y + SEPARATOR_SPACING

   local separator = Common.initSeparator(
      Geometry.RIGHT_X,
      SEP_Y,
      Geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- filesystem bar chart

   local BAR_Y = SEP_Y + SEPARATOR_SPACING

   local fs = Common.compound_bar(
      Geometry.RIGHT_X,
      BAR_Y,
      Geometry.SECTION_WIDTH,
      BAR_PAD,
      {'root', 'boot', 'home', 'data', 'dcache', 'tmpfs'},
      SPACING,
      12,
      0.8
   )

   local FS_NUM = #FS_PATHS
   local CONKY_USED_PERC = {}
   for i, v in pairs(FS_PATHS) do
      CONKY_USED_PERC[i] = '${fs_used_perc '..v..'}'
   end

   -----------------------------------------------------------------------------
   -- main functions

   local update = function(trigger)
      if trigger == 0 then
         local smart_pid = Util.execute_cmd('pidof smartd', nil, '*n')
         Common.text_row_set(smart, (smart_pid == '') and 'Error' or 'Running')

         for i = 1, FS_NUM do
            local percent = Util.conky_numeric(CONKY_USED_PERC[i])
            Common.compound_bar_set(fs, i, percent * 0.01)
         end
      end
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)
      Common.text_row_draw_static(smart, cr)
      Line.draw(separator, cr)
      Common.compound_bar_draw_static(fs, cr)
   end

   local draw_dynamic = function(cr)
      -- if trigger == 0 then update() end
      Common.text_row_draw_dynamic(smart, cr)
      Common.compound_bar_draw_dynamic(fs, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
