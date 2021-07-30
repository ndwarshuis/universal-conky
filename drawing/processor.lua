local CompoundDial 	= require 'CompoundDial'
local Line = require 'Line'
local Table	= require 'Table'
local Util = require 'Util'
local common = require 'common'
local geometry = require 'geometry'
local CPU = require 'CPU'
local func = require 'func'

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

   local header = common.Header(
      geometry.LEFT_X,
      MODULE_Y,
      geometry.SECTION_WIDTH,
      'PROCESSOR'
   )

   -----------------------------------------------------------------------------
   -- cores (loads and temps)

   local cpu_loads = CPU.init_cpu_loads()
   local ncpus = CPU.get_cpu_number()
   local ncores = CPU.get_core_number()
   local nthreads = ncpus / ncores
   local hwp_paths = CPU.get_hwp_paths()
   local coretemp_paths = CPU.get_coretemp_paths()
   CPU.read_cpu_loads(cpu_loads) -- prime load matrix by side effect

   local cores = {}

   local create_core = function(x, y)
      return {
         loads = common.compound_dial(
            x,
            y,
            DIAL_OUTER_RADIUS,
            DIAL_INNER_RADIUS,
            DIAL_THICKNESS,
            0.8,
            nthreads
         ),
         coretemp = common.initTextRing(
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

   local cpu_status = common.initTextRows(
      geometry.LEFT_X,
      HWP_Y,
      geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'HWP Preference', 'Ave Freq'}
   )

   -----------------------------------------------------------------------------
   -- frequency

   local SEP_Y = HWP_Y + TEXT_SPACING + SEPARATOR_SPACING

   local separator = common.initSeparator(
      geometry.LEFT_X,
      SEP_Y,
      geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- total load plot

   local LOAD_Y = SEP_Y + SEPARATOR_SPACING

   local total_load = common.initPercentPlot(
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
   local TABLE_CONKY = func.map(
      function(i) return {pid = '${top pid '..i..'}', cpu = '${top cpu '..i..'}'} end,
      func.seq(NUM_ROWS)
   )

   local tbl = common.initTable(
      geometry.LEFT_X,
      PLOT_Y + PLOT_HEIGHT + TABLE_SECTION_BREAK,
      geometry.SECTION_WIDTH,
      TABLE_HEIGHT,
      NUM_ROWS,
      {'Name', 'PID', 'CPU (%)'}
   )

   -----------------------------------------------------------------------------
   -- main functions

   local update = function(trigger)
      local conky = Util.conky
      local load_sum = 0

      cpu_loads = CPU.read_cpu_loads(cpu_loads)
      for _, load_data in pairs(cpu_loads) do
         local cur = load_data.percent_active
         load_sum = load_sum + cur
         CompoundDial.set(cores[load_data.conky_core_id].loads, load_data.conky_thread_id, cur)
      end

      for conky_core_id, path in pairs(coretemp_paths) do
         local temp = __math_floor(0.001 * Util.read_file(path, nil, '*n'))
         common.text_ring_set(cores[conky_core_id].coretemp, temp)
      end

      -- For some reason this call is slow (querying anything with pstate in
      -- general seems slow), but I also don't need to see an update every cycle,
      -- hence the trigger
      if trigger == 0 then
         common.text_rows_set(cpu_status, 1, CPU.read_hwp(hwp_paths))
      end
      common.text_rows_set(cpu_status, 2, CPU.read_freq())

      common.percent_plot_set(total_load, load_sum / ncpus * 100)

      for r = 1, NUM_ROWS do
         local pid = conky(TABLE_CONKY[r].pid, '(%d+)') -- may have leading spaces
         if pid ~= '' then
            Table.set(tbl, 1, r, Util.read_file('/proc/'..pid..'/comm', '(%C+)'))
            Table.set(tbl, 2, r, pid)
            Table.set(tbl, 3, r, conky(TABLE_CONKY[r].cpu))
         end
      end
   end

   local draw_static = function(cr)
      common.drawHeader(cr, header)

      for i = 1, #cores do
         common.text_ring_draw_static(cores[i].coretemp, cr)
         CompoundDial.draw_static(cores[i].loads, cr)
      end

      common.text_rows_draw_static(cpu_status, cr)
      Line.draw(separator, cr)

      common.percent_plot_draw_static(total_load, cr)

      Table.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr)
      for i = 1, #cores do
         CompoundDial.draw_dynamic(cores[i].loads, cr)
         common.text_ring_draw_dynamic(cores[i].coretemp, cr)
      end

      common.text_rows_draw_dynamic(cpu_status, cr)
      common.percent_plot_draw_dynamic(total_load, cr)

      Table.draw_dynamic(tbl, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
