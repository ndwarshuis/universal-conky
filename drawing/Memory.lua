local Dial = require 'Dial'
local LabelPlot = require 'LabelPlot'
local Table = require 'Table'
local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local MODULE_Y = 712
   local DIAL_THICKNESS = 8
   local TEXT_Y_OFFSET = 7
   local TEXT_LEFT_X_OFFSET = 30
   local TEXT_SPACING = 20
   local PLOT_SECTION_BREAK = 30
   local PLOT_HEIGHT = 56
   local TABLE_SECTION_BREAK = 20
   local TABLE_HEIGHT = 114

   local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
      '\nBuffers:%s+(%d+).+'..
      '\nCached:%s+(%d+).+'..
      '\nSwapTotal:%s+(%d+).+'..
      '\nSwapFree:%s+(%d+).+'..
      '\nSReclaimable:%s+(%d+)'

   local __string_match	= string.match

   -----------------------------------------------------------------------------
   -- header

   local header = Common.Header(
      Geometry.RIGHT_X,
      MODULE_Y,
      Geometry.SECTION_WIDTH,
      'MEMORY'
   )

   -----------------------------------------------------------------------------
   -- mem consumption dial

   local mem_total_kb = tonumber(Util.read_file('/proc/meminfo', '^MemTotal:%s+(%d+)'))

   local DIAL_RADIUS = 32
   local DIAL_X = Geometry.RIGHT_X + DIAL_RADIUS + DIAL_THICKNESS / 2
   local DIAL_Y = header.bottom_y + DIAL_RADIUS + DIAL_THICKNESS / 2

   local dial = Common.dial(DIAL_X, DIAL_Y, DIAL_RADIUS, DIAL_THICKNESS, 0.8)
   local text_ring = Common.initTextRing(
      DIAL_X,
      DIAL_Y,
      DIAL_RADIUS - DIAL_THICKNESS / 2 - 2,
      '%s%%',
      80
   )

   -----------------------------------------------------------------------------
   -- swap/buffers stats

   local LINE_1_Y = header.bottom_y + TEXT_Y_OFFSET
   local TEXT_LEFT_X = Geometry.RIGHT_X + DIAL_RADIUS * 2 + TEXT_LEFT_X_OFFSET
   local SWAP_BUFFERS_WIDTH = Geometry.SECTION_WIDTH - TEXT_LEFT_X_OFFSET
      - DIAL_RADIUS * 2

   local swap = Common.initTextRowCrit(
      TEXT_LEFT_X,
      LINE_1_Y,
      SWAP_BUFFERS_WIDTH,
      'Swap Usage',
      '%s%%',
      80
   )

   local cache = Common.initTextRows_formatted(
      TEXT_LEFT_X,
      LINE_1_Y + TEXT_SPACING,
      SWAP_BUFFERS_WIDTH,
      TEXT_SPACING,
      {'Page Cache', 'Buffers', 'Kernel Slab'},
      '%s%%'
   )

   -----------------------------------------------------------------------------
   -- memory consumption plot

   local PLOT_Y = PLOT_SECTION_BREAK + header.bottom_y + DIAL_RADIUS * 2

   local plot = Common.initThemedLabelPlot(
      Geometry.RIGHT_X,
      PLOT_Y,
      Geometry.SECTION_WIDTH,
      PLOT_HEIGHT,
      Common.percent_label_style,
      update_freq
   )

   -----------------------------------------------------------------------------
   -- memory top table

   local NUM_ROWS = 5
   local TABLE_CONKY = {}
   for r = 1, NUM_ROWS do
      TABLE_CONKY[r] = {
         comm = '${top_mem name '..r..'}',
         pid = '${top_mem pid '..r..'}',
         mem = '${top_mem mem '..r..'}',
      }
   end

   local tbl = Common.initTable(
      Geometry.RIGHT_X,
      PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK,
      Geometry.SECTION_WIDTH,
      TABLE_HEIGHT,
      NUM_ROWS,
      {'Name', 'PID', 'Mem (%)'}
   )

   -----------------------------------------------------------------------------
   -- main functions

   local update = function(cr)
      local conky = Util.conky
      -- see source for the 'free' command (sysinfo.c) for formulas

      local memfree_kb,
         buffers_kb,
         cached_kb,
         swap_total_kb,
         swap_free_kb,
         slab_reclaimable_kb
         = __string_match(Util.read_file('/proc/meminfo'), MEMINFO_REGEX)

      local used_percent = (mem_total_kb - memfree_kb - cached_kb - buffers_kb - slab_reclaimable_kb) / mem_total_kb

      Dial.set(dial, used_percent)
      Common.text_ring_set(text_ring, cr, Util.round_to_string(used_percent * 100))

      Common.text_row_crit_set(swap, cr,
                               Util.precision_round_to_string(
                                  (swap_total_kb - swap_free_kb)
                                  / swap_total_kb * 100))

      Common.text_rows_set(cache, cr, 1, Util.precision_round_to_string(
                              cached_kb / mem_total_kb * 100))

      Common.text_rows_set(cache, cr, 2, Util.precision_round_to_string(
                              buffers_kb / mem_total_kb * 100))

      Common.text_rows_set(cache, cr, 3, Util.precision_round_to_string(
                              slab_reclaimable_kb / mem_total_kb * 100))

      LabelPlot.update(plot, used_percent)

      for r = 1, NUM_ROWS do
         Table.set(tbl, cr, 1, r, conky(TABLE_CONKY[r].comm, '(%S+)'))
         Table.set(tbl, cr, 2, r, conky(TABLE_CONKY[r].pid))
         Table.set(tbl, cr, 3, r, conky(TABLE_CONKY[r].mem))
      end
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)

      Common.text_ring_draw_static(text_ring, cr)
      Dial.draw_static(dial, cr)

      Common.text_row_crit_draw_static(swap, cr)
      Common.text_rows_draw_static(cache, cr)
      LabelPlot.draw_static(plot, cr)

      Table.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr)
      update(cr)

      Dial.draw_dynamic(dial, cr)
      Common.text_ring_draw_dynamic(text_ring, cr)

      Common.text_row_crit_draw_dynamic(swap, cr)
      Common.text_rows_draw_dynamic(cache, cr)

      LabelPlot.draw_dynamic(plot, cr)

      Table.draw_dynamic(tbl, cr)
   end

   return {dynamic = draw_dynamic, static = draw_static}
end
