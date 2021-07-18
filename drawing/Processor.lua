local CompoundDial 	= require 'CompoundDial'
local Line			= require 'Line'
local Table			= require 'Table'
local Util			= require 'Util'
local Common		= require 'Common'
local Geometry = require 'Geometry'
local CPU = require 'CPU'

local __math_floor = math.floor

local NUM_ROWS = 5

local TABLE_CONKY = {}

for r = 1, NUM_ROWS do
   TABLE_CONKY[r] = {
      pid = '${top pid '..r..'}',
      cpu = '${top cpu '..r..'}'
   }
end

local _MODULE_Y_ = 614
local _DIAL_INNER_RADIUS_ = 30
local _DIAL_OUTER_RADIUS_ = 42
local _DIAL_THICKNESS_ = 5.5
local _SEPARATOR_SPACING_ = 20
local _TEXT_SPACING_ = 22
local _PLOT_SECTION_BREAK_ = 23
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 20
local _TABLE_HEIGHT_ = 114

local _create_core_ = function(x, y, nthreads)
   return {
	  loads = Common.compound_dial(
         x,
         y,
         _DIAL_OUTER_RADIUS_,
         _DIAL_INNER_RADIUS_,
         _DIAL_THICKNESS_,
         0.8,
         nthreads
	  ),
      coretemp = Common.initTextRing(
         x,
         y,
         _DIAL_INNER_RADIUS_ - 2,
		 '%s°C',
		 90
      )
   }
end

local header = Common.Header(
   Geometry.LEFT_X,
   _MODULE_Y_,
   Geometry.SECTION_WIDTH,
   'PROCESSOR'
)


local _HWP_Y_ = header.bottom_y + _DIAL_OUTER_RADIUS_ * 2 + _PLOT_SECTION_BREAK_

local _FREQ_Y_ = _HWP_Y_ + _TEXT_SPACING_

local cpu_status = Common.initTextRows(
   Geometry.LEFT_X,
   _HWP_Y_,
   Geometry.SECTION_WIDTH,
   _TEXT_SPACING_,
   {'HWP Preference', 'Ave Freq'}
)

local _SEP_Y_ = _FREQ_Y_ + _SEPARATOR_SPACING_

local separator = Common.initSeparator(
   Geometry.LEFT_X,
   _SEP_Y_,
   Geometry.SECTION_WIDTH
)

local _LOAD_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local _PLOT_Y_ = _LOAD_Y_ + _PLOT_SECTION_BREAK_


local tbl = Common.initTable(
   Geometry.LEFT_X,
   _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
   Geometry.SECTION_WIDTH,
   _TABLE_HEIGHT_,
   NUM_ROWS,
   {'Name', 'PID', 'CPU (%)'}
)

-- local cpu_loads = {}
-- for i = 1, NCPU do
--    cpu_loads[i] = {active_prev = 0, active_total = 0}
-- end


-- _MODULE_Y_ = nil
-- _DIAL_INNER_RADIUS_ = nil
-- _DIAL_OUTER_RADIUS_ = nil
-- _DIAL_THICKNESS_ = nil
-- _TEXT_Y_OFFSET_ = nil
-- _SEPARATOR_SPACING_ = nil
-- _TEXT_SPACING_ = nil
-- _PLOT_SECTION_BREAK_ = nil
-- _PLOT_HEIGHT_ = nil
-- _TABLE_SECTION_BREAK_ = nil
-- _TABLE_HEIGHT_ = nil
-- _create_core_ = nil
-- _FREQ_Y_ = nil
-- _LOAD_Y_ = nil
-- _SEP_Y_ = nil
-- _HWP_Y_ = nil
-- _PLOT_Y_ = nil

return function(update_freq)
   local cpu_loads = CPU.init_cpu_loads()
   local ncpus = CPU.get_cpu_number()
   local ncores = CPU.get_core_number()
   local nthreads = ncpus / ncores
   local hwp_paths = CPU.get_hwp_paths()
   local coretemp_paths = CPU.get_coretemp_paths()

   -- prime the load matrix
   CPU.read_cpu_loads(cpu_loads)

   local cores = {}

   for c = 1, ncores do
      local dial_x = Geometry.LEFT_X + _DIAL_OUTER_RADIUS_ +
         (Geometry.SECTION_WIDTH - 2 * _DIAL_OUTER_RADIUS_) * (c - 1) / 3
      local dial_y = header.bottom_y + _DIAL_OUTER_RADIUS_
      cores[c] = _create_core_(dial_x, dial_y, nthreads)
   end

   local total_load = Common.initPercentPlot(
      Geometry.LEFT_X,
      _LOAD_Y_,
      Geometry.SECTION_WIDTH,
      _PLOT_HEIGHT_,
      _PLOT_SECTION_BREAK_,
      "Total Load",
      update_freq
   )

   local update = function(cr, trigger)
      local conky = Util.conky
      local load_sum = 0

      cpu_loads = CPU.read_cpu_loads(cpu_loads)
      for _, load_data in pairs(cpu_loads) do
         local cur = load_data.percent_active
         load_sum = load_sum + cur
         CompoundDial.set(cores[load_data.core_id].loads, load_data.thread_id, cur)
      end

      for core_id, path in pairs(coretemp_paths) do
         local temp = __math_floor(0.001 * Util.read_file(path, nil, '*n'))
         Common.text_ring_set(cores[core_id].coretemp, cr, temp)
      end

      -- For some reason this call is slow (querying anything with pstate in
      -- general seems slow), but I also don't need to see an update every cycle,
      -- hence the trigger
      if trigger == 0 then
         Common.text_rows_set(cpu_status, cr, 1, CPU.read_hwp(hwp_paths))
      end
      Common.text_rows_set(cpu_status, cr, 2, CPU.read_freq())

      Common.percent_plot_set(total_load, cr, load_sum / ncpus * 100)

      for r = 1, NUM_ROWS do
         local pid = conky(TABLE_CONKY[r].pid, '(%d+)') -- may have leading spaces
         if pid ~= '' then
            local cpu = conky(TABLE_CONKY[r].cpu)
            local comm = Util.read_file('/proc/'..pid..'/comm', '(%C+)')
            Table.set(tbl, cr, 1, r, comm)
            Table.set(tbl, cr, 2, r, pid)
            Table.set(tbl, cr, 3, r, cpu)
         end
      end
   end

   local draw_static = function(cr)
      Common.drawHeader(cr, header)

      for _, this_core in pairs(cores) do
         Common.text_ring_draw_static(this_core.coretemp, cr)
         CompoundDial.draw_static(this_core.loads, cr)
      end

      Common.text_rows_draw_static(cpu_status, cr)
      Line.draw(separator, cr)

      Common.percent_plot_draw_static(total_load, cr)

      Table.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr, trigger)
      update(cr, trigger)

      for _, this_core in pairs(cores) do
         CompoundDial.draw_dynamic(this_core.loads, cr)
         Common.text_ring_draw_dynamic(this_core.coretemp, cr)
      end

      Common.text_rows_draw_dynamic(cpu_status, cr)
      Common.percent_plot_draw_dynamic(total_load, cr)

      Table.draw_dynamic(tbl, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
