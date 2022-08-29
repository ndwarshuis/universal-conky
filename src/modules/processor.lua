local compound_dial = require 'compound_dial'
local text_table = require 'text_table'
local i_o = require 'i_o'
local cpu = require 'sys'
local pure = require 'pure'

local __math_floor = math.floor

return function(update_freq, main_state, config, common, width, point)
   local dial_inner_radius = 30
   local dial_outer_radius = 42
   local dial_thickness = 5.5
   local dial_y_spacing = 20

   local geo = config.geometry
   local sep_spacing = geo.sep_spacing
   local text_spacing = geo.text_spacing
   local plot_sec_break = geo.plot.sec_break
   local plot_height = geo.plot.height

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

   local create_core = function(core_cols, y, c)
      local dial_x = point.x +
         (core_cols == 1
          and (width / 2)
          or (config.core_padding + dial_outer_radius +
              (width - 2 * (dial_outer_radius + config.core_padding))
              * math.fmod(c - 1, core_cols) / (core_cols - 1)))
      local dial_y = y + dial_outer_radius +
         (2 * dial_outer_radius + dial_y_spacing)
         * math.floor((c - 1) / core_cols)
      return {
         loads = common.make_compound_dial(
            dial_x,
            dial_y,
            dial_outer_radius,
            dial_inner_radius,
            dial_thickness,
            80,
            nthreads
         ),
         coretemp = common.make_text_circle(
            dial_x,
            dial_y,
            dial_inner_radius - 2,
            '%s°C',
            80,
            __math_floor
         )
      }
   end

   local mk_cores = function(y)
      local core_cols = ncores / config.core_rows
      local cores = pure.map_n(pure.partial(create_core, core_cols, y), ncores)
      local coretemp_paths = cpu.get_coretemp_paths()
      if #coretemp_paths ~= ncores then
         i_o.warnf('could not find all coretemp paths')
      end
      local update_coretemps = function()
         for conky_core_idx, path in pairs(coretemp_paths) do
            local temp = __math_floor(0.001 * i_o.read_file(path, nil, '*n'))
            common.text_circle_set(cores[conky_core_idx].coretemp, temp)
         end
      end
      local update = function()
         for _, load_data in pairs(mod_state) do
            compound_dial.set(
               cores[load_data.conky_core_idx].loads,
               load_data.conky_thread_id,
               load_data.percent_active * 100
            )
         end
         update_coretemps()
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
         (dial_outer_radius * 2 + dial_y_spacing) * config.core_rows
         - dial_y_spacing,
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
         text_spacing,
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
         text_spacing,
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
         plot_height,
         geo.plot.ticks_y,
         plot_sec_break,
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
         plot_height + plot_sec_break,
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
            local name = i_o.read_file('/proc/'..pid..'/comm', '(%C+)') or 'N/A'
            if pid ~= '' then
               text_table.set(tbl, 1, r, name)
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
         {mk_cores, show_cores, text_spacing},
         {mk_hwp_freq, config.show_stats, sep_spacing},
      },
      common.mk_section(
         sep_spacing,
         {mk_load_plot, config.show_plot, geo.table.sec_break},
         {mk_tbl, config.table_rows > 0, 0}
      )
   }
end
