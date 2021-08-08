local line = require 'line'
local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'

return function()
   local FS_PATHS = {'/', '/boot', '/home', '/mnt/data', '/mnt/dcache', "/tmp"}
   local MODULE_Y = 170
   local SPACING = 20
   local BAR_PAD = 100
   local SEPARATOR_SPACING = 20

   -----------------------------------------------------------------------------
   -- header

   local header = common.make_header(
      geometry.RIGHT_X,
      MODULE_Y,
      geometry.SECTION_WIDTH,
      'FILE SYSTEMS'
   )

   -----------------------------------------------------------------------------
   -- smartd

   local smart = common.make_text_row(
      geometry.RIGHT_X,
      header.bottom_y,
      geometry.SECTION_WIDTH,
      'SMART Daemon'
   )

   local SEP_Y = header.bottom_y + SEPARATOR_SPACING

   local separator = common.make_separator(
      geometry.RIGHT_X,
      SEP_Y,
      geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- filesystem bar chart

   local BAR_Y = SEP_Y + SEPARATOR_SPACING

   local fs = common.make_compound_bar(
      geometry.RIGHT_X,
      BAR_Y,
      geometry.SECTION_WIDTH,
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
         local smart_pid = i_o.execute_cmd('pidof smartd', nil, '*n')
         common.text_row_set(smart, (smart_pid == '') and 'Error' or 'Running')

         for i = 1, FS_NUM do
            local percent = i_o.conky_numeric(CONKY_USED_PERC[i])
            common.compound_bar_set(fs, i, percent * 0.01)
         end
      end
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)
      common.text_row_draw_static(smart, cr)
      line.draw(separator, cr)
      common.compound_bar_draw_static(fs, cr)
   end

   local draw_dynamic = function(cr)
      common.text_row_draw_dynamic(smart, cr)
      common.compound_bar_draw_dynamic(fs, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
