local compound_dial = require 'compound_dial'
local line = require 'line'
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

   local header = common.make_header(
      geometry.LEFT_X,
      MODULE_Y,
      geometry.SECTION_WIDTH,
      'PROCESSOR'
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
            compound_dial.draw_dynamic(cores[i].loads, cr)
            common.text_circle_draw_dynamic(cores[i].coretemp, cr)
         end
      end
      return {h = DIAL_OUTER_RADIUS * 2, obj = {update, static, dynamic}}
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
      return {h = TEXT_SPACING, obj = {update, static, dynamic}}
   end

   -----------------------------------------------------------------------------
   -- frequency

   local mk_sep = function(y)
      local separator = common.make_separator(
         geometry.LEFT_X,
         y,
         geometry.SECTION_WIDTH
      )
      local static = pure.partial(line.draw, separator)
      return {h = 0, obj = {nil, static, nil}}
   end

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
      return {h = PLOT_HEIGHT + PLOT_SECTION_BREAK, obj = {update, static, dynamic}}
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
      return {h = TABLE_HEIGHT, obj = {update, static, dynamic}}
   end

   -----------------------------------------------------------------------------
   -- main functions

   local combine = function(acc, new)
      if new.active == true then
         local n = new.f(acc.y + new.offset)
         table.insert(acc.objs, n.obj)
         acc.y = acc.y + n.h + new.offset
      end
      return acc
   end

   local all = pure.reduce(
      combine,
      {y = header.bottom_y, objs = {}},
      {
         {f = mk_cores, active = true, offset = 0},
         {f = mk_hwp_freq, active = true, offset = TEXT_SPACING},
         {f = mk_sep, active = true, offset = SEPARATOR_SPACING},
         {f = mk_load_plot, active = true, offset = SEPARATOR_SPACING},
         {f = mk_tbl, active = true, offset = TABLE_SECTION_BREAK}
      }
   )

   local update_state_ = pure.compose(
      table.unpack(
         pure.non_nil(
            pure.reverse(pure.map(function(x) return x[1] end, all.objs))
         )
      )
   )

   local update = function(trigger)
      update_state_(update_state(trigger, state.cpu_loads))
   end

   local draw_static = pure.sequence(
      function(cr) common.draw_header(cr, header) end,
      table.unpack(pure.map(function(x) return x[2] end, all.objs))
   )

   local draw_dynamic = pure.sequence(
      table.unpack(
         pure.non_nil(
            pure.map(function(x) return x[3] end, all.objs)))
   )

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
