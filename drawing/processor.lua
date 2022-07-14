local compound_dial = require 'compound_dial'
local text_table = require 'text_table'
local i_o = require 'i_o'
local common = require 'common'
local geometry = require 'geometry'
local cpu = require 'sys'
local pure = require 'pure'

local __math_floor = math.floor

return function(update_freq)
   -- local SHOW_DIALS = true
   -- local SHOW_TIMESERIES = true
   -- local SHOW_TABLE = true

   local MODULE_Y = 614
   local DIAL_INNER_RADIUS = 30
   local DIAL_OUTER_RADIUS = 42
   local DIAL_THICKNESS = 5.5
   local SEPARATOR_SPACING = 20
   local TEXT_SPACING = 22
   local PLOT_SECTION_BREAK = 23
   local PLOT_HEIGHT = 56
   local TABLE_SECTION_BREAK = 20
   local TABLE_HEIGHT = 114

   -----------------------------------------------------------------------------
   -- header

   local mk_header = pure.partial(
      common.mk_header,
      'PROCESSOR',
      geometry.SECTION_WIDTH,
      geometry.LEFT_X
   )

   -----------------------------------------------------------------------------
   -- cores (loads and temps)

   -- this totally is not supposed to be a state monad (ssssh...)
   local update_state = function(trigger, cpu_loads)
      return {
         cpu_loads = cpu.read_cpu_loads(cpu_loads),
         load_sum = 0,
         trigger = trigger
      }
   end

   local state = update_state(0, cpu.init_cpu_loads())
   local ncpus = cpu.get_cpu_number()
   local ncores = cpu.get_core_number()
   local nthreads = ncpus / ncores

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
      local cores = {}
      -- TODO what happens when the number of cores changes?
      for c = 1, ncores do
         local dial_x = geometry.LEFT_X + DIAL_OUTER_RADIUS +
            (geometry.SECTION_WIDTH - 2 * DIAL_OUTER_RADIUS) * (c - 1) / 3
         local dial_y = y + DIAL_OUTER_RADIUS
         cores[c] = create_core(dial_x, dial_y)
      end
      local update = function(state_)
         local s = state_.load_sum
         for _, load_data in pairs(state_.cpu_loads) do
            local cur = load_data.percent_active
            s = s + cur
            compound_dial.set(
               cores[load_data.conky_core_id].loads,
               load_data.conky_thread_id,
               cur * 100
            )
         end
         for conky_core_id, path in pairs(coretemp_paths) do
            local temp = __math_floor(0.001 * i_o.read_file(path, nil, '*n'))
            common.text_circle_set(cores[conky_core_id].coretemp, temp)
         end
         state_.load_sum = s
         return state_
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
      return common.mk_acc(DIAL_OUTER_RADIUS * 2, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- HWP status

   local mk_hwp_freq = function(y)
      local hwp_paths = cpu.get_hwp_paths()
      local cpu_status = common.make_text_rows(
         geometry.LEFT_X,
         y,
         geometry.SECTION_WIDTH,
         TEXT_SPACING,
         {'HWP Preference', 'Ave Freq'}
      )
      local update = function(state_)
         -- For some reason this call is slow (querying anything with pstate in
         -- general seems slow), but I also don't need to see an update every
         -- cycle, hence the trigger
         if state_.trigger == 0 then
            common.text_rows_set(cpu_status, 1, cpu.read_hwp(hwp_paths))
         end
         common.text_rows_set(cpu_status, 2, cpu.read_freq())
         return state_
      end
      local static = pure.partial(common.text_rows_draw_static, cpu_status)
      local dynamic = pure.partial(common.text_rows_draw_dynamic, cpu_status)
      return common.mk_acc(TEXT_SPACING, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- frequency

   local mk_sep = pure.partial(
      common.mk_seperator,
      geometry.SECTION_WIDTH,
      geometry.LEFT_X
   )

   -----------------------------------------------------------------------------
   -- total load plot

   local mk_load_plot = function(y)
      local total_load = common.make_tagged_percent_timeseries(
         geometry.LEFT_X,
         y,
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         PLOT_SECTION_BREAK,
         "Total Load",
         update_freq
      )
      local update = function(state_)
         common.tagged_percent_timeseries_set(
            total_load,
            state_.load_sum / ncpus * 100
         )
         return state_
      end
      local static = pure.partial(common.tagged_percent_timeseries_draw_static, total_load)
      local dynamic = pure.partial(common.tagged_percent_timeseries_draw_dynamic, total_load)
      return common.mk_acc(PLOT_HEIGHT + PLOT_SECTION_BREAK, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- cpu top table

   local mk_tbl = function(y)
      local NUM_ROWS = 5
      local TABLE_CONKY = pure.map_n(
         function(i) return {pid = '${top pid '..i..'}', cpu = '${top cpu '..i..'}'} end,
         NUM_ROWS
      )
      local tbl = common.make_text_table(
         geometry.LEFT_X,
         y,
         geometry.SECTION_WIDTH,
         TABLE_HEIGHT,
         NUM_ROWS,
         'CPU (%)'
      )
      local update = function(state_)
         for r = 1, NUM_ROWS do
            local pid = i_o.conky(TABLE_CONKY[r].pid, '(%d+)') -- may have leading spaces
            if pid ~= '' then
               text_table.set(tbl, 1, r, i_o.read_file('/proc/'..pid..'/comm', '(%C+)'))
               text_table.set(tbl, 2, r, pid)
               text_table.set(tbl, 3, r, i_o.conky(TABLE_CONKY[r].cpu))
            end
         end
         return state_
      end
      local static = pure.partial(text_table.draw_static, tbl)
      local dynamic = pure.partial(text_table.draw_dynamic, tbl)
      return common.mk_acc(TABLE_HEIGHT, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- main functions

   local rbs = common.reduce_blocks(
      MODULE_Y,
      {
         common.mk_block(mk_header, true, 0),
         common.mk_block(mk_cores, true, 0),
         common.mk_block(mk_hwp_freq, true, TEXT_SPACING),
         common.mk_block(mk_sep, true, SEPARATOR_SPACING),
         common.mk_block(mk_load_plot, true, SEPARATOR_SPACING),
         common.mk_block(mk_tbl, true, TABLE_SECTION_BREAK)
      }
   )

   local update = function(trigger)
      rbs.updater(update_state(trigger, state.cpu_loads))
   end

   -- TODO return the bottom y/height of the entire module
   return {
      static = rbs.static_drawer,
      dynamic = rbs.dynamic_drawer,
      update = update
   }
end
