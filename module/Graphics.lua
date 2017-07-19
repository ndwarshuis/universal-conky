local Widget		= require 'Widget'
local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local util			= require 'util'
local schema		= require 'default_patterns'

local __tonumber		= tonumber
local __string_find 	= string.find
local __string_match	= string.match

local _MODULE_Y_ = 145
local _SEPARATOR_SPACING_ = 20
local _TEXT_SPACING_ = 20
local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local header = Widget.Header{
	x = _G_INIT_DATA_.LEFT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'NVIDIA GRAPHICS'
}

local _RIGHT_X_ = _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH

local status = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= header.bottom_y,
		text    = 'Status'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= header.bottom_y,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		text        = '<status>'
	}
}

local _SEP_Y_1_ = header.bottom_y + _SEPARATOR_SPACING_

local separator1 = Widget.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_1_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_1_}
}

local _INTERNAL_TEMP_Y_ = _SEP_Y_1_ + _SEPARATOR_SPACING_

local internal_temp = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _INTERNAL_TEMP_Y_,
		text    = 'Internal Temperature'
	},
	value = Widget.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _INTERNAL_TEMP_Y_,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		text        = '<gpu_temp>'
	}
}

local _PCI_UTIL_Y_ = _INTERNAL_TEMP_Y_ + _TEXT_SPACING_

local pci_util = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _PCI_UTIL_Y_,
		text    = 'PCI Utilization'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _PCI_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		text        = '<pci_util>'
	}
}

local _SEP_Y_2_ = _PCI_UTIL_Y_ + _SEPARATOR_SPACING_

local separator2 = Widget.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_2_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_2_}
}

local _CLOCK_SPEED_Y_ = _SEP_Y_2_ + _SEPARATOR_SPACING_

local clock_speed = {
	labels = Widget.TextColumn{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _CLOCK_SPEED_Y_,
		spacing = _TEXT_SPACING_,
		'GPU Clock Speed',
		'Memory Clock Speed'
	},
	values = Widget.TextColumn{
		x 			= _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH,
		y 			= _CLOCK_SPEED_Y_,
		spacing 	= _TEXT_SPACING_,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		num_rows 	= 2
	}
}

local _SEP_Y_3_ = _CLOCK_SPEED_Y_ + _TEXT_SPACING_ * 2

local separator3 = Widget.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_3_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_3_}
}

local _GPU_UTIL_Y_ = _SEP_Y_3_ + _SEPARATOR_SPACING_

local gpu_util = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _GPU_UTIL_Y_,
		text    = 'GPU Utilization'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _GPU_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		text        = '<gpu_util>'
	},
	plot = Widget.LabelPlot{
		x		= _G_INIT_DATA_.LEFT_X,
		y		= _GPU_UTIL_Y_ + _PLOT_SEC_BREAK_,
		width	= _G_INIT_DATA_.SECTION_WIDTH,
		height	= _PLOT_HEIGHT_
	}
}

local _MEM_UTIL_Y_ = _GPU_UTIL_Y_ + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local mem_util = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _MEM_UTIL_Y_,
		text    = 'Memory Utilization'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _MEM_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		text        = '<mem_util>'
	},
	plot = Widget.LabelPlot{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _MEM_UTIL_Y_ + _PLOT_SEC_BREAK_,
		width 	= _G_INIT_DATA_.SECTION_WIDTH,
		height 	= _PLOT_HEIGHT_
	}
}

local _VID_UTIL_Y_ = _MEM_UTIL_Y_ + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local vid_util = {
	label = Widget.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _VID_UTIL_Y_,
		text    = 'Video Utilization'
	},
	value = Widget.Text{
		x 			= _RIGHT_X_,
		y 			= _VID_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= schema.BLUE,
		text        = '<vid_util>'
	},
	plot = Widget.LabelPlot{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _VID_UTIL_Y_ + _PLOT_SEC_BREAK_,
		width 	= _G_INIT_DATA_.SECTION_WIDTH,
		height 	= _PLOT_HEIGHT_
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

local NA = 'N/A'

local nvidia_off = function(cr)
	CriticalText.set(internal_temp.value, cr, NA, 1)
	Text.set(pci_util.value, cr, NA)

	TextColumn.set(clock_speed.values, cr, 1, NA)
	TextColumn.set(clock_speed.values, cr, 2, NA)

	Text.set(gpu_util.value, cr, NA)
	Text.set(mem_util.value, cr, NA)
	Text.set(vid_util.value, cr, NA)

	LabelPlot.update(gpu_util.plot, 0)
	LabelPlot.update(mem_util.plot, 0)
	LabelPlot.update(vid_util.plot, 0)
end
				 
local update = function(cr)
    -- check if bbswitch is on
	if util.read_file('/proc/acpi/bbswitch', '.+%s+(%u+)') == 'ON' then

		-- bbswitch might be on, but only because conky is constantly querying
		-- it and there appears to be some lag between closing all optirun
		-- processes and flipping bbswitch off. If bbswitch is on and there are
		-- no optirun processes, we call this "Mixed." In this case we don't
		-- check anything (to allow bbswitch to actually switch off) and set all
		-- values to N/A and 0.
		if __string_find(util.execute_cmd('ps -A -o comm'), 'optirun') == nil then
			Text.set(status.value, cr, 'Mixed')
			nvidia_off(cr)
		else
			Text.set(status.value, cr, 'On')
			local nvidia_settings_glob = util.execute_cmd(NV_QUERY)

			local used_memory, total_memory, temp_reading, gpu_frequency,
				memory_frequency, gpu_utilization, vid_utilization,
				pci_utilization = __string_match(nvidia_settings_glob, NV_REGEX)

			local is_critical = 1
			if __tonumber(temp_reading) > 80 then is_critical = 0 end

			CriticalText.set(internal_temp.value, cr, temp_reading..'°C', is_critical)
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
		nvidia_off(cr)
	end
end

Widget = nil
schema = nil
_MODULE_Y_ = nil
_SEPARATOR_SPACING_ = nil
_TEXT_SPACING_ = nil
_PLOT_SEC_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_RIGHT_X_ = nil
_SEP_Y_1_ = nil
_SEP_Y_2_ = nil
_SEP_Y_3_ = nil
_INTERNAL_TEMP_Y_ = nil
_PCI_UTIL_Y_ = nil
_CLOCK_SPEED_Y_ = nil
_GPU_UTIL_Y_ = nil
_MEM_UTIL_Y_ = nil
_VID_UTIL_Y_ = nil

local draw = function(cr, current_interface)
	update(cr)

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

