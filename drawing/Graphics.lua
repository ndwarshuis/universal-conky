local Text			= require 'Text'
local Line			= require 'Line'
local Util			= require 'Util'
local Common		= require 'Common'
local Geometry		= require 'Geometry'

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

   local header = Common.Header(
      Geometry.LEFT_X,
      MODULE_Y,
      Geometry.SECTION_WIDTH,
      'NVIDIA GRAPHICS'
   )

   -----------------------------------------------------------------------------
   -- gpu status

   local status = Common.initTextRow(
      Geometry.LEFT_X,
      header.bottom_y,
      Geometry.SECTION_WIDTH,
      'Status'
   )

   local SEP_Y1 = header.bottom_y + SEPARATOR_SPACING

   local separator1 = Common.initSeparator(
      Geometry.LEFT_X,
      SEP_Y1,
      Geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- gpu temperature

   local INTERNAL_TEMP_Y = SEP_Y1 + SEPARATOR_SPACING

   local internal_temp = Common.initTextRowCrit(
      Geometry.LEFT_X,
      INTERNAL_TEMP_Y,
      Geometry.SECTION_WIDTH,
      'Internal Temperature',
      function(s)
         if s == -1 then return NA else return string.format('%s°C', s) end
      end,
      80
   )

   local SEP_Y2 = INTERNAL_TEMP_Y + SEPARATOR_SPACING

   local separator2 = Common.initSeparator(
      Geometry.LEFT_X,
      SEP_Y2,
      Geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- gpu clock speeds

   local CLOCK_SPEED_Y = SEP_Y2 + SEPARATOR_SPACING

   local clock_speed = Common.initTextRows(
      Geometry.LEFT_X,
      CLOCK_SPEED_Y,
      Geometry.SECTION_WIDTH,
      TEXT_SPACING,
      {'GPU Clock Speed', 'Memory Clock Speed'}
   )

   local SEP_Y3 = CLOCK_SPEED_Y + TEXT_SPACING * 2

   local separator3 = Common.initSeparator(
      Geometry.LEFT_X,
      SEP_Y3,
      Geometry.SECTION_WIDTH
   )

   -----------------------------------------------------------------------------
   -- gpu utilization plot

   local na_percent_format = function(x)
      if x == -1 then return NA else return __string_format('%s%%', x) end
   end

   local build_plot = function(y, label)
      return Common.initPercentPlot_formatted(
         Geometry.LEFT_X,
         y,
         Geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         PLOT_SEC_BREAK,
         label,
         update_freq,
         na_percent_format
      )
   end

   local GPU_UTIL_Y = SEP_Y3 + SEPARATOR_SPACING
   local gpu_util = build_plot(GPU_UTIL_Y, 'GPU Utilization')

   -----------------------------------------------------------------------------
   -- gpu memory consumption plot

   local MEM_UTIL_Y = GPU_UTIL_Y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2
   local mem_util = build_plot(MEM_UTIL_Y, 'Memory Utilization')

   -----------------------------------------------------------------------------
   -- gpu video utilization plot

   local VID_UTIL_Y = MEM_UTIL_Y + PLOT_HEIGHT + PLOT_SEC_BREAK * 2
   local vid_util = build_plot(VID_UTIL_Y, 'Video Utilization')

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

   local GPU_BUS_CTRL = '/sys/bus/pci/devices/0000:01:00.0/power/control'

   local nvidia_off = function(cr)
      Common.text_row_crit_set(internal_temp, cr, -1)
      Common.text_rows_set(clock_speed, cr, 1, NA)
      Common.text_rows_set(clock_speed, cr, 2, NA)
      Common.percent_plot_set(gpu_util, cr, nil)
      Common.percent_plot_set(vid_util, cr, nil)
      Common.percent_plot_set(mem_util, cr, nil)
   end

   local update = function(cr)
      if Util.read_file(GPU_BUS_CTRL, nil, '*l') == 'on' then
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

   -----------------------------------------------------------------------------
   -- main drawing functions

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

   return {static = draw_static, dynamic = draw_dynamic}
end
