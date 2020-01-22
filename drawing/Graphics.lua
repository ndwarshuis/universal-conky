local M = {}

local CriticalText	= require 'CriticalText'
local Text			= require 'Text'
local TextColumn	= require 'TextColumn'
local Line			= require 'Line'
local LabelPlot		= require 'LabelPlot'
local Util			= require 'Util'

local __tonumber		= tonumber
local __string_find 	= string.find
local __string_match	= string.match

local _MODULE_Y_ = 145
local _SEPARATOR_SPACING_ = 20
local _TEXT_SPACING_ = 20
local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.LEFT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'NVIDIA GRAPHICS'
}

local _RIGHT_X_ = _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH

local status = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= header.bottom_y,
		text    = 'Status'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= header.bottom_y,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		text        = '<status>'
	}
}

local _SEP_Y_1_ = header.bottom_y + _SEPARATOR_SPACING_

local separator1 = _G_Widget_.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_1_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_1_}
}

local _INTERNAL_TEMP_Y_ = _SEP_Y_1_ + _SEPARATOR_SPACING_

local internal_temp = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _INTERNAL_TEMP_Y_,
		text    = 'Internal Temperature'
	},
	value = _G_Widget_.CriticalText{
		x 			= _RIGHT_X_,
		y 			= _INTERNAL_TEMP_Y_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		text        = '<gpu_temp>'
	}
}

local _SEP_Y_2_ = _INTERNAL_TEMP_Y_ + _SEPARATOR_SPACING_

local separator2 = _G_Widget_.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_2_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_2_}
}

local _CLOCK_SPEED_Y_ = _SEP_Y_2_ + _SEPARATOR_SPACING_

local clock_speed = {
	labels = _G_Widget_.TextColumn{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _CLOCK_SPEED_Y_,
		spacing = _TEXT_SPACING_,
		'GPU Clock Speed',
		'Memory Clock Speed'
	},
	values = _G_Widget_.TextColumn{
		x 			= _G_INIT_DATA_.LEFT_X + _G_INIT_DATA_.SECTION_WIDTH,
		y 			= _CLOCK_SPEED_Y_,
		spacing 	= _TEXT_SPACING_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		num_rows 	= 2
	}
}

local _SEP_Y_3_ = _CLOCK_SPEED_Y_ + _TEXT_SPACING_ * 2

local separator3 = _G_Widget_.Line{
	p1 = {x = _G_INIT_DATA_.LEFT_X, y = _SEP_Y_3_},
	p2 = {x = _RIGHT_X_, y = _SEP_Y_3_}
}

local _GPU_UTIL_Y_ = _SEP_Y_3_ + _SEPARATOR_SPACING_

local gpu_util = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _GPU_UTIL_Y_,
		text    = 'GPU Utilization'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _GPU_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		text        = '<gpu_util>'
	},
	plot = _G_Widget_.LabelPlot{
		x		= _G_INIT_DATA_.LEFT_X,
		y		= _GPU_UTIL_Y_ + _PLOT_SEC_BREAK_,
		width	= _G_INIT_DATA_.SECTION_WIDTH,
		height	= _PLOT_HEIGHT_
	}
}

local _MEM_UTIL_Y_ = _GPU_UTIL_Y_ + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local mem_util = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _MEM_UTIL_Y_,
		text    = 'Memory Utilization'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _MEM_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		text        = '<mem_util>'
	},
	plot = _G_Widget_.LabelPlot{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _MEM_UTIL_Y_ + _PLOT_SEC_BREAK_,
		width 	= _G_INIT_DATA_.SECTION_WIDTH,
		height 	= _PLOT_HEIGHT_
	}
}

local _VID_UTIL_Y_ = _MEM_UTIL_Y_ + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local vid_util = {
	label = _G_Widget_.Text{
		x 		= _G_INIT_DATA_.LEFT_X,
		y 		= _VID_UTIL_Y_,
		text    = 'Video Utilization'
	},
	value = _G_Widget_.Text{
		x 			= _RIGHT_X_,
		y 			= _VID_UTIL_Y_,
		x_align 	= 'right',
		text_color 	= _G_Patterns_.PURPLE,
		text        = '<vid_util>'
	},
	plot = _G_Widget_.LabelPlot{
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
				 'graphics=(%d+), memory=%d+, video=(%d+), PCIe=%d+\n'

local NA = 'N/A'

local nvidia_off = function(cr)
	CriticalText.set(internal_temp.value, cr, NA, false)

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
	if Util.read_file('/proc/acpi/bbswitch', '.+%s+(%u+)') == 'ON' then

		-- bbswitch might be on, but only because conky is constantly querying
		-- it and there appears to be some lag between closing all optirun
		-- processes and flipping bbswitch off. If bbswitch is on and there are
		-- no optirun processes, we call this "Mixed." In this case we don't
		-- check anything (to allow bbswitch to actually switch off) and set all
		-- values to N/A and 0.
		if not __string_find(Util.execute_cmd('ps -A -o comm'), 'optirun') then
			Text.set(status.value, cr, 'Mixed')
			nvidia_off(cr)
		else
			Text.set(status.value, cr, 'On')
			local nvidia_settings_glob = Util.execute_cmd(NV_QUERY)

			local used_memory, total_memory, temp_reading, gpu_frequency,
				memory_frequency, gpu_utilization, vid_utilization
				= __string_match(nvidia_settings_glob, NV_REGEX)

			local is_critical = false
			if __tonumber(temp_reading) > 80 then is_critical = true end

			CriticalText.set(internal_temp.value, cr, temp_reading..'°C', is_critical)

			TextColumn.set(clock_speed.values, cr, 1, gpu_frequency..' Mhz')
			TextColumn.set(clock_speed.values, cr, 2, memory_frequency..' Mhz')

			local percent_used_memory = used_memory / total_memory

			Text.set(gpu_util.value, cr, gpu_utilization..'%')
			Text.set(mem_util.value, cr, Util.round(percent_used_memory * 100)..'%')
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
_CLOCK_SPEED_Y_ = nil
_GPU_UTIL_Y_ = nil
_MEM_UTIL_Y_ = nil
_VID_UTIL_Y_ = nil

local draw_static = function(cr)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)

   Text.draw(status.label, cr)
   Line.draw(separator1, cr)

   Text.draw(internal_temp.label, cr)
   Line.draw(separator2, cr)

   TextColumn.draw(clock_speed.labels, cr)
   Line.draw(separator3, cr)

   Text.draw(gpu_util.label, cr)
   LabelPlot.draw_static(gpu_util.plot, cr)

   Text.draw(mem_util.label, cr)
   LabelPlot.draw_static(mem_util.plot, cr)

   Text.draw(vid_util.label, cr)
   LabelPlot.draw_static(vid_util.plot, cr)
end

local draw_dynamic = function(cr)
   update(cr)

   Text.draw(status.value, cr)
   Text.draw(internal_temp.value, cr)
   TextColumn.draw(clock_speed.values, cr)
   
   Text.draw(gpu_util.value, cr)
   LabelPlot.draw_dynamic(gpu_util.plot, cr)
   
   Text.draw(mem_util.value, cr)
   LabelPlot.draw_dynamic(mem_util.plot, cr)
	
   Text.draw(vid_util.value, cr)
   LabelPlot.draw_dynamic(vid_util.plot, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
