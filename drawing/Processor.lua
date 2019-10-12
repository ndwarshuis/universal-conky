local M = {}

local Arc 			= require 'Arc'
local CompoundDial 	= require 'CompoundDial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'

local __string_format = string.format

local CORETEMP_PATH = '/sys/devices/platform/coretemp.0/hwmon/hwmon%i/%s'

local NUM_PHYSICAL_CORES = 4
local NUM_THREADS_PER_CORE = 2

local NUM_ROWS = 5

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
	  dials = _G_Widget_.CompoundDial{
		 x 				= x,
		 y 				= y,
		 inner_radius 	= _DIAL_INNER_RADIUS_,
		 outer_radius 	= _DIAL_OUTER_RADIUS_,
		 spacing 		= _DIAL_SPACING_,
		 num_dials 		= NUM_THREADS_PER_CORE,
		 critical_limit	= '>0.8'
	  },
	  inner_ring = _G_Widget_.Arc{
		 x = x,
		 y = y,
		 radius = _DIAL_INNER_RADIUS_ - 2,
		 theta0 = 0,
		 theta1 = 360
	  },
	  coretemp_text = _G_Widget_.CriticalText{
		 x 				= x,
		 y 				= y,
		 x_align 	    = 'center',
		 y_align 	    = 'center',
		 append_end 		= '°C',
		 critical_limit 	= '>90'
	  },
	  coretemp_path = string.format(CORETEMP_PATH, hwmon_index, 'temp'..(id + 2)..'_input'),
	  conky_loads = conky_loads,
	  conky_freqs = conky_freqs
   }
end

local header = _G_Widget_.Header{
   x = _G_INIT_DATA_.LEFT_X,
   y = _MODULE_Y_,
   width = _G_INIT_DATA_.SECTION_WIDTH,
   header = 'PROCESSOR'
}

--we assume that this cpu has 4 physical cores with 2 logical each
local cores = {}

for c = 0, NUM_PHYSICAL_CORES - 1 do
   local dial_x = _G_INIT_DATA_.LEFT_X + _DIAL_OUTER_RADIUS_ +
	  (_G_INIT_DATA_.SECTION_WIDTH - 2 * _DIAL_OUTER_RADIUS_) * c / 3
   local dial_y = header.bottom_y + _DIAL_OUTER_RADIUS_
   _create_core_(cores, c, dial_x, dial_y)
end

local _RIGHT_X_ = _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH

local _PROCESS_Y_ = header.bottom_y + _DIAL_OUTER_RADIUS_ * 2 + _PLOT_SECTION_BREAK_

local process = {
   label = _G_Widget_.Text{
	  x 		= _G_INIT_DATA_.LEFT_X,
	  y 		= _PROCESS_Y_,
	  text 	= 'R | S | D | T | Z'
   },
   value = _G_Widget_.Text{
	  x 			= _RIGHT_X_,
	  y 			= _PROCESS_Y_,
	  x_align 	= 'right',
	  text_color 	= _G_Patterns_.BLUE,
	  text		= '<R> | <S> | <D> | <T> | <Z>'
   }
}

local _FREQ_Y_ = _PROCESS_Y_ + _TEXT_SPACING_

local ave_freq = {
   label = _G_Widget_.Text{
	  x 		= _G_INIT_DATA_.LEFT_X,
	  y 		= _FREQ_Y_,
	  text 	= 'Ave Freq'
   },
   value = _G_Widget_.Text{
	  x 			= _RIGHT_X_,
	  y 			= _FREQ_Y_,
	  x_align 	= 'right',
	  text_color 	= _G_Patterns_.BLUE,
	  text		= '<freq>'
   }
}

local _SEP_Y_ = _FREQ_Y_ + _SEPARATOR_SPACING_

local separator = _G_Widget_.Line{
   p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_},
   p2 = {x = _RIGHT_X_, y = _SEP_Y_}
}

