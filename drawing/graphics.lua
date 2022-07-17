local pure			= require 'pure'
local i_o			= require 'i_o'
local common		= require 'common'
local geometry		= require 'geometry'

return function(update_freq, config, point)
   local SEPARATOR_SPACING = 20
   local TEXT_SPACING = 20
   local PLOT_SEC_BREAK = 20
   local PLOT_HEIGHT = 56
   local NA = 'N/A'
   local __string_match	= string.match
   local __tonumber = tonumber

   -----------------------------------------------------------------------------
   -- helper functions

   local _from_state = function(def, f, set)
      return function(s)
         if s.error == false then
            set(f(s))
         else
            set(def)
         end
      end
   end

   local _mk_plot = function(label, getter, y)
      local obj = common.make_tagged_maybe_percent_timeseries(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT,
         PLOT_SEC_BREAK,
         label,
         update_freq
      )
      local update = _from_state(
         false,
         getter,
         pure.partial(common.tagged_maybe_percent_timeseries_set, obj)
      )
      local static = pure.partial(common.tagged_percent_timeseries_draw_static, obj)
      local dynamic = pure.partial(common.tagged_percent_timeseries_draw_dynamic, obj)
      return common.mk_acc(
         geometry.SECTION_WIDTH,
         PLOT_HEIGHT + PLOT_SEC_BREAK,
         update,
         static,
         dynamic
      )
   end

   -----------------------------------------------------------------------------
   -- gpu status

   local mk_status = function(y)
      local obj = common.make_text_row(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         'Status'
      )
      local update = function(s)
         if s.error == false then
            common.text_row_set(obj, 'On')
         else
            common.text_row_set(obj, s.error)
         end
      end
      local static = pure.partial(common.text_row_draw_static, obj)
      local dynamic = pure.partial(common.text_row_draw_dynamic, obj)
      return common.mk_acc(geometry.SECTION_WIDTH, 0, update, static, dynamic)
   end

   local mk_sep = pure.partial(
      common.mk_seperator,
      geometry.SECTION_WIDTH,
      point.x
   )

   -----------------------------------------------------------------------------
   -- gpu temperature

   local mk_temp = function(y)
      local obj = common.make_threshold_text_row(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         'Internal Temperature',
         function(s)
            if s == -1 then return NA else return string.format('%s°C', s) end
         end,
         80
      )
      local update = _from_state(
         -1,
         function(s) return __tonumber(s.temp_reading) end,
         pure.partial(common.threshold_text_row_set, obj)
      )
      local static = pure.partial(common.threshold_text_row_draw_static, obj)
      local dynamic = pure.partial(common.threshold_text_row_draw_dynamic, obj)
      return common.mk_acc(geometry.SECTION_WIDTH, 0, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- gpu clock speeds

   local mk_clock = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         geometry.SECTION_WIDTH,
         TEXT_SPACING,
         {'GPU Clock Speed', 'memory Clock Speed'}
      )
      local update = function(s)
         if s.error == false then
            common.text_rows_set(obj, 1, s.gpu_frequency..' Mhz')
            common.text_rows_set(obj, 2, s.memory_frequency..' Mhz')
         else
            common.text_rows_set(obj, 1, NA)
            common.text_rows_set(obj, 2, NA)
         end
      end
      local static = pure.partial(common.text_rows_draw_static, obj)
      local dynamic = pure.partial(common.text_rows_draw_dynamic, obj)
      return common.mk_acc(geometry.SECTION_WIDTH, TEXT_SPACING, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- gpu utilization plot

   local mk_gpu_util = pure.partial(
      _mk_plot,
      'GPU utilization',
      function(s) return s.gpu_utilization end
   )

   -----------------------------------------------------------------------------
   -- gpu memory consumption plot

   local mk_mem_util = pure.partial(
      _mk_plot,
      'Memory utilization',
      function(s) return s.used_memory / s.total_memory * 100 end
   )

   -----------------------------------------------------------------------------
   -- gpu video utilization plot

   local mk_vid_util = pure.partial(
      _mk_plot,
      'Video utilization',
      function(s) return s.vid_utilization end
   )

   -----------------------------------------------------------------------------
   -- nvidia state

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

   local state = {
      error = false,
      used_memory = 0,
      total_memory = 0,
      temp_reading = 0,
      gpu_frequency = 0,
      memory_frequency = 0,
      gpu_utilization = 0,
      vid_utilization = 0
   }

   local update_state = function()
      if i_o.read_file(GPU_BUS_CTRL, nil, '*l') == 'on' then
         local nvidia_settings_glob = i_o.execute_cmd(NV_QUERY)
         if nvidia_settings_glob == '' then
            state.error = 'Error'
         else
            state.used_memory,
               state.total_memory,
               state.temp_reading,
               state.gpu_frequency,
               state.memory_frequency,
               state.gpu_utilization,
               state.vid_utilization
               = __string_match(nvidia_settings_glob, NV_REGEX)
            state.error = false
         end
      else
         state.error = 'Off'
      end
      return state
   end

   -----------------------------------------------------------------------------
   -- main drawing functions

   local rbs = common.reduce_blocks_(
      'NVIDIA GRAPHICS',
      point,
      geometry.SECTION_WIDTH,
      {{mk_status, true, SEPARATOR_SPACING}},
      common.mk_section(
         SEPARATOR_SPACING,
         mk_sep,
         {mk_temp, config.show_temp, SEPARATOR_SPACING}
      ),
      common.mk_section(
         SEPARATOR_SPACING,
         mk_sep,
         {mk_clock, config.show_clock, SEPARATOR_SPACING}
      ),
      common.mk_section(
         SEPARATOR_SPACING,
         mk_sep,
         {mk_gpu_util, config.show_gpu_util, PLOT_SEC_BREAK},
         {mk_mem_util, config.show_mem_util, PLOT_SEC_BREAK},
         {mk_vid_util, config.show_vid_util, 0}
      )
   )
   return pure.map_at("update", function(f) return function(_) f(update_state()) end end, rbs)
end
