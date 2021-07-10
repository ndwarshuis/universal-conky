local M = {}

local CompoundDial 	= require 'CompoundDial'
local Line			= require 'Line'
local Table			= require 'Table'
local Util			= require 'Util'
local Common		= require 'Common'

local CORETEMP_PATH = '/sys/devices/platform/coretemp.0/hwmon/hwmon%i/%s'

local NUM_PHYSICAL_CORES = 4
local NUM_THREADS_PER_CORE = 2

local NUM_ROWS = 5

local HWP_PATHS = {}

for i = 1, NUM_ROWS do
   HWP_PATHS[i] = '/sys/devices/system/cpu/cpu' .. i ..
      '/cpufreq/energy_performance_preference'
end

local TABLE_CONKY = {}

for r = 1, NUM_ROWS do
   TABLE_CONKY[r] = {}
   TABLE_CONKY[r].pid = '${top pid '..r..'}'
   TABLE_CONKY[r].cpu = '${top cpu '..r..'}'
end

local _MODULE_Y_ = 614
local _DIAL_INNER_RADIUS_ = 30
local _DIAL_OUTER_RADIUS_ = 42
local _DIAL_SPACING_ = 1
local _SEPARATOR_SPACING_ = 20
local _TEXT_SPACING_ = 22
local _PLOT_SECTION_BREAK_ = 23
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 20
local _TABLE_HEIGHT_ = 114

local _create_core_ = function(cores, id, x, y)
   local conky_loads = {}
   local conky_freqs = {}

   for c = 0, NUM_PHYSICAL_CORES * NUM_THREADS_PER_CORE - 1 do
	  if Util.read_file('/sys/devices/system/cpu/cpu'..c..'/topology/core_id', nil, '*n') == id then
		 table.insert(conky_loads, '${cpu cpu'..(c+1)..'}')
		 table.insert(conky_freqs, '${freq '..c..'}')
	  end
   end

   local hwmon_index = -1
   while Util.read_file(string.format(CORETEMP_PATH, hwmon_index, 'name'), nil, '*l') ~= 'coretemp' do
	  hwmon_index = hwmon_index + 1
   end

   cores[id +1] = {
	  -- dials = _G_Widget_.CompoundDial{
	  --    x 				= x,
	  --    y 				= y,
	  --    inner_radius 	= _DIAL_INNER_RADIUS_,
	  --    outer_radius 	= _DIAL_OUTER_RADIUS_,
	  --    spacing 		= _DIAL_SPACING_,
	  --    num_dials 		= NUM_THREADS_PER_CORE,
	  --    critical_limit	= 0.8,
	  --    critical_pattern = _G_Patterns_.INDICATOR_FG_CRITICAL,
      --    dial_pattern    = _G_Patterns_.INDICATOR_FG_PRIMARY,
      --    arc_pattern   = _G_Patterns_.INDICATOR_BG
	  -- },
	  dials = _G_Widget_.CompoundDial(
         _G_Widget_.make_semicircle(
            _G_Widget_.make_point(x, y),
            _DIAL_OUTER_RADIUS_,
            90,
            360
         ),
         _G_Patterns_.INDICATOR_BG,
         _G_Patterns_.INDICATOR_FG_PRIMARY,
		 _G_Patterns_.INDICATOR_FG_CRITICAL,
		 0.8,
		 _DIAL_INNER_RADIUS_,
		 _DIAL_SPACING_,
		 NUM_THREADS_PER_CORE
	  ),
      text_ring = Common.initTextRing(
         x,
         y,
         _DIAL_INNER_RADIUS_ - 2,
		 '°C',
		 90
      ),
	  coretemp_path = string.format(CORETEMP_PATH, hwmon_index, 'temp'..(id + 2)..'_input'),
	  conky_loads = conky_loads,
	  conky_freqs = conky_freqs
   }
end

local header = Common.Header(
   _G_INIT_DATA_.LEFT_X,
   _MODULE_Y_,
   _G_INIT_DATA_.SECTION_WIDTH,
   'PROCESSOR'
)

--we assume that this cpu has 4 physical cores with 2 logical each
local cores = {}

for c = 0, NUM_PHYSICAL_CORES - 1 do
   local dial_x = _G_INIT_DATA_.LEFT_X + _DIAL_OUTER_RADIUS_ +
	  (_G_INIT_DATA_.SECTION_WIDTH - 2 * _DIAL_OUTER_RADIUS_) * c / 3
   local dial_y = header.bottom_y + _DIAL_OUTER_RADIUS_
   _create_core_(cores, c, dial_x, dial_y)
end

