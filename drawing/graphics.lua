local text			= require 'text'
local line			= require 'line'
local util			= require 'util'
local common		= require 'common'
local geometry		= require 'geometry'

return function(update_freq)
   local MODULE_Y = 145
   local SEPARATOR_SPACING = 20
   local TEXT_SPACING = 20
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local NA = 'N/A'
   local __string_match	= string.match
   local __string_format = string.format


   -----------------------------------------------------------------------------
   -- header

   local header = common.make_header(
      geometry.LEFT_X,
      MODULE_Y,
      geometry.SECTION_WIDTH,
      'NVIDIA GRAPHICS'
   )

   -----------------------------------------------------------------------------
   -- gpu status

   local status = common.make_text_row(
      geometry.LEFT_X,
      header.bottom_y,
      geometry.SECTION_WIDTH,
      'Status'
   )

   local SEP_Y1 = header.bottom_y + SEPARATOR_SPACING

   local separator1 = common.make_separator(
      geometry.LEFT_X,
      SEP_Y1,
      geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- gpu temperature

   local INTERNAL_TEMP_Y = SEP_Y1 + SEPARATOR_SPACING

   local internal_temp = common.make_threshold_text_row(
      geometry.LEFT_X,
      INTERNAL_TEMP_Y,
      geometry.SECTION_WIDTH,
      'Internal Temperature',
      function(s)
         if s == -1 then return NA else return string.format('%s°C', s) end
      end,
      80
   )

   local SEP_Y2 = INTERNAL_TEMP_Y + SEPARATOR_SPACING

   local separator2 = common.make_separator(
      geometry.LEFT_X,
      SEP_Y2,
      geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- gpu clock speeds

   local CLOCK_SPEED_Y = SEP_Y2 + SEPARATOR_SPACING

   local clock_speed = common.make_text_rows(
      geometry.LEFT_X,
      CLOCK_SPEED_Y,
      geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'GPU Clock Speed', 'memory Clock Speed'}
   )

   local SEP_Y3 = CLOCK_SPEED_Y + TEXT_SPACING * 2

   local separator3 = common.make_separator(
      geometry.LEFT_X,
      SEP_Y3,
      geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- gpu utilization plot

   local na_percent_format = function(x)
      if x == -1 then return NA else return __string_format('%s%%', x) end
   end

   local make_plot = function(y, label)
      return common.make_percent_timeseries_formatted(
         geometry.LEFT_X,
         y,
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         PLOT_SEC_BREAK,
         label,
         update_freq,
         na_percent_format
      )
   end

   local GPU_UTIL_Y = SEP_Y3 + SEPARATOR_SPACING
   local gpu_util = make_plot(GPU_UTIL_Y, 'GPU utilization')

   -----------------------------------------------------------------------------
   -- gpu memory consumption plot

   local MEM_UTIL_Y = GPU_UTIL_Y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2
   local mem_util = make_plot(MEM_UTIL_Y, 'memory utilization')

   -----------------------------------------------------------------------------
   -- gpu video utilization plot

   local VID_UTIL_Y = MEM_UTIL_Y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2
   local vid_util = make_plot(VID_UTIL_Y, 'Video utilization')

   -----------------------------------------------------------------------------
   -- update function

   -- vars to process the nv settings glob
   --
   -- glob will be of the form:
   --   <used_mem>
   --   <total_mem>
   --   <temp>
   --   <gpu_freq>,<mem_freq>
   --   graphics=<gpu_util>, memory=<mem_util>, video=<vid_util>, PCIe=<pci_util>
   local NV_QUERY = 'nvidia-settings -t'..
      ' -q UsedDedicatedGPUmemory'..
      ' -q TotalDedicatedGPUmemory'..
      ' -q ThermalSensorReading'..
      ' -q [gpu:0]/GPUCurrentClockFreqs'..
      ' -q [gpu:0]/GPUutilization'

   local NV_REGEX = '(%d+)\n'..
      '(%d+)\n'..
      '(%d+)\n'..
      '(%d+),(%d+)\n'..
      'graphics=(%d+), memory=%d+, video=(%d+), PCIe=%d+\n'

   local GPU_BUS_CTRL = '/sys/bus/pci/devices/0000:01:00.0/power/control'

   local nvidia_off = function()
      common.threshold_text_row_set(internal_temp, -1)
      common.text_rows_set(clock_speed, 1, NA)
      common.text_rows_set(clock_speed, 2, NA)
      common.percent_timeseries_set(gpu_util, nil)
      common.percent_timeseries_set(vid_util, nil)
      common.percent_timeseries_set(mem_util, nil)
   end

   local update = function()
      if util.read_file(GPU_BUS_CTRL, nil, '*l') == 'on' then
         local nvidia_settings_glob = util.execute_cmd(NV_QUERY)
         if nvidia_settings_glob == '' then
            text.set(status.value, 'Error')
            nvidia_off()
         else
            common.text_row_set(status, 'On')

            local used_memory, total_memory, temp_reading, gpu_frequency,
               memory_frequency, gpu_utilization, vid_utilization
               = __string_match(nvidia_settings_glob, NV_REGEX)

            common.threshold_text_row_set(internal_temp, temp_reading)
            common.text_rows_set(clock_speed, 1, gpu_frequency..' Mhz')
            common.text_rows_set(clock_speed, 2, memory_frequency..' Mhz')

            common.percent_timeseries_set(gpu_util, gpu_utilization)
            common.percent_timeseries_set(mem_util, used_memory / total_memory * 100)
            common.percent_timeseries_set(vid_util, vid_utilization)
         end
      else
         text.set(status.value, 'Off')
         nvidia_off()
      end
   end

   -----------------------------------------------------------------------------
   -- main drawing functions

   local draw_static = function(cr)
      common.draw_header(cr, header)

      common.text_row_draw_static(status, cr)
      line.draw(separator1, cr)

      common.threshold_text_row_draw_static(internal_temp, cr)
      line.draw(separator2, cr)

      common.text_rows_draw_static(clock_speed, cr)
      line.draw(separator3, cr)

      common.percent_timeseries_draw_static(gpu_util, cr)
      common.percent_timeseries_draw_static(mem_util, cr)
      common.percent_timeseries_draw_static(vid_util, cr)
   end

   local draw_dynamic = function(cr)
      common.text_row_draw_dynamic(status, cr)
      common.threshold_text_row_draw_dynamic(internal_temp, cr)
      common.text_rows_draw_dynamic(clock_speed, cr)
      common.percent_timeseries_draw_dynamic(gpu_util, cr)
      common.percent_timeseries_draw_dynamic(mem_util, cr)
      common.percent_timeseries_draw_dynamic(vid_util, cr)
   end

   return {static = draw_static, dynamic = draw_dynamic, update = update}
end
