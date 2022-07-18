local timeseries = require 'timeseries'
local text_table = require 'text_table'
local i_o = require 'i_o'
local pure = require 'pure'

return function(update_freq, config, common, width, point)
   local DIAL_THICKNESS = 8
   local DIAL_RADIUS = 32
   local DIAL_SPACING = 40
   local CACHE_Y_OFFSET = 7
   local CACHE_X_OFFSET = 50
   local TEXT_SPACING = 20
   local PLOT_SECTION_BREAK = 22
   local PLOT_HEIGHT = 56
   local TABLE_SECTION_BREAK = 20

   local __string_match	= string.match
   local __math_floor = math.floor

   -----------------------------------------------------------------------------
   -- state

   local use_swap = false

   local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
      '\nBuffers:%s+(%d+).+'..
      '\nCached:%s+(%d+).+'..
      '\nSwapFree:%s+(%d+).+'..
      '\nShmem:%s+(%d+).+'..
      '\nSReclaimable:%s+(%d+)'

   local get_meminfo_field = function(field)
      return tonumber(i_o.read_file('/proc/meminfo', field..':%s+(%d+)'))
   end

   local mod_state = {
      mem = {total = get_meminfo_field('MemTotal')},
      swap = {total = get_meminfo_field('SwapTotal')}
   }
   local read_state = function()
      local m = mod_state.mem
      -- see manpage for free command for formulas
      m.memfree,
         m.buffers,
         m.cached,
         mod_state.swap.free,
         m.shmem,
         m.sreclaimable
         = __string_match(i_o.read_file('/proc/meminfo'), MEMINFO_REGEX)
      m.used_percent =
         (m.total -
          m.memfree -
          m.cached -
          m.buffers -
          m.sreclaimable) / m.total
   end


   -----------------------------------------------------------------------------
   -- mem stats (dial + text)

   local mk_stats = function(y)
      local MEM_X = point.x + DIAL_RADIUS + DIAL_THICKNESS / 2
      local DIAL_DIAMETER = DIAL_RADIUS * 2 + DIAL_THICKNESS
      local CACHE_X
      local SWAP_X
      if use_swap == true then
         SWAP_X = MEM_X + DIAL_DIAMETER + DIAL_SPACING
         CACHE_X = SWAP_X + CACHE_X_OFFSET + DIAL_DIAMETER / 2
      else
         CACHE_X = MEM_X + CACHE_X_OFFSET + DIAL_DIAMETER / 2
      end
      local CACHE_WIDTH = point.x + width - CACHE_X
      local format_percent = function(x)
         return string.format('%i%%', x)
      end

      -- memory bits (used no matter what)
      local mem = common.make_dial(
         MEM_X,
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
      local update_mem = function()
         local m = mod_state.mem
         local mtot = m.total
         common.dial_set(mem, m.used_percent * 100)

         common.text_rows_set(cache, 1, m.cached / mtot * 100)
         common.text_rows_set(cache, 2, m.buffers / mtot * 100)
         common.text_rows_set(cache, 3, m.shmem / mtot * 100)
         common.text_rows_set(cache, 4, m.sreclaimable / mtot * 100)
      end
      local static_mem = function(cr)
         common.dial_draw_static(mem, cr)
         common.text_rows_draw_static(cache, cr)
      end
      local dynamic_mem = function(cr)
         common.dial_draw_dynamic(mem, cr)
         common.text_rows_draw_dynamic(cache, cr)
      end
      local ret = pure.partial(common.mk_acc, width, DIAL_DIAMETER)

      -- add swap bits if needed
      if use_swap == true then
         local swap = common.make_dial(
            SWAP_X,
            y + DIAL_RADIUS,
            DIAL_RADIUS,
            DIAL_THICKNESS,
            80,
            format_percent,
            __math_floor
         )
         local update_swap = function()
            local w = mod_state.swap
            common.dial_set(swap, (w.total - w.free) / w.total * 100)
         end
         local static_swap = pure.partial(common.dial_draw_static, swap)
         local dynamic_swap = pure.partial(common.dial_draw_dynamic, swap)
         return ret(
            pure.sequence(update_mem, update_swap),
            pure.sequence(static_mem, static_swap),
            pure.sequence(dynamic_mem, dynamic_swap)
         )
      else
         return ret(update_mem, static_mem, dynamic_mem)
      end
   end

   -----------------------------------------------------------------------------
   -- memory consumption plot

   local mk_plot = function(y)
      local obj = common.make_percent_timeseries(
         point.x,
         y,
         width,
         PLOT_HEIGHT,
         update_freq
      )
      return common.mk_acc(
         width,
         PLOT_HEIGHT,
         function() timeseries.update(obj, mod_state.mem.used_percent) end,
         pure.partial(timeseries.draw_static, obj),
         pure.partial(timeseries.draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- memory top table

   local mk_tbl = function(y)
      local num_rows = config.table_rows
      local table_height = common.table_height(num_rows)
      local table_conky = pure.map_n(
         function(i)
            return {
               comm = '${top_mem name '..i..'}',
               pid = '${top_mem pid '..i..'}',
               mem = '${top_mem mem '..i..'}',
            }
         end,
         num_rows)
      local obj = common.make_text_table(
         point.x,
         y,
         width,
         table_height,
         num_rows,
         'Mem (%)'
      )
      local update = function()
         for r = 1, num_rows do
            text_table.set(obj, 1, r, i_o.conky(table_conky[r].comm, '(%S+)'))
            text_table.set(obj, 2, r, i_o.conky(table_conky[r].pid))
            text_table.set(obj, 3, r, i_o.conky(table_conky[r].mem))
         end
      end
      return common.mk_acc(
         width,
         table_height,
         update,
         pure.partial(text_table.draw_static, obj),
         pure.partial(text_table.draw_dynamic, obj)
      )
   end

   -----------------------------------------------------------------------------
   -- main functions

   return {
      header = 'MEMORY',
      point = point,
      width = width,
      set_state = read_state,
      top = {
         {mk_stats, config.show_stats, PLOT_SECTION_BREAK},
         {mk_plot, config.show_plot, TABLE_SECTION_BREAK},
         {mk_tbl, config.table_rows > 0, 0},
      }
   }
end
