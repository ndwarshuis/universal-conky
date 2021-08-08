local timeseries = require 'timeseries'
local texttable = require 'texttable'
local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'
local pure = require 'pure'

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

   local header = common.make_header(
      geometry.RIGHT_X,
      MODULE_Y,
      geometry.SECTION_WIDTH,
      'MEMORY'
   )

   -----------------------------------------------------------------------------
   -- mem consumption dial

   local get_meminfo_field = function(field)
      return tonumber(i_o.read_file('/proc/meminfo', field..':%s+(%d+)'))
   end

   local memtotal = get_meminfo_field('MemTotal')
   local swaptotal = get_meminfo_field('SwapTotal')

   local FORMAT_PERCENT = function(x)
      return string.format('%.0f%%', x * 100)
   end

   local MEM_X = geometry.RIGHT_X + DIAL_RADIUS + DIAL_THICKNESS / 2
   local MEM_Y = header.bottom_y + DIAL_RADIUS + DIAL_THICKNESS / 2
   local DIAL_DIAMETER = DIAL_RADIUS * 2 + DIAL_THICKNESS

   local mem = common.make_dial(
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

   local swap = common.make_dial(
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
   local CACHE_WIDTH = geometry.RIGHT_X + geometry.SECTION_WIDTH - CACHE_X

   local cache = common.make_text_rows_formatted(
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

   local plot = common.make_percent_timeseries(
      geometry.RIGHT_X,
      PLOT_Y,
      geometry.SECTION_WIDTH,
      PLOT_HEIGHT,
      update_freq
   )

   -----------------------------------------------------------------------------
   -- memory top table

   local NUM_ROWS = 5
   local TABLE_CONKY = pure.map(
      function(i)
         return {
            comm = '${top_mem name '..i..'}',
            pid = '${top_mem pid '..i..'}',
            mem = '${top_mem mem '..i..'}',
         }
      end,
      pure.seq(NUM_ROWS))

   local tbl = common.make_text_table(
      geometry.RIGHT_X,
      PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK,
      geometry.SECTION_WIDTH,
      TABLE_HEIGHT,
      NUM_ROWS,
      {'Name', 'PID', 'Mem (%)'}
   )

   -----------------------------------------------------------------------------
   -- main functions

   local update = function()
      -- see manpage for free command for formulas
      local memfree,
         buffers,
         cached,
         swapfree,
         shmem,
         sreclaimable
         = __string_match(i_o.read_file('/proc/meminfo'), MEMINFO_REGEX)

      local used_percent =
         (memtotal -
          memfree -
          cached -
          buffers -
          sreclaimable) / memtotal

      common.dial_set(mem, used_percent)
      common.dial_set(swap, (swaptotal - swapfree) / swaptotal)

      common.text_rows_set(cache, 1, cached / memtotal * 100)
      common.text_rows_set(cache, 2, buffers / memtotal * 100)
      common.text_rows_set(cache, 3, shmem / memtotal * 100)
      common.text_rows_set(cache, 4, sreclaimable / memtotal * 100)

      timeseries.update(plot, used_percent)

      for r = 1, NUM_ROWS do
         texttable.set(tbl, 1, r, i_o.conky(TABLE_CONKY[r].comm, '(%S+)'))
         texttable.set(tbl, 2, r, i_o.conky(TABLE_CONKY[r].pid))
         texttable.set(tbl, 3, r, i_o.conky(TABLE_CONKY[r].mem))
      end
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)
      common.dial_draw_static(mem, cr)
      common.dial_draw_static(swap, cr)
      common.text_rows_draw_static(cache, cr)
      timeseries.draw_static(plot, cr)
      texttable.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr)
      common.dial_draw_dynamic(mem, cr)
      common.dial_draw_dynamic(swap, cr)
      common.text_rows_draw_dynamic(cache, cr)
      timeseries.draw_dynamic(plot, cr)
      texttable.draw_dynamic(tbl, cr)
   end

   return {dynamic = draw_dynamic, static = draw_static, update = update}
end