local _LOAD_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local total_load = {
   label = _G_Widget_.Text{
	  x    = _G_INIT_DATA_.LEFT_X,
	  y    = _LOAD_Y_,
	  text = 'Total Load'
   },
   value = _G_Widget_.CriticalText{
	  x 			    = _RIGHT_X_,
	  y 			    = _LOAD_Y_,
	  x_align 	    = 'right',
	  append_end 	    = '%',
	  critical_limit 	= '>80'
   }
}

local _PLOT_Y_ = _LOAD_Y_ + _PLOT_SECTION_BREAK_

local plot = _G_Widget_.LabelPlot{
   x 		= _G_INIT_DATA_.LEFT_X,
   y 		= _PLOT_Y_,
   width 	= _G_INIT_DATA_.SECTION_WIDTH,
   height 	= _PLOT_HEIGHT_
}

local tbl = _G_Widget_.Table{
   x 		 = _G_INIT_DATA_.LEFT_X,
   y 		 = _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
   width 	 = _G_INIT_DATA_.SECTION_WIDTH,
   height 	 = _TABLE_HEIGHT_,
   num_rows = NUM_ROWS,
   'Name',
   'PID',
   'CPU (%)'
}

local update = function(cr)
   local conky = Util.conky
   local char_count = Util.char_count

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

	  CriticalText.set(core.coretemp_text, cr, Util.round_to_string(0.001 * Util.read_file(core.coretemp_path, nil, '*n')))
   end

   -- trimming the string actually helps performance
   local process_glob = Util.execute_cmd('ps -A -o s h | tr -d "I\n"')

   -- subtract one from running b/c ps will always be "running"
   Text.set(process.value, cr,
            __string_format('%s | %s | %s | %s | %s',
                            (char_count(process_glob, 'R') - 1),
                            char_count(process_glob, 'S'),
                            char_count(process_glob, 'D'),
                            char_count(process_glob, 'T'),
                            char_count(process_glob, 'Z')))

   Text.set(ave_freq.value, cr, Util.round_to_string(freq_sum / NUM_PHYSICAL_CORES / NUM_THREADS_PER_CORE) .. ' MHz')

   local load_percent = Util.round(load_sum / NUM_PHYSICAL_CORES / NUM_THREADS_PER_CORE, 2)
   CriticalText.set(total_load.value, cr,
                    Util.round_to_string(load_percent * 100))

   LabelPlot.update(plot, load_percent)

   for r = 1, NUM_ROWS do
      local pid = conky(TABLE_CONKY[r].pid, '(%d+)') -- may have leading spaces
      if pid ~= '' then
         local cpu = conky(TABLE_CONKY[r].cpu)
         local comm = Util.read_file('/proc/'..pid..'/comm')
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
_RIGHT_X_ = nil
_SEP_Y_ = nil
_PROCESS_Y_ = nil
_PLOT_Y_ = nil

local draw_static = function(cr)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)

   for c = 1, NUM_PHYSICAL_CORES do
	  local this_core = cores[c]
	  Arc.draw(this_core.inner_ring, cr)
	  CompoundDial.draw_static(this_core.dials, cr)
   end

   Text.draw(process.label, cr)
   Text.draw(ave_freq.label, cr)
   Line.draw(separator, cr)

   Text.draw(total_load.label, cr)
   LabelPlot.draw_static(plot, cr)

   Table.draw_static(tbl, cr)
end

local draw_dynamic = function(cr)
   update(cr)

   for c = 1, NUM_PHYSICAL_CORES do
	  local this_core = cores[c]
	  CompoundDial.draw_dynamic(this_core.dials, cr)
	  CriticalText.draw(this_core.coretemp_text, cr)
   end

   Text.draw(process.value, cr)
   Text.draw(ave_freq.value, cr)

   CriticalText.draw(total_load.value, cr)
   LabelPlot.draw_dynamic(plot, cr)

   Table.draw_dynamic(tbl, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
