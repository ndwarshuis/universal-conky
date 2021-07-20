local Timeseries = require 'Timeseries'
local Table = require 'Table'
local Util = require 'Util'
local Common = require 'Common'
local Geometry = require 'Geometry'

return function(update_freq)
   local MODULE_Y = 712
   local DIAL_THICKNESS = 8
   local DIAL_RADIUS = 32
   local DIAL_SPACING = 40
   local CACHE_Y_OFFSET = 7
   local CACHE_X_OFFSET = 50
   local TEXT_SPACING = 20
   local PLOT_SECTION_BREAK = 22
   local PLOT_HEIGHT = 56
   local TABLE_SECTION_BREAK = 20
   local TABLE_HEIGHT = 114

   local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
      '\nBuffers:%s+(%d+).+'..
      '\nCached:%s+(%d+).+'..
      '\nSwapFree:%s+(%d+).+'..
      '\nShmem:%s+(%d+).+'..
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

   local get_meminfo_field = function(field)
      return tonumber(Util.read_file('/proc/meminfo', field..':%s+(%d+)'))
   end

   local memtotal = get_meminfo_field('MemTotal')
   local swaptotal = get_meminfo_field('SwapTotal')

   local FORMAT_PERCENT = function(x)
      return string.format('%.0f%%', x * 100)
   end

   local MEM_X = Geometry.RIGHT_X + DIAL_RADIUS + DIAL_THICKNESS / 2
   local MEM_Y = header.bottom_y + DIAL_RADIUS + DIAL_THICKNESS / 2
   local DIAL_DIAMETER = DIAL_RADIUS * 2 + DIAL_THICKNESS

   local mem = Common.dial(
      MEM_X,
      MEM_Y,
      DIAL_RADIUS,
      DIAL_THICKNESS,
      0.8,
      FORMAT_PERCENT
   )

   -----------------------------------------------------------------------------
   -- swap consumption dial

   local SWAP_X = MEM_X + DIAL_DIAMETER + DIAL_SPACING

   local swap = Common.dial(
      SWAP_X,
      MEM_Y,
      DIAL_RADIUS,
      DIAL_THICKNESS,
      0.8,
      FORMAT_PERCENT
   )

   -----------------------------------------------------------------------------
   -- swap/buffers stats

   local CACHE_Y = header.bottom_y + CACHE_Y_OFFSET
   local CACHE_X = SWAP_X + CACHE_X_OFFSET + DIAL_DIAMETER / 2
   local CACHE_WIDTH = Geometry.RIGHT_X + Geometry.SECTION_WIDTH - CACHE_X

   local cache = Common.initTextRows_formatted(
      CACHE_X,
      CACHE_Y,
      CACHE_WIDTH,
      TEXT_SPACING,
      {'Page Cache', 'Buffers', 'Shared', 'Kernel Slab'},
      '%.1f%%'
   )

   -----------------------------------------------------------------------------
   -- memory consumption plot

   local PLOT_Y = header.bottom_y + PLOT_SECTION_BREAK + DIAL_DIAMETER

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
      -- see manpage for free command for formulas

      local memfree,
         buffers,
         cached,
         swapfree,
         shmem,
         sreclaimable
         = __string_match(Util.read_file('/proc/meminfo'), MEMINFO_REGEX)

      local used_percent =
         (memtotal -
          memfree -
          cached -
          buffers -
          sreclaimable) / memtotal

      Common.dial_set(mem, cr, used_percent)
      Common.dial_set(swap, cr, (swaptotal - swapfree) / swaptotal)

      Common.text_rows_set(cache, cr, 1, cached / memtotal * 100)
      Common.text_rows_set(cache, cr, 2, buffers / memtotal * 100)
      Common.text_rows_set(cache, cr, 3, shmem / memtotal * 100)
      Common.text_rows_set(cache, cr, 4, sreclaimable / memtotal * 100)

      Timeseries.update(plot, used_percent)

      for r = 1, NUM_ROWS do
         Table.set(tbl, cr, 1, r, conky(TABLE_CONKY[r].comm, '(%S+)'))
         Table.set(tbl, cr, 2, r, conky(TABLE_CONKY[r].pid))
         Table.set(tbl, cr, 3, r, conky(TABLE_CONKY[r].mem))
      end
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)

      Common.dial_draw_static(mem, cr)
      Common.dial_draw_static(swap, cr)

      Common.text_rows_draw_static(cache, cr)
      Timeseries.draw_static(plot, cr)

      Table.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr)
      update(cr)

      Common.dial_draw_dynamic(mem, cr)
      Common.dial_draw_dynamic(swap, cr)

      Common.text_rows_draw_dynamic(cache, cr)

      Timeseries.draw_dynamic(plot, cr)

      Table.draw_dynamic(tbl, cr)
   end

   return {dynamic = draw_dynamic, static = draw_static}
end
