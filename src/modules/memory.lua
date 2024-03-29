local timeseries = require 'timeseries'
local text_table = require 'text_table'
local i_o = require 'i_o'
local pure = require 'pure'
local sys = require 'sys'

return function(update_freq, config, common, width, point)
   local dial_thickness = 8
   local dial_radius = 32
   local dial_x_spacing = 40
   local cache_y_offset = 7
   local cache_x_offset = 50

   local geo = config.geometry
   local plot_sec_break = geo.plot.sec_break
   local plot_height = geo.plot.height
   local table_sec_break = geo.table.sec_break

   local __math_floor = math.floor
   local __string_format = string.format

   -----------------------------------------------------------------------------
   -- state

   local _show_swap = config.show_stats and config.show_swap

   local mod_state = {mem = {total = sys.meminfo_field_reader('MemTotal')()}}
   local update_state

   if _show_swap == true then
      mod_state.swap = {total = sys.meminfo_field_reader('SwapTotal')()}
      update_state = sys.meminfo_updater_swap(mod_state.mem, mod_state.swap)
   else
      update_state = sys.meminfo_updater_noswap(mod_state.mem)
   end

   local read_state = function()
      update_state()
      -- see manpage for free command for formulas
      local m = mod_state.mem
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
      local mem_x = point.x + dial_radius + dial_thickness / 2
      local dial_diameter = dial_radius * 2 + dial_thickness
      local cache_x
      local swap_x
      if _show_swap == true then
         swap_x = mem_x + dial_diameter + dial_x_spacing
         cache_x = swap_x + cache_x_offset + dial_diameter / 2
      else
         cache_x = mem_x + cache_x_offset + dial_diameter / 2
      end
      local cache_width = point.x + width - cache_x
      local format_percent = pure.partial(__string_format, '%i%%', true)

      -- memory bits (used no matter what)
      local mem = common.make_dial(
         mem_x,
         y + dial_radius,
         dial_radius,
         dial_thickness,
         80,
         format_percent,
         __math_floor
      )
      local cache = common.make_text_rows_formatted(
         cache_x,
         y + cache_y_offset,
         cache_width,
         geo.text_spacing,
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
      local ret = pure.partial(common.mk_acc, width, dial_diameter)

      -- add swap bits if needed
      if _show_swap == true then
         local swap = common.make_dial(
            swap_x,
            y + dial_radius,
            dial_radius,
            dial_thickness,
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

   local mk_bare_plot = function(y)
      local obj = common.make_percent_timeseries(
         point.x,
         y,
         width,
         plot_height,
         geo.plot.ticks_y,
         update_freq
      )
      return common.mk_acc(
         width,
         plot_height,
         function() timeseries.update(obj, mod_state.mem.used_percent) end,
         pure.partial(timeseries.draw_static, obj),
         pure.partial(timeseries.draw_dynamic, obj)
      )
   end

   local mk_tagged_plot = function(y)
      local obj = common.make_tagged_percent_timeseries(
         point.x,
         y,
         width,
         plot_height,
         geo.plot.ticks_y,
         plot_sec_break,
         "Total Memory",
         update_freq
      )
      return common.mk_acc(
         width,
         plot_height + plot_sec_break,
         function()
            common.tagged_percent_timeseries_set(
               obj,
               mod_state.mem.used_percent * 100
            )
         end,
         pure.partial(common.tagged_percent_timeseries_draw_static, obj),
         pure.partial(common.tagged_percent_timeseries_draw_dynamic, obj)
      )
   end

   local mk_plot = config.show_stats and mk_bare_plot or mk_tagged_plot

   -----------------------------------------------------------------------------
   -- memory top table

   local mk_tbl = function(y)
      local num_rows = config.table_rows
      local table_conky = pure.map_n(
         function(i)
            return {
               comm = '${top_mem name '..i..'}',
               pid = '${top_mem pid '..i..'}',
               mem = '${top_mem mem '..i..'}',
            }
         end,
         num_rows)
      local obj = common.make_text_table(point.x, y, width, num_rows, 'Mem (%)')
      local update = function()
         -- TODO this is broken in conky 1.12
         for r = 1, num_rows do
            text_table.set(obj, 1, r, i_o.conky(table_conky[r].comm, '(%S+)'))
            text_table.set(obj, 2, r, i_o.conky(table_conky[r].pid))
            -- NOTE: according to the conky source (top.cc) this is just the RSS
            -- of a given process divided by the total memory
            text_table.set(obj, 3, r, i_o.conky(table_conky[r].mem))
         end
      end
      return common.mk_acc(
         width,
         common.table_height(num_rows),
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
         {mk_stats, config.show_stats, plot_sec_break},
         {mk_plot, config.show_plot, table_sec_break},
         {mk_tbl, config.table_rows > 0, 0},
      }
   }
end
