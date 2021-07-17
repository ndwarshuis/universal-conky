local Text			= require 'Text'
local Line			= require 'Line'
local Util			= require 'Util'
local Common		= require 'Common'
local Geometry		= require 'Geometry'

local __string_match	= string.match

local _MODULE_Y_ = 145
local _SEPARATOR_SPACING_ = 20
local _TEXT_SPACING_ = 20
local _PLOT_SEC_BREAK_ = 20
local _PLOT_HEIGHT_ = 56

local NA = 'N/A'

local na_percent_format = function(x)
   if x == -1 then return NA else return string.format('%s%%', x) end
end

local header = Common.Header(
	Geometry.LEFT_X,
	_MODULE_Y_,
	Geometry.SECTION_WIDTH,
	'NVIDIA GRAPHICS'
)

local status = Common.initTextRow(
   Geometry.LEFT_X,
   header.bottom_y,
   Geometry.SECTION_WIDTH,
   'Status'
)

local _SEP_Y_1_ = header.bottom_y + _SEPARATOR_SPACING_

local separator1 = Common.initSeparator(
   Geometry.LEFT_X,
   _SEP_Y_1_,
   Geometry.SECTION_WIDTH
)

local _INTERNAL_TEMP_Y_ = _SEP_Y_1_ + _SEPARATOR_SPACING_

local internal_temp = Common.initTextRowCrit(
   Geometry.LEFT_X,
   _INTERNAL_TEMP_Y_,
   Geometry.SECTION_WIDTH,
   'Internal Temperature',
   function(s) if s == -1 then return NA else return string.format('%s°C', s) end end,
   80
)

local _SEP_Y_2_ = _INTERNAL_TEMP_Y_ + _SEPARATOR_SPACING_

local separator2 = Common.initSeparator(
   Geometry.LEFT_X,
   _SEP_Y_2_,
   Geometry.SECTION_WIDTH
)

local _CLOCK_SPEED_Y_ = _SEP_Y_2_ + _SEPARATOR_SPACING_

local clock_speed = Common.initTextRows(
   Geometry.LEFT_X,
   _CLOCK_SPEED_Y_,
   Geometry.SECTION_WIDTH,
   _TEXT_SPACING_,
   {'GPU Clock Speed', 'Memory Clock Speed'}
)

local _SEP_Y_3_ = _CLOCK_SPEED_Y_ + _TEXT_SPACING_ * 2

local separator3 = Common.initSeparator(
   Geometry.LEFT_X,
   _SEP_Y_3_,
   Geometry.SECTION_WIDTH
)

local _GPU_UTIL_Y_ = _SEP_Y_3_ + _SEPARATOR_SPACING_

local gpu_util = Common.initPercentPlot_formatted(
   Geometry.LEFT_X,
   _GPU_UTIL_Y_,
   Geometry.SECTION_WIDTH,
   _PLOT_HEIGHT_,
   _PLOT_SEC_BREAK_,
   'GPU Utilization',
   na_percent_format
)

local _MEM_UTIL_Y_ = _GPU_UTIL_Y_ + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local mem_util = Common.initPercentPlot_formatted(
   Geometry.LEFT_X,
   _MEM_UTIL_Y_,
   Geometry.SECTION_WIDTH,
   _PLOT_HEIGHT_,
   _PLOT_SEC_BREAK_,
   'Memory Utilization',
   na_percent_format
)

local _VID_UTIL_Y_ = _MEM_UTIL_Y_ + _PLOT_HEIGHT_ + _PLOT_SEC_BREAK_ * 2

local vid_util = Common.initPercentPlot_formatted(
   Geometry.LEFT_X,
   _VID_UTIL_Y_,
   Geometry.SECTION_WIDTH,
   _PLOT_HEIGHT_,
   _PLOT_SEC_BREAK_,
   'Video Utilization',
   na_percent_format
)

--[[
vars to process the nv settings glob

glob will be of the form:
	<used_mem>
	<total_mem>
	<temp>
	<gpu_freq>,<mem_freq>
	graphics=<gpu_util>, memory=<mem_util>, video=<vid_util>, PCIe=<pci_util>
--]]
local NV_QUERY = 'nvidia-settings -t'..
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

local nvidia_off = function(cr)
   Common.text_row_crit_set(internal_temp, cr, -1)
   Common.text_rows_set(clock_speed, cr, 1, NA)
   Common.text_rows_set(clock_speed, cr, 2, NA)

   Common.percent_plot_set(gpu_util, cr, nil)
   Common.percent_plot_set(vid_util, cr, nil)
   Common.percent_plot_set(mem_util, cr, nil)
end

local gpu_bus_ctrl = '/sys/bus/pci/devices/0000:01:00.0/power/control'

local update = function(cr)
   if Util.read_file(gpu_bus_ctrl, nil, '*l') == 'on' then
      local nvidia_settings_glob = Util.execute_cmd(NV_QUERY)
      if nvidia_settings_glob == '' then
         Text.set(status.value, cr, 'Error')
         nvidia_off(cr)
      else
         Common.text_row_set(status, cr, 'On')

         local used_memory, total_memory, temp_reading, gpu_frequency,
            memory_frequency, gpu_utilization, vid_utilization
            = __string_match(nvidia_settings_glob, NV_REGEX)

         Common.text_row_crit_set(internal_temp, cr, temp_reading)
         Common.text_rows_set(clock_speed, cr, 1, gpu_frequency..' Mhz')
         Common.text_rows_set(clock_speed, cr, 2, memory_frequency..' Mhz')

         Common.percent_plot_set(gpu_util, cr, gpu_utilization)
         Common.percent_plot_set(mem_util, cr, used_memory / total_memory * 100)
         Common.percent_plot_set(vid_util, cr, vid_utilization)
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
_SEP_Y_1_ = nil
_SEP_Y_2_ = nil
_SEP_Y_3_ = nil
_INTERNAL_TEMP_Y_ = nil
_CLOCK_SPEED_Y_ = nil
_GPU_UTIL_Y_ = nil
_MEM_UTIL_Y_ = nil
_VID_UTIL_Y_ = nil

local draw_static = function(cr)
   Common.drawHeader(cr, header)

   Common.text_row_draw_static(status, cr)
   Line.draw(separator1, cr)

   Common.text_row_crit_draw_static(internal_temp, cr)
   Line.draw(separator2, cr)

   Common.text_rows_draw_static(clock_speed, cr)
   Line.draw(separator3, cr)

   Common.percent_plot_draw_static(gpu_util, cr)
   Common.percent_plot_draw_static(mem_util, cr)
   Common.percent_plot_draw_static(vid_util, cr)
end

local draw_dynamic = function(cr)
   update(cr)

   Common.text_row_draw_dynamic(status, cr)
   Common.text_row_crit_draw_dynamic(internal_temp, cr)
   Common.text_rows_draw_dynamic(clock_speed, cr)
   Common.percent_plot_draw_dynamic(gpu_util, cr)
   Common.percent_plot_draw_dynamic(mem_util, cr)
   Common.percent_plot_draw_dynamic(vid_util, cr)
end

return function()
   return {static = draw_static, dynamic = draw_dynamic}
end
