local CompoundDial 	= require 'CompoundDial'
local Line			= require 'Line'
local Table			= require 'Table'
local Util			= require 'Util'
local Common		= require 'Common'
local Geometry = require 'Geometry'

local __string_match = string.match
local __string_gmatch = string.gmatch
local __string_format = string.format
local __tonumber = tonumber
local __math_floor = math.floor

local CORETEMP_PATH = '/sys/devices/platform/coretemp.0/hwmon/hwmon%i/%s'

local NUM_PHYSICAL_CORES = 4
local NUM_THREADS_PER_CORE = 2
local NCPU = NUM_THREADS_PER_CORE * NUM_PHYSICAL_CORES

local NUM_ROWS = 5

local HWP_PATHS = {}

for i = 1, NCPU do
   HWP_PATHS[i] = '/sys/devices/system/cpu/cpu' .. (i - 1) ..
      '/cpufreq/energy_performance_preference'
end

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

local _create_core_ = function(cores, id, x, y)
   local hwmon_index = -1
   while Util.read_file(string.format(CORETEMP_PATH, hwmon_index, 'name'), nil, '*l') ~= 'coretemp' do
	  hwmon_index = hwmon_index + 1
   end

   cores[id +1] = {
	  dials = Common.compound_dial(
         x,
         y,
         _DIAL_OUTER_RADIUS_,
         _DIAL_INNER_RADIUS_,
         _DIAL_THICKNESS_,
         0.8,
         NUM_THREADS_PER_CORE
	  ),
      text_ring = Common.initTextRing(
         x,
         y,
         _DIAL_INNER_RADIUS_ - 2,
		 '%s°C',
		 90
      ),
	  coretemp_path = string.format(CORETEMP_PATH, hwmon_index, 'temp'..(id + 2)..'_input'),
   }
end

local header = Common.Header(
   Geometry.LEFT_X,
   _MODULE_Y_,
   Geometry.SECTION_WIDTH,
   'PROCESSOR'
)

--we assume that this cpu has 4 physical cores with 2 logical each
local cores = {}

for c = 0, NUM_PHYSICAL_CORES - 1 do
   local dial_x = Geometry.LEFT_X + _DIAL_OUTER_RADIUS_ +
	  (Geometry.SECTION_WIDTH - 2 * _DIAL_OUTER_RADIUS_) * c / 3
   local dial_y = header.bottom_y + _DIAL_OUTER_RADIUS_
   _create_core_(cores, c, dial_x, dial_y)
end

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

local cpu_loads = {}
for i = 1, NCPU do
   cpu_loads[i] = {active_prev = 0, active_total = 0}
end

local _read_cpu = function()
   local i = NCPU
   local iter = io.lines('/proc/stat')
   iter() -- ignore first line
   for ln in iter do
      if i == 0 then break end
      local user, system, idle = __string_match(ln, '(%d+) %d+ (%d+) (%d+)', 5)
      local c = cpu_loads[i]
      c.active_prev = c.active
      c.total_prev = c.total
      c.active = user + system
      c.total = user + system + idle
      i = i - 1
   end
end

_read_cpu() -- prime once

local _read_freq = function()
   -- NOTE: Using the builtin conky functions for getting cpu freq seems to
   -- make the entire loop jittery due to high variance latency. Querying
   -- scaling_cur_freq in sysfs seems to do the same thing. It appears
   -- /proc/cpuinfo is much faster and doesn't have this jittery problem.
   local c = Util.read_file('/proc/cpuinfo')
   local f = 0
   for s in __string_gmatch(c, 'cpu MHz%s+: (%d+%.%d+)') do
      f = f + __tonumber(s)
   end
   return __string_format('%.0f Mhz', f / NCPU)
end

local _read_hwp = function()
   -- read HWP of first cpu, then test all others to see if they match
   local hwp_pref = Util.read_file(HWP_PATHS[1], nil, "*l")
   local mixed = false
   local i = 2

   while not mixed and i <= #HWP_PATHS do
      if hwp_pref ~= Util.read_file(HWP_PATHS[i], nil, '*l') then
         mixed = true
      end
      i = i + 1
   end

   if mixed then
      return 'Mixed'
   elseif hwp_pref == 'power' then
      return 'Power'
   elseif hwp_pref == 'balance_power' then
      return 'Bal. Power'
   elseif hwp_pref == 'balance_performance' then
      return 'Bal. Performance'
   elseif hwp_pref == 'performance' then
      return 'Performance'
   elseif hwp_pref == 'default' then
      return 'Default'
   else
      return 'Unknown'
   end
end

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

      -- TODO bundle all the crap down below into this function and make it return
      -- something useful rather than totally use a side effect (it will be mildly
      -- slower)
      -- this entire loop is about 10% total execution time
      _read_cpu()
      for c = 1, NUM_PHYSICAL_CORES do
         local core = cores[c]

         for t = 1, NUM_THREADS_PER_CORE do
            -- TODO these might not match the actual core numbers (if I care)
            local cl = cpu_loads[(c - 1) * NUM_THREADS_PER_CORE + t]
            -- this is necessary to prevent 1/0 errors
            if cl.total > cl.total_prev then
               local p = (cl.active - cl.active_prev) / (cl.total - cl.total_prev)
               CompoundDial.set(core.dials, t, p)
               load_sum = load_sum + p
            end
         end
         Common.text_ring_set(
            core.text_ring,
            cr,
            __math_floor(0.001 * Util.read_file(core.coretemp_path, nil, '*n'))
         )
      end

      -- For some reason this call is slow (querying anything with pstate in
      -- general seems slow), but I also don't need to see an update every cycle,
      -- hence the trigger
      if trigger == 0 then
         Common.text_rows_set(cpu_status, cr, 1, _read_hwp())
      end
      Common.text_rows_set(cpu_status, cr, 2, _read_freq())

      Common.percent_plot_set(total_load, cr, load_sum / NCPU * 100)

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

      for c = 1, NUM_PHYSICAL_CORES do
         local this_core = cores[c]
         Common.text_ring_draw_static(this_core.text_ring, cr)
         CompoundDial.draw_static(this_core.dials, cr)
      end

      Common.text_rows_draw_static(cpu_status, cr)
      Line.draw(separator, cr)

      Common.percent_plot_draw_static(total_load, cr)

      Table.draw_static(tbl, cr)
   end

   local draw_dynamic = function(cr, trigger)
      update(cr, trigger)

      for c = 1, NUM_PHYSICAL_CORES do
         local this_core = cores[c]
         CompoundDial.draw_dynamic(this_core.dials, cr)
         Common.text_ring_draw_dynamic(this_core.text_ring, cr)
      end

      Common.text_rows_draw_dynamic(cpu_status, cr)
      Common.percent_plot_draw_dynamic(total_load, cr)

      Table.draw_dynamic(tbl, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic}
end
