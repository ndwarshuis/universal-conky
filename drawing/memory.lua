local timeseries = require 'timeseries'
local text_table = require 'text_table'
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

   local __string_match	= string.match
   local __math_floor = math.floor

   -----------------------------------------------------------------------------
   -- header

   local mk_header = pure.partial(
      common.mk_header,
      'MEMORY',
      geometry.SECTION_WIDTH,
      geometry.RIGHT_X
   )

   -----------------------------------------------------------------------------
   -- mem stats (dial + text)

   local mk_stats = function(y)
      local MEM_X = geometry.RIGHT_X + DIAL_RADIUS + DIAL_THICKNESS / 2
      local DIAL_DIAMETER = DIAL_RADIUS * 2 + DIAL_THICKNESS
      local SWAP_X = MEM_X + DIAL_DIAMETER + DIAL_SPACING
      local CACHE_X = SWAP_X + CACHE_X_OFFSET + DIAL_DIAMETER / 2
      local CACHE_WIDTH = geometry.RIGHT_X + geometry.SECTION_WIDTH - CACHE_X
      local format_percent = function(x)
         return string.format('%i%%', x)
      end
      local mem = common.make_dial(
         MEM_X,
         y + DIAL_RADIUS,
         DIAL_RADIUS,
         DIAL_THICKNESS,
         80,
         format_percent,
         __math_floor
      )
      local swap = common.make_dial(
         SWAP_X,
         y + DIAL_RADIUS,
         DIAL_RADIUS,
         DIAL_THICKNESS,
         80,
         format_percent,
         __math_floor
      )
      local cache = common.make_text_rows_formatted(
         CACHE_X,
         y + CACHE_Y_OFFSET,
         CACHE_WIDTH,
         TEXT_SPACING,
         {'Page Cache', 'Buffers', 'Shared', 'Kernel Slab'},
         '%.1f%%'
      )
      local update = function(s)
         local m = s.mem
         local w = s.swap
         common.dial_set(mem, m.used_percent * 100)
         common.dial_set(swap, (w.total - w.free) / w.total * 100)

         common.text_rows_set(cache, 1, m.cached / m.total * 100)
         common.text_rows_set(cache, 2, m.buffers / m.total * 100)
         common.text_rows_set(cache, 3, m.shmem / m.total * 100)
         common.text_rows_set(cache, 4, m.sreclaimable / m.total * 100)
      end
      local static = function(cr)
         common.dial_draw_static(mem, cr)
         common.dial_draw_static(swap, cr)
         common.text_rows_draw_static(cache, cr)
      end
      local dynamic = function(cr)
         common.dial_draw_dynamic(mem, cr)
         common.dial_draw_dynamic(swap, cr)
         common.text_rows_draw_dynamic(cache, cr)
      end
      return common.mk_acc(DIAL_DIAMETER, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- memory consumption plot

   local mk_plot = function(y)
      local obj = common.make_percent_timeseries(
         geometry.RIGHT_X,
         y,
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         update_freq
      )
      return common.mk_acc(
         PLOT_HEIGHT,
         function(s) timeseries.update(obj, s.mem.used_percent) end,
         pure.partial(timeseries.draw_static, obj),
         pure.partial(timeseries.draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- memory top table

   local mk_tbl = function(y)
      local NUM_ROWS = 5
      local TABLE_CONKY = pure.map_n(
         function(i)
            return {
               comm = '${top_mem name '..i..'}',
               pid = '${top_mem pid '..i..'}',
               mem = '${top_mem mem '..i..'}',
            }
         end,
         NUM_ROWS)
      local obj = common.make_text_table(
         geometry.RIGHT_X,
         y,
         geometry.SECTION_WIDTH,
         TABLE_HEIGHT,
         NUM_ROWS,
         'Mem (%)'
      )
      local update = function(_)
         for r = 1, NUM_ROWS do
            text_table.set(obj, 1, r, i_o.conky(TABLE_CONKY[r].comm, '(%S+)'))
            text_table.set(obj, 2, r, i_o.conky(TABLE_CONKY[r].pid))
            text_table.set(obj, 3, r, i_o.conky(TABLE_CONKY[r].mem))
         end
      end
      return common.mk_acc(
         TABLE_HEIGHT,
         update,
         pure.partial(text_table.draw_static, obj),
         pure.partial(text_table.draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- state

   local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
      '\nBuffers:%s+(%d+).+'..
      '\nCached:%s+(%d+).+'..
      '\nSwapFree:%s+(%d+).+'..
      '\nShmem:%s+(%d+).+'..
      '\nSReclaimable:%s+(%d+)'

   local get_meminfo_field = function(field)
      return tonumber(i_o.read_file('/proc/meminfo', field..':%s+(%d+)'))
   end

   local state = {
      mem = {total = get_meminfo_field('MemTotal')},
      swap = {total = get_meminfo_field('SwapTotal')}
   }
   local read_state = function()
      local m = state.mem
      -- see manpage for free command for formulas
      m.memfree,
         m.buffers,
         m.cached,
         state.swap.free,
         m.shmem,
         m.sreclaimable
         = __string_match(i_o.read_file('/proc/meminfo'), MEMINFO_REGEX)
      m.used_percent =
         (m.total -
          m.memfree -
          m.cached -
          m.buffers -
          m.sreclaimable) / m.total
      return state
   end

   -----------------------------------------------------------------------------
   -- main functions

   local rbs = common.reduce_blocks_(
      MODULE_Y,
      {
         common.mk_block(mk_header, true, 0),
         common.mk_block(mk_stats, true, 0),
         common.mk_block(mk_plot, true, PLOT_SECTION_BREAK),
         common.mk_block(mk_tbl, true, TABLE_SECTION_BREAK),
      }
   )

   return {
      static = rbs.static_drawer,
      dynamic = rbs.dynamic_drawer,
      update = function() rbs.updater(read_state()) end,
   }
end
