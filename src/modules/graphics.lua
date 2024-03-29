local pure			= require 'pure'
local i_o			= require 'i_o'

return function(update_freq, config, common, width, point)
   local NA = 'N/A'
   local NVIDIA_EXE = 'nvidia-settings'

   local geo = config.geometry
   local sep_spacing = geo.sep_spacing
   local text_spacing = geo.text_spacing
   local plot_sec_break = geo.plot.sec_break
   local plot_height = geo.plot.height

   local __string_match	= string.match
   local __string_format = string.format
   local __tonumber = tonumber

   -----------------------------------------------------------------------------
   -- nvidia state

   i_o.assert_exe_exists(NVIDIA_EXE)

   -- vars to process the nv settings glob
   --
   -- glob will be of the form:
   --   <used_mem>
   --   <total_mem>
   --   <temp>
   --   <gpu_freq>,<mem_freq>
   --   graphics=<gpu_util>, memory=<mem_util>, video=<vid_util>, PCIe=<pci_util>
   local NV_QUERY = NVIDIA_EXE..
      ' -t'..
      ' -q UsedDedicatedGPUmemory'..
      ' -q TotalDedicatedGPUmemory'..
      ' -q ThermalSensorReading'..
      ' -q [gpu:0]/GPUCurrentClockFreqs'..
      ' -q [gpu:0]/GPUutilization'..
      ' 2>/dev/null'

   local NV_REGEX = '(%d+)\n'..
      '(%d+)\n'..
      '(%d+)\n'..
      '(%d+),(%d+)\n'..
      'graphics=(%d+), memory=%d+, video=(%d+), PCIe=%d+\n'

   local mod_state = {
      error = false,
      used_memory = 0,
      total_memory = 0,
      temp_reading = 0,
      gpu_utilization = 0,
      vid_utilization = 0
   }

   local update_state = function()
      if i_o.read_file(config.dev_power, nil, '*l') == 'on' then
         local nvidia_settings_glob = i_o.execute_cmd(NV_QUERY)
         if nvidia_settings_glob == nil then
            mod_state.error = 'Error'
         else
            mod_state.used_memory,
               mod_state.total_memory,
               mod_state.temp_reading,
               mod_state.gpu_frequency,
               mod_state.memory_frequency,
               mod_state.gpu_utilization,
               mod_state.vid_utilization
               = __string_match(nvidia_settings_glob, NV_REGEX)
            mod_state.error = false
         end
      else
         mod_state.error = 'Off'
      end
   end

   -----------------------------------------------------------------------------
   -- helper functions

   local _from_state = function(def, get, set)
      return function()
         if mod_state.error == false then
            set(get(mod_state))
         else
            set(def)
         end
      end
   end

   local _mk_plot = function(label, getter, y)
      local obj = common.make_tagged_maybe_percent_timeseries(
         point.x,
         y,
         width,
         plot_height,
         geo.plot.ticks_y,
         plot_sec_break,
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
         width,
         plot_height + plot_sec_break,
         update,
         static,
         dynamic
      )
   end

   -----------------------------------------------------------------------------
   -- gpu status

   local mk_status = function(y)
      local obj = common.make_text_row(point.x, y, width, 'Status')
      local update = function()
         common.text_row_set(obj, mod_state.error == false and 'On' or mod_state.error)
      end
      local static = pure.partial(common.text_row_draw_static, obj)
      local dynamic = pure.partial(common.text_row_draw_dynamic, obj)
      return common.mk_acc(width, 0, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- gpu temperature

   local mk_temp = function(y)
      local obj = common.make_threshold_text_row(
         point.x,
         y,
         width,
         'Internal Temperature',
         function(s)
            if s == -1 then return NA else return __string_format('%s°C', s) end
         end,
         80
      )
      local update = _from_state(
         -1,
         pure.compose(__tonumber, pure.getter("temp_reading")),
         pure.partial(common.threshold_text_row_set, obj)
      )
      local static = pure.partial(common.threshold_text_row_draw_static, obj)
      local dynamic = pure.partial(common.threshold_text_row_draw_dynamic, obj)
      return common.mk_acc(width, 0, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- gpu clock speeds

   local mk_clock = function(y)
      local obj = common.make_text_rows(
         point.x,
         y,
         width,
         text_spacing,
         {'GPU Clock Speed', 'Memory Clock Speed'}
      )
      local update = function()
         if mod_state.error == false then
            common.text_rows_set(obj, 1, mod_state.gpu_frequency..' Mhz')
            common.text_rows_set(obj, 2, mod_state.memory_frequency..' Mhz')
         else
            common.text_rows_set(obj, 1, NA)
            common.text_rows_set(obj, 2, NA)
         end
      end
      local static = pure.partial(common.text_rows_draw_static, obj)
      local dynamic = pure.partial(common.text_rows_draw_dynamic, obj)
      return common.mk_acc(width, text_spacing, update, static, dynamic)
   end

   -----------------------------------------------------------------------------
   -- gpu utilization plot

   local mk_gpu_util = pure.partial(
      _mk_plot,
      'GPU utilization',
      pure.getter("gpu_utilization")
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
      pure.getter("vid_utilization")
   )

   -----------------------------------------------------------------------------
   -- main drawing functions

   return {
      header = 'NVIDIA GRAPHICS',
      point = point,
      width = width,
      set_state = update_state,
      top = {{mk_status, true, sep_spacing}},
      common.mk_section(
         sep_spacing,
         {mk_temp, config.show_temp, sep_spacing}
      ),
      common.mk_section(
         sep_spacing,
         {mk_clock, config.show_clock, sep_spacing}
      ),
      common.mk_section(
         sep_spacing,
         {mk_gpu_util, config.show_gpu_util, plot_sec_break},
         {mk_mem_util, config.show_mem_util, plot_sec_break},
         {mk_vid_util, config.show_vid_util, 0}
      )
   }
end
