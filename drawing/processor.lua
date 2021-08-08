local compounddial 	= require 'compounddial'
local line = require 'line'
local texttable = require 'texttable'
local util = require 'util'
local common = require 'common'
local geometry = require 'geometry'
local cpu = require 'sys'
local pure = require 'pure'

local __math_floor = math.floor

return function(update_freq)
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

   local cpu_loads = cpu.init_cpu_loads()
   local ncpus = cpu.get_cpu_number()
   local ncores = cpu.get_core_number()
   local nthreads = ncpus / ncores
   local hwp_paths = cpu.get_hwp_paths()
   local coretemp_paths = cpu.get_coretemp_paths()
   cpu.read_cpu_loads(cpu_loads) -- prime load matrix by side effect

   local cores = {}

   local create_core = function(x, y)
      return {
         loads = common.make_compound_dial(
            x,
            y,
            DIAL_OUTER_RADIUS,
            DIAL_INNER_RADIUS,
            DIAL_THICKNESS,
            0.8,
            nthreads
         ),
         coretemp = common.make_text_circle(
            x,
            y,
            DIAL_INNER_RADIUS - 2,
            '%s°C',
            90
         )
      }
   end

   for c = 1, ncores do
      local dial_x = geometry.LEFT_X + DIAL_OUTER_RADIUS +
         (geometry.SECTION_WIDTH - 2 * DIAL_OUTER_RADIUS) * (c - 1) / 3
      local dial_y = header.bottom_y + DIAL_OUTER_RADIUS
      cores[c] = create_core(dial_x, dial_y)
   end

   -----------------------------------------------------------------------------
   -- HWP status

   local HWP_Y = header.bottom_y + DIAL_OUTER_RADIUS * 2 + PLOT_SECTION_BREAK

   local cpu_status = common.make_text_rows(
      geometry.LEFT_X,
      HWP_Y,
      geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'HWP Preference', 'Ave Freq'}
   )

   -----------------------------------------------------------------------------
   -- frequency

   local SEP_Y = HWP_Y + TEXT_SPACING + SEPARATOR_SPACING

   local separator = common.make_separator(
      geometry.LEFT_X,
      SEP_Y,
      geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- total load plot

   local LOAD_Y = SEP_Y + SEPARATOR_SPACING

   local total_load = common.make_tagged_percent_timeseries(
      geometry.LEFT_X,
      LOAD_Y,
      geometry.SECTION_WIDTH,
      PLOT_HEIGHT,
      PLOT_SECTION_BREAK,
      "Total Load",
      update_freq
   )

   local PLOT_Y = LOAD_Y + PLOT_SECTION_BREAK

   -----------------------------------------------------------------------------
   -- cpu top table

   local NUM_ROWS = 5
   local TABLE_CONKY = pure.map(
      function(i) return {pid = '${top pid '..i..'}', cpu = '${top cpu '..i..'}'} end,
      pure.seq(NUM_ROWS)
   )

   local tbl = common.make_text_table(
      geometry.LEFT_X,
      PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK,
      geometry.SECTION_WIDTH,
      TABLE_HEIGHT,
      NUM_ROWS,
      {'Name', 'PID', 'cpu (%)'}
   )

   -----------------------------------------------------------------------------
   -- main functions

   local update = function(trigger)
      local conky = util.conky
      local load_sum = 0

      cpu_loads = cpu.read_cpu_loads(cpu_loads)
      for _, load_data in pairs(cpu_loads) do
         local cur = load_data.percent_active
         load_sum = load_sum + cur
         compounddial.set(cores[load_data.conky_core_id].loads, load_data.conky_thread_id, cur)
      end

      for conky_core_id, path in pairs(coretemp_paths) do
         local temp = __math_floor(0.001 * util.read_file(path, nil, '*n'))
         common.text_circle_set(cores[conky_core_id].coretemp, temp)
      end

      -- For some reason this call is slow (querying anything with pstate in
      -- general seems slow), but I also don't need to see an update every cycle,
      -- hence the trigger
      if trigger == 0 then
         common.text_rows_set(cpu_status, 1, cpu.read_hwp(hwp_paths))
      end
      common.text_rows_set(cpu_status, 2, cpu.read_freq())

      common.tagged_percent_timeseries_set(total_load, load_sum / ncpus * 100)

      for r = 1, NUM_ROWS do
         local pid = conky(TABLE_CONKY[r].pid, '(%d+)') -- may have leading spaces
         if pid ~= '' then
            texttable.set(tbl, 1, r, util.read_file('/proc/'..pid..'/comm', '(%C+)'))
            texttable.set(tbl, 2, r, pid)
            texttable.set(tbl, 3, r, conky(TABLE_CONKY[r].cpu))
         end
      end
   end

   local draw_static = function(cr)
      common.draw_header(cr, header)

      for i = 1, #cores do
         common.text_circle_draw_static(cores[i].coretemp, cr)
         compounddial.draw_static(cores[i].loads, cr)
      end

      common.text_rows_draw_static(cpu_status, cr)
      line.draw(separator, cr)

      common.tagged_percent_timeseries_draw_static(total_load, cr)

      texttable.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr)
      for i = 1, #cores do
         compounddial.draw_dynamic(cores[i].loads, cr)
         common.text_circle_draw_dynamic(cores[i].coretemp, cr)
      end

      common.text_rows_draw_dynamic(cpu_status, cr)
      common.tagged_percent_timeseries_draw_dynamic(total_load, cr)

      texttable.draw_dynamic(tbl, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
