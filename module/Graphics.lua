local Widget		= require 'Widget'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local util			= require 'util'
local schema		= require 'default_patterns'

local _TONUMBER		= tonumber

--construction params
local MODULE_Y = 145
local SEPARATOR_SPACING = 20
local TEXT_SPACING = 20
local PLOT_SEC_BREAK = 20
local PLOT_HEIGHT = 56

local header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.LEFT_X,
	y = MODULE_Y,
	width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	header = 'NVIDIA GRAPHICS'
}

local RIGHT_X = CONSTRUCTION_GLOBAL.LEFT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH

local status = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= header.bottom_y,
		text    = 'Status'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= header.bottom_y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<status>'
	}
}

local SEP_Y_1 = header.bottom_y + SEPARATOR_SPACING

local separator1 = Widget.Line{
	p1 = {x = CONSTRUCTION_GLOBAL.LEFT_X, y = SEP_Y_1},
	p2 = {x = RIGHT_X, y = SEP_Y_1}
}

local INTERNAL_TEMP_Y = SEP_Y_1 + SEPARATOR_SPACING

local internal_temp = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= INTERNAL_TEMP_Y,
		text    = 'Internal Temperature'
	},
	value = Widget.CriticalText{
		x 			= RIGHT_X,
		y 			= INTERNAL_TEMP_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<gpu_temp>'
	}
}

local PCI_UTIL_Y = INTERNAL_TEMP_Y + TEXT_SPACING

local pci_util = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= PCI_UTIL_Y,
		text    = 'PCI Utilization'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= PCI_UTIL_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<pci_util>'
	}
}

local SEP_Y_2 = PCI_UTIL_Y + SEPARATOR_SPACING

local separator2 = Widget.Line{
	p1 = {x = CONSTRUCTION_GLOBAL.LEFT_X, y = SEP_Y_2},
	p2 = {x = RIGHT_X, y = SEP_Y_2}
}

local CLOCK_SPEED_Y = SEP_Y_2 + SEPARATOR_SPACING

local clock_speed = {
	labels = Widget.TextColumn{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= CLOCK_SPEED_Y,
		spacing = TEXT_SPACING,
		'GPU Clock Speed',
		'Memory Clock Speed'
	},
	values = Widget.TextColumn{
		x 			= CONSTRUCTION_GLOBAL.LEFT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		y 			= CLOCK_SPEED_Y,
		spacing 	= TEXT_SPACING,
		x_align 	= 'right',
		text_color 	= schema.blue,
		num_rows 	= 2
	}
}

local SEP_Y_3 = CLOCK_SPEED_Y + TEXT_SPACING * 2

local separator3 = Widget.Line{
	p1 = {x = CONSTRUCTION_GLOBAL.LEFT_X, y = SEP_Y_3},
	p2 = {x = RIGHT_X, y = SEP_Y_3}
}

local GPU_UTIL_Y = SEP_Y_3 + SEPARATOR_SPACING
local GPU_UTIL_PLOT_Y = GPU_UTIL_Y + PLOT_SEC_BREAK

local gpu_util = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= GPU_UTIL_Y,
		text    = 'GPU Utilization'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= GPU_UTIL_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<gpu_util>'
	},
	plot = Widget.LabelPlot{
		x		= CONSTRUCTION_GLOBAL.LEFT_X,
		y		= GPU_UTIL_PLOT_Y,
		width	= CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height	= PLOT_HEIGHT
	}
}

local MEM_UTIL_Y = GPU_UTIL_PLOT_Y + PLOT_HEIGHT + PLOT_SEC_BREAK
local MEM_UTIL_PLOT_Y = MEM_UTIL_Y + PLOT_SEC_BREAK

local mem_util = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= MEM_UTIL_Y,
		text    = 'Memory Utilization'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= MEM_UTIL_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<mem_util>'
	},
	plot = Widget.LabelPlot{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= MEM_UTIL_PLOT_Y,
		width 	= CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height 	= PLOT_HEIGHT
	}
}

local VID_UTIL_Y = MEM_UTIL_PLOT_Y + PLOT_HEIGHT + PLOT_SEC_BREAK
local VID_UTIL_PLOT_Y = VID_UTIL_Y + PLOT_SEC_BREAK

local vid_util = {
	label = Widget.Text{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= VID_UTIL_Y,
		text    = 'Video Utilization'
	},
	value = Widget.Text{
		x 			= RIGHT_X,
		y 			= VID_UTIL_Y,
		x_align 	= 'right',
		text_color 	= schema.blue,
		text        = '<vid_util>'
	},
	plot = Widget.LabelPlot{
		x 		= CONSTRUCTION_GLOBAL.LEFT_X,
		y 		= VID_UTIL_PLOT_Y,
		width 	= CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		height 	= PLOT_HEIGHT
	}
}

