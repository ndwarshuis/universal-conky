local Widget		= require 'Widget'
local Arc 			= require 'Arc'
local CompoundDial 	= require 'CompoundDial'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local util			= require 'util'
local schema		= require 'default_patterns'

local CORETEMP_PATH = '/sys/devices/platform/coretemp.0/hwmon/hwmon%i/%s'

local NUM_PHYSICAL_CORES = 4
local NUM_PHYSICAL_CORE_THREADS = 2

local NUM_ROWS = 5
local TABLE_CONKY = {{}, {}, {}}

for r = 1, NUM_ROWS do
	TABLE_CONKY[1][r] = '${top name '..r..'}'
	TABLE_CONKY[2][r] = '${top pid '..r..'}'
	TABLE_CONKY[3][r] = '${top cpu '..r..'}'
end

local MODULE_Y_ = 636
local DIAL_INNER_RADIUS_ = 30
local DIAL_OUTER_RADIUS_ = 42
local DIAL_SPACING_ = 1
local TEXT_Y_OFFSET_ = 15
local SEPARATOR_SPACING_ = 20
local PLOT_SECTION_BREAK_ = 23
local PLOT_HEIGHT_ = 56
local TABLE_SECTION_BREAK_ = 20
local TABLE_HEIGHT_ = 114

local create_core_ = function(cores, id, x, y)
	local conky_threads = {}

	for c = 0, NUM_PHYSICAL_CORES * NUM_PHYSICAL_CORE_THREADS - 1 do
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
			inner_radius 	= DIAL_INNER_RADIUS_,
			outer_radius 	= DIAL_OUTER_RADIUS_,
			spacing 		= DIAL_SPACING_,
			num_dials 		= NUM_PHYSICAL_CORE_THREADS,
			critical_limit	= '>0.8'
		},
		inner_ring = Widget.Arc{
			x = x,
			y = y,
			radius = DIAL_INNER_RADIUS_ - 2,
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
	x = __G_INIT_DATA__.LEFT_X,
	y = MODULE_Y_,
	width = __G_INIT_DATA__.SECTION_WIDTH,
	header = "PROCESSOR"
}

local HEADER_BOTTOM_Y_ = header.bottom_y

--we assume that this cpu has 4 physical cores with 2 logical each
local cores = {}

for c = 0, NUM_PHYSICAL_CORES - 1 do
	local dial_x = __G_INIT_DATA__.LEFT_X + DIAL_OUTER_RADIUS_ + (__G_INIT_DATA__.SECTION_WIDTH - 2 * DIAL_OUTER_RADIUS_) * c / 3
	create_core_(cores, c, dial_x, HEADER_BOTTOM_Y_ + DIAL_OUTER_RADIUS_)
end

local RIGHT_X = __G_INIT_DATA__.LEFT_X + __G_INIT_DATA__.SECTION_WIDTH

local PROCESS_Y = HEADER_BOTTOM_Y_ + DIAL_OUTER_RADIUS_ * 2 + PLOT_SECTION_BREAK_

local process = {
	labels = Widget.Text{
		x 		= __G_INIT_DATA__.LEFT_X,
		y 		= PROCESS_Y,
		text    = 'R | S | D | T | Z'
	},
	values = Widget.Text{
		x 			= RIGHT_X,
		y 			= PROCESS_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<R.S.D.T.Z>'
	}
}

local SEP_Y = PROCESS_Y + SEPARATOR_SPACING_

local separator = Widget.Line{
	p1 = {x = __G_INIT_DATA__.LEFT_X, y = SEP_Y},
	p2 = {x = RIGHT_X, y = SEP_Y}
}

local LOAD_Y = SEP_Y + SEPARATOR_SPACING_

local total_load = {
	label = Widget.Text{
		x    = __G_INIT_DATA__.LEFT_X,
		y    = LOAD_Y,
		text = 'Total Load'
	},
	value = Widget.CriticalText{
		x 			    = RIGHT_X,
		y 			    = LOAD_Y,
		x_align 	    = 'right',
		append_end 	    = '%',
		critical_limit 	= '>80'
	}	
}

local PLOT_Y = LOAD_Y + PLOT_SECTION_BREAK_

local plot = Widget.LabelPlot{
	x 		= __G_INIT_DATA__.LEFT_X,
	y 		= PLOT_Y,
	width 	= __G_INIT_DATA__.SECTION_WIDTH,
	height 	= PLOT_HEIGHT_
}

local TABLE_Y = PLOT_Y + PLOT_HEIGHT_ + TABLE_SECTION_BREAK_

local tbl = Widget.Table{
	x 		 = __G_INIT_DATA__.LEFT_X,
	y 		 = TABLE_Y,
	width 	 = __G_INIT_DATA__.SECTION_WIDTH,
	height 	 = TABLE_HEIGHT_,
	num_rows = NUM_ROWS,
	'Name',
	'PID',
	'CPU (%)'
}

local __update = function(cr)
	local conky = util.conky
	local char_count = util.char_count

	local sum = 0
	for c = 1, NUM_PHYSICAL_CORES do
		local core = cores[c]
		
		local conky_threads = core.conky_threads
		for t = 1, NUM_PHYSICAL_CORE_THREADS do
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

	local load_percent = util.round(sum / NUM_PHYSICAL_CORES / NUM_PHYSICAL_CORE_THREADS, 2)
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
schema = nil
MODULE_Y_ = nil
DIAL_INNER_RADIUS_ = nil
DIAL_OUTER_RADIUS_ = nil
DIAL_SPACING_ = nil
TEXT_Y_OFFSET_ = nil
SEPARATOR_SPACING_ = nil
PLOT_SECTION_BREAK_ = nil
PLOT_HEIGHT_ = nil
TABLE_SECTION_BREAK_ = nil
TABLE_HEIGHT_ = nil
create_core_ = nil
HEADER_BOTTOM_Y_ = nil
LOAD_Y = nil
RIGHT_X = nil
SEP_Y = nil
PROCESS_Y = nil
PLOT_Y = nil
TABLE_Y = nil

local draw = function(cr, current_interface)
	__update(cr)

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
