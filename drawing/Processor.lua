local Widget		= require 'Widget'
local Arc 			= require 'Arc'
local CompoundDial 	= require 'CompoundDial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local util			= require 'util'
local Patterns		= require 'Patterns'

local CORETEMP_PATH = '/sys/devices/platform/coretemp.0/hwmon/hwmon%i/%s'

local NUM_PHYSICAL_CORES = 4
local NUM_THREADS_PER_CORE = 2

local NUM_ROWS = 5
local TABLE_CONKY = {{}, {}, {}}

for r = 1, NUM_ROWS do
	TABLE_CONKY[1][r] = '${top name '..r..'}'
	TABLE_CONKY[2][r] = '${top pid '..r..'}'
	TABLE_CONKY[3][r] = '${top cpu '..r..'}'
end

local _MODULE_Y_ = 636
local _DIAL_INNER_RADIUS_ = 30
local _DIAL_OUTER_RADIUS_ = 42
local _DIAL_SPACING_ = 1
local _TEXT_Y_OFFSET_ = 15
local _SEPARATOR_SPACING_ = 20
local _PLOT_SECTION_BREAK_ = 23
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 20
local _TABLE_HEIGHT_ = 114

local _create_core_ = function(cores, id, x, y)
	local conky_threads = {}

	for c = 0, NUM_PHYSICAL_CORES * NUM_THREADS_PER_CORE - 1 do
		if util.read_file('/sys/devices/system/cpu/cpu'..c..'/topology/core_id', nil, '*n') == id then
			table.insert(conky_threads, '${cpu cpu'..c..'}')
		end
	end

	local hwmon_index = -1
	while util.read_file(string.format(CORETEMP_PATH, hwmon_index, 'name'), nil, '*l') ~= 'coretemp' do
		hwmon_index = hwmon_index + 1
	end

	cores[id +1] = {
		dials = Widget.CompoundDial{
			x 				= x,
			y 				= y,			
			inner_radius 	= _DIAL_INNER_RADIUS_,
			outer_radius 	= _DIAL_OUTER_RADIUS_,
			spacing 		= _DIAL_SPACING_,
			num_dials 		= NUM_THREADS_PER_CORE,
			critical_limit	= '>0.8'
		},
		inner_ring = Widget.Arc{
			x = x,
			y = y,
			radius = _DIAL_INNER_RADIUS_ - 2,
			theta0 = 0,
			theta1 = 360
		},
		coretemp_text = Widget.CriticalText{
			x 				= x,
			y 				= y,
			x_align 	    = 'center',
			y_align 	    = 'center',
			append_end 		= '°C',
			critical_limit 	= '>90'
		},
		coretemp_path = string.format(CORETEMP_PATH, hwmon_index, 'temp'..(id + 2)..'_input'),
		conky_threads = conky_threads
	}
end

local header = Widget.Header{
	x = _G_INIT_DATA_.LEFT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = "PROCESSOR"
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
	labels = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _PROCESS_Y_,
		text    = 'R | S | D | T | Z'
	},
	values = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _PROCESS_Y_,
		x_align 	= 'right',
		text_color 	= Patterns.BLUE,
		text        = '<R.S.D.T.Z>'
	}
}

local _SEP_Y_ = _PROCESS_Y_ + _SEPARATOR_SPACING_

local separator = Widget.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_}
}

local _LOAD_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local total_load = {
	label = Widget.Text{
		x    = _G_INIT_DATA_.LEFT_X,
		y    = _LOAD_Y_,
		text = 'Total Load'
	},
	value = Widget.CriticalText{
		x 			    = _RIGHT_X_,
		y 			    = _LOAD_Y_,
		x_align 	    = 'right',
		append_end 	    = '%',
		critical_limit 	= '>80'
	}	
}

local _PLOT_Y_ = _LOAD_Y_ + _PLOT_SECTION_BREAK_

local plot = Widget.LabelPlot{
	x 		= _G_INIT_DATA_.LEFT_X,
	y 		= _PLOT_Y_,
	width 	= _G_INIT_DATA_.SECTION_WIDTH,
	height 	= _PLOT_HEIGHT_
}

local tbl = Widget.Table{
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
	local conky = util.conky
	local char_count = util.char_count

	local sum = 0
	for c = 1, NUM_PHYSICAL_CORES do
		local core = cores[c]
		
		local conky_threads = core.conky_threads
		for t = 1, NUM_THREADS_PER_CORE do
			local percent = util.conky_numeric(conky_threads[t]) * 0.01
			CompoundDial.set(core.dials, t, percent)
			sum = sum + percent
		end

		CriticalText.set(core.coretemp_text, cr, util.round(0.001 * util.read_file(core.coretemp_path, nil, '*n')))
	end
	
	local process_glob = util.execute_cmd('ps -A -o s')
	
	--subtract one from running b/c ps will always be "running"
	Text.set(process.values, cr, (char_count(process_glob, 'R') - 1)..' | '..
								  char_count(process_glob, 'S')..' | '..
								  char_count(process_glob, 'D')..' | '..
								  char_count(process_glob, 'T')..' | '..
								  char_count(process_glob, 'Z'))

	local load_percent = util.round(sum / NUM_PHYSICAL_CORES / NUM_THREADS_PER_CORE, 2)
	CriticalText.set(total_load.value, cr, load_percent * 100)

	LabelPlot.update(plot, load_percent)

	for c = 1, 3 do
		local column = TABLE_CONKY[c]
		for r = 1, NUM_ROWS do
			Table.set(tbl, cr, c, r, conky(column[r], '(%S+)'))
		end
	end
end

Widget = nil
Patterns = nil
_MODULE_Y_ = nil
_DIAL_INNER_RADIUS_ = nil
_DIAL_OUTER_RADIUS_ = nil
_DIAL_SPACING_ = nil
_TEXT_Y_OFFSET_ = nil
_SEPARATOR_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_create_core_ = nil
_LOAD_Y_ = nil
_RIGHT_X_ = nil
_SEP_Y_ = nil
_PROCESS_Y_ = nil
_PLOT_Y_ = nil

local draw = function(cr, current_interface)
	update(cr)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		
		for c = 1, NUM_PHYSICAL_CORES do
			local core = cores[c]
			CompoundDial.draw(core.dials, cr)
			Arc.draw(core.inner_ring, cr)
			CriticalText.draw(core.coretemp_text, cr)
		end

		Text.draw(process.labels, cr)
		Text.draw(process.values, cr)

		Line.draw(separator, cr)
		
		Text.draw(total_load.label, cr)
		CriticalText.draw(total_load.value, cr)

		LabelPlot.draw(plot, cr)

		Table.draw(tbl, cr)
	end
end

return draw
