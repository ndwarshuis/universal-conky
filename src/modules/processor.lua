local compound_dial = require 'compound_dial'
local text_table = require 'text_table'
local i_o = require 'i_o'
local cpu = require 'sys'
local pure = require 'pure'

local __math_floor = math.floor

return function(update_freq, config, main_state, common, width, point)
   local DIAL_INNER_RADIUS = 30
   local DIAL_OUTER_RADIUS = 42
   local DIAL_THICKNESS = 5.5
   local DIAL_SPACING = 20
   local SEPARATOR_SPACING = 20
   local TEXT_SPACING = 22
   local PLOT_SECTION_BREAK = 23
   local PLOT_HEIGHT = 56
   local TABLE_SECTION_BREAK = 20

   -----------------------------------------------------------------------------
   -- processor state

   local mod_state = cpu.read_cpu_loads(cpu.init_cpu_loads())

   local update_state = function()
      mod_state = cpu.read_cpu_loads(mod_state)
   end

   -----------------------------------------------------------------------------
   -- cores (loads and temps)

   local ncpus = cpu.get_cpu_number()
   local ncores = cpu.get_core_number()
   local nthreads = ncpus / ncores

   local show_cores = false

   if config.core_rows > 0 then
      if math.fmod(ncores, config.core_rows) == 0 then
         show_cores = true
      else
         i_o.warnf(
            'could not evenly distribute %i cores over %i rows; disabling',
            ncores,
            config.core_rows
         )
      end
   end

   local create_core = function(x, y)
      return {
         loads = common.make_compound_dial(
            x,
            y,
            DIAL_OUTER_RADIUS,
            DIAL_INNER_RADIUS,
            DIAL_THICKNESS,
            80,
            nthreads
         ),
         coretemp = common.make_text_circle(
            x,
            y,
            DIAL_INNER_RADIUS - 2,
            '%s°C',
            80,
            __math_floor
         )
      }
   end

   local mk_cores = function(y)
      local coretemp_paths = cpu.get_coretemp_paths()
      local core_cols = ncores / config.core_rows
      local cores = {}
      for c = 1, ncores do
         local dial_x = point.x +
            (core_cols == 1
             and (width / 2)
             or (config.core_padding + DIAL_OUTER_RADIUS +
                 (width - 2 * (DIAL_OUTER_RADIUS + config.core_padding))
                 * math.fmod(c - 1, core_cols) / (core_cols - 1)))
         local dial_y = y + DIAL_OUTER_RADIUS +
            (2 * DIAL_OUTER_RADIUS + DIAL_SPACING)
            * math.floor((c - 1) / core_cols)
         cores[c] = create_core(dial_x, dial_y)
      end
      local update = function()
         for _, load_data in pairs(mod_state) do
            compound_dial.set(
               cores[load_data.conky_core_id].loads,
               load_data.conky_thread_id,
               load_data.percent_active * 100
            )
         end
         for conky_core_id, path in pairs(coretemp_paths) do
            local temp = __math_floor(0.001 * i_o.read_file(path, nil, '*n'))
            common.text_circle_set(cores[conky_core_id].coretemp, temp)
         end
      end
      local static = function(cr)
         for i = 1, #cores do
            common.text_circle_draw_static(cores[i].coretemp, cr)
            compound_dial.draw_static(cores[i].loads, cr)
         end
      end
      local dynamic = function(cr)
         for i = 1, #cores do
            common.text_circle_draw_dynamic(cores[i].coretemp, cr)
            compound_dial.draw_dynamic(cores[i].loads, cr)
         end
      end
      return common.mk_acc(
         width,
         (DIAL_OUTER_RADIUS * 2 + DIAL_SPACING) * config.core_rows
         - DIAL_SPACING,
         update,
         static,
         dynamic
      )
   end

   -----------------------------------------------------------------------------
   -- HWP status

   local mk_hwp_freq = function(y)
      local hwp_paths = cpu.get_hwp_paths()
      local cpu_status = common.make_text_rows(
         point.x,
         y,
         width,
         TEXT_SPACING,
         {'HWP Preference', 'Ave Freq'}
      )
      local update = function()
         -- For some reason this call is slow (querying anything with pstate in
         -- general seems slow), but I also don't need to see an update every
         -- cycle, hence the trigger
         if main_state.trigger10 == 0 then
            common.text_rows_set(cpu_status, 1, cpu.read_hwp(hwp_paths))
         end
         common.text_rows_set(cpu_status, 2, cpu.read_freq())
      end
      local static = pure.partial(common.text_rows_draw_static, cpu_status)
      local dynamic = pure.partial(common.text_rows_draw_dynamic, cpu_status)
      return common.mk_acc(
         width,
         TEXT_SPACING,
         update,
         static,
         dynamic
      )
   end

   -----------------------------------------------------------------------------
   -- total load plot

   local mk_load_plot = function(y)
      local total_load = common.make_tagged_percent_timeseries(
         point.x,
         y,
         width,
         PLOT_HEIGHT,
         PLOT_SECTION_BREAK,
         "Total Load",
         update_freq
      )
      local update = function()
         local s = 0
         for i = 1, #mod_state do
            s = s + mod_state[i].percent_active
         end
         common.tagged_percent_timeseries_set(total_load, s / ncpus * 100)
      end
      return common.mk_acc(
         width,
         PLOT_HEIGHT + PLOT_SECTION_BREAK,
         update,
         pure.partial(common.tagged_percent_timeseries_draw_static, total_load),
         pure.partial(common.tagged_percent_timeseries_draw_dynamic, total_load)
      )
   end

   -----------------------------------------------------------------------------
   -- cpu top table

   local mk_tbl = function(y)
      local num_rows = config.table_rows
      local table_conky = pure.map_n(
         function(i) return {pid = '${top pid '..i..'}', cpu = '${top cpu '..i..'}'} end,
         num_rows
      )
      local tbl = common.make_text_table(
         point.x,
         y,
         width,
         num_rows,
         'CPU (%)'
      )
      local update = function()
         for r = 1, num_rows do
            local pid = i_o.conky(table_conky[r].pid, '(%d+)') -- may have leading spaces
            if pid ~= '' then
               text_table.set(tbl, 1, r, i_o.read_file('/proc/'..pid..'/comm', '(%C+)'))
               text_table.set(tbl, 2, r, pid)
               text_table.set(tbl, 3, r, i_o.conky(table_conky[r].cpu))
            end
         end
      end
      return common.mk_acc(
         width,
         common.table_height(num_rows),
         update,
         pure.partial(text_table.draw_static, tbl),
         pure.partial(text_table.draw_dynamic, tbl)
      )
   end

   -----------------------------------------------------------------------------
   -- main functions

   return {
      header = 'PROCESSOR',
      point = point,
      width = width,
      set_state = update_state,
      top = {
         {mk_cores, show_cores, TEXT_SPACING},
         {mk_hwp_freq, config.show_stats, SEPARATOR_SPACING},
      },
      common.mk_section(
         SEPARATOR_SPACING,
         {mk_load_plot, config.show_plot, TABLE_SECTION_BREAK},
         {mk_tbl, config.table_rows > 0, 0}
      )
   }
end