local _HWP_Y_ = header.bottom_y + _DIAL_OUTER_RADIUS_ * 2 + _PLOT_SECTION_BREAK_

local _FREQ_Y_ = _HWP_Y_ + _TEXT_SPACING_

local cpu_status = Common.initTextRows(
   _G_INIT_DATA_.LEFT_X,
   _HWP_Y_,
   _G_INIT_DATA_.SECTION_WIDTH,
   _TEXT_SPACING_,
   {'HWP Preference', 'Ave Freq'}
)

local _SEP_Y_ = _FREQ_Y_ + _SEPARATOR_SPACING_

local separator = Common.initSeparator(
   _G_INIT_DATA_.LEFT_X,
   _SEP_Y_,
   _G_INIT_DATA_.SECTION_WIDTH
)

local _LOAD_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local _PLOT_Y_ = _LOAD_Y_ + _PLOT_SECTION_BREAK_

local total_load = Common.initPercentPlot(
   _G_INIT_DATA_.LEFT_X,
   _LOAD_Y_,
   _G_INIT_DATA_.SECTION_WIDTH,
   _PLOT_HEIGHT_,
   _PLOT_SECTION_BREAK_,
   "Total Load"
)

local tbl = Common.initTable(
   _G_INIT_DATA_.LEFT_X,
   _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
   _G_INIT_DATA_.SECTION_WIDTH,
   _TABLE_HEIGHT_,
   NUM_ROWS,
   {'Name', 'PID', 'CPU (%)'}
)

local update = function(cr)
   local conky = Util.conky

   local load_sum = 0
   local freq_sum = 0

   for c = 1, NUM_PHYSICAL_CORES do
	  local core = cores[c]

	  local conky_loads = core.conky_loads
	  local conky_freqs = core.conky_freqs

	  for t = 1, NUM_THREADS_PER_CORE do
		 local percent = Util.conky_numeric(conky_loads[t]) * 0.01
		 CompoundDial.set(core.dials, t, percent)
		 load_sum = load_sum + percent

		 freq_sum = freq_sum + Util.conky_numeric(conky_freqs[t])
	  end

      Common.text_ring_set(core.text_ring, cr,
                           Util.round_to_string(
                              0.001 * Util.read_file(core.coretemp_path, nil, '*n')))
   end

   -- read HWP of first cpu, then test all others to see if they match
   local hwp_pref = Util.read_file(HWP_PATHS[1], nil, "*l")
   local mixed = nil
   local i = 2

   while not mixed and i <= #HWP_PATHS do
      if hwp_pref ~= Util.read_file(HWP_PATHS[i], nil, '*l') then
         mixed = 0
      end
      i = i + 1
   end

   local hwp_val = "Unknown"
   if mixed then
      hwp_val = "Mixed"
   elseif hwp_pref == "power" then
      hwp_val = "Power"
   elseif hwp_pref == "balance_power" then
      hwp_val = "Bal. Power"
   elseif hwp_pref == "balance_performance" then
      hwp_val = "Bal. Performance"
   elseif hwp_pref == "performance" then
      hwp_val = "Performance"
   elseif hwp_pref == "default" then
      hwp_val = "Default"
   end
   Common.text_rows_set(cpu_status, cr, 1, hwp_val)
   Common.text_rows_set(cpu_status, cr, 2,
                        Util.round_to_string(freq_sum / NUM_PHYSICAL_CORES / NUM_THREADS_PER_CORE) .. ' MHz')

   Common.percent_plot_set(total_load, cr, load_sum / NUM_PHYSICAL_CORES / NUM_THREADS_PER_CORE * 100)

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

_MODULE_Y_ = nil
_DIAL_INNER_RADIUS_ = nil
_DIAL_OUTER_RADIUS_ = nil
_DIAL_SPACING_ = nil
_TEXT_Y_OFFSET_ = nil
_SEPARATOR_SPACING_ = nil
_TEXT_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_create_core_ = nil
_FREQ_Y_ = nil
_LOAD_Y_ = nil
_SEP_Y_ = nil
_HWP_Y_ = nil
_PLOT_Y_ = nil

M.draw_static = function(cr)
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

M.draw_dynamic = function(cr)
   update(cr)

   for c = 1, NUM_PHYSICAL_CORES do
	  local this_core = cores[c]
	  CompoundDial.draw_dynamic(this_core.dials, cr)
      Common.text_ring_draw_dynamic(this_core.text_ring, cr)
   end

   Common.text_rows_draw_dynamic(cpu_status, cr)
   Common.percent_plot_draw_dynamic(total_load, cr)

   Table.draw_dynamic(tbl, cr)
end

return M