--[[
vars to process the nv settings glob

glob will be of the form:
	<used_mem>
	<total_mem>
	<temp>
	<gpu_freq>,<mem_freq>
	graphics=<gpu_util>, memory=<mem_util>, video=<vid_util>, PCIe=<pci_util>
--]]
local NV_QUERY = 'optirun nvidia-settings -c :8 -t'..
	' -q UsedDedicatedGPUMemory'..
	' -q TotalDedicatedGPUMemory'..
	' -q ThermalSensorReading'..
	' -q [gpu:0]/GPUCurrentClockFreqs'..
	' -q [gpu:0]/GPUUtilization'

local NV_REGEX = '(%d+)\n'..
				 '(%d+)\n'..
				 '(%d+)\n'..
				 '(%d+),(%d+)\n'..
				 'graphics=(%d+), memory=%d+, video=(%d+), PCIe=(%d+)\n'

local __nvidia_off = function(cr)
	CriticalText.set(internal_temp.value, cr, 'N/A', 1)
	Text.set(pci_util.value, cr, 'N/A')

	TextColumn.set(clock_speed.values, cr, 1, 'N/A')
	TextColumn.set(clock_speed.values, cr, 2, 'N/A')

	Text.set(gpu_util.value, cr, 'N/A')
	Text.set(mem_util.value, cr, 'N/A')
	Text.set(vid_util.value, cr, 'N/A')

	LabelPlot.update(gpu_util.plot, 0)
	LabelPlot.update(mem_util.plot, 0)
	LabelPlot.update(vid_util.plot, 0)
end
				 
local __update = function(cr)
	if util.read_file('/proc/acpi/bbswitch', '.+%s+(%u+)') == 'ON' then
		if string.find(util.execute_cmd('ps -A -o comm'), 'optirun') == nil then
			Text.set(status.value, cr, 'Mixed')
			__nvidia_off(cr)
		else
			Text.set(status.value, cr, 'On')
			local nvidia_settings_glob = util.execute_cmd(NV_QUERY)

			local used_memory, total_memory, temp_reading, gpu_frequency,
				memory_frequency, gpu_utilization, vid_utilization,
				pci_utilization = string.match(nvidia_settings_glob, NV_REGEX)

			local force = 1
			if _TONUMBER(temp_reading) > 80 then force = 0 end

			CriticalText.set(internal_temp.value, cr, temp_reading..'°C', force)
			Text.set(pci_util.value, cr, pci_utilization..'%')

			TextColumn.set(clock_speed.values, cr, 1, gpu_frequency..' Mhz')
			TextColumn.set(clock_speed.values, cr, 2, memory_frequency..' Mhz')

			local percent_used_memory = used_memory / total_memory

			Text.set(gpu_util.value, cr, gpu_utilization..'%')
			Text.set(mem_util.value, cr, util.round(percent_used_memory * 100)..'%')
			Text.set(vid_util.value, cr, vid_utilization..'%')

			LabelPlot.update(gpu_util.plot, gpu_utilization * 0.01)
			LabelPlot.update(mem_util.plot, percent_used_memory)
			LabelPlot.update(vid_util.plot, vid_utilization * 0.01)
		end
	else
		Text.set(status.value, cr, 'Off')
		__nvidia_off(cr)
	end
end

Widget = nil
schema = nil
MODULE_Y = nil
SEPARATOR_SPACING = nil
TEXT_SPACING = nil
PLOT_SECTION_BREAK = nil
PLOT_HEIGHT = nil
RIGHT_X = nil
SEP_Y_1 = nil
SEP_Y_2 = nil
SEP_Y_3 = nil
INTERNAL_TEMP_Y = nil
PCI_UTIL_Y = nil
CLOCK_SPEED_Y = nil
GPU_UTIL_Y = nil
GPU_UTIL_PLOT_Y = nil
MEM_UTIL_Y = nil
MEM_UTIL_PLOT_Y = nil
VID_UTIL_Y = nil
VID_UTIL_PLOT_Y = nil

local draw = function(cr, current_interface)
	__update(cr)

	if current_interface == 0 then
		Text.draw(header.text, cr)
		Line.draw(header.underline, cr)
		
		Text.draw(status.label, cr)
		Text.draw(status.value, cr)

		Line.draw(separator1, cr)

		Text.draw(internal_temp.label, cr)
		Text.draw(internal_temp.value, cr)
		
		Text.draw(pci_util.label, cr)
		Text.draw(pci_util.value, cr)

		Line.draw(separator2, cr)
		
		TextColumn.draw(clock_speed.labels, cr)
		TextColumn.draw(clock_speed.values, cr)
	
		Line.draw(separator3, cr)
		
		Text.draw(gpu_util.label, cr)
		Text.draw(gpu_util.value, cr)
		LabelPlot.draw(gpu_util.plot, cr)
		
		Text.draw(mem_util.label, cr)
		Text.draw(mem_util.value, cr)
		LabelPlot.draw(mem_util.plot, cr)
		
		Text.draw(vid_util.label, cr)
		Text.draw(vid_util.value, cr)
		LabelPlot.draw(vid_util.plot, cr)
	end
end

return draw

