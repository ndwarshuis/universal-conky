require 'cairo'
local __cairo_xlib_surface_create 	= cairo_xlib_surface_create
local __cairo_create 				= cairo_create
local __cairo_surface_destroy 		= cairo_surface_destroy
local __cairo_destroy 				= cairo_destroy

local ABS_PATH = debug.getinfo(1).source:match("@?(.*/)")
package.path = ABS_PATH..'?.lua;'..
   ABS_PATH..'drawing/?.lua;'..
   ABS_PATH..'schema/?.lua;'..
   ABS_PATH..'core/?.lua;'..
   ABS_PATH..'core/widget/?.lua;'..
   ABS_PATH..'core/widget/arc/?.lua;'..
   ABS_PATH..'core/widget/text/?.lua;'..
   ABS_PATH..'core/widget/timeseries/?.lua;'..
   ABS_PATH..'core/widget/rect/?.lua;'..
   ABS_PATH..'core/widget/line/?.lua;'

local i_o 			= require 'i_o'
local geom 			= require 'geom'
local pure 			= require 'pure'
local sys 			= require 'sys'
local system 		= require 'system'
local network 		= require 'network'
local processor 	= require 'processor'
local filesystem 	= require 'filesystem'
local pacman 		= require 'pacman'
local power 		= require 'power'
local readwrite		= require 'readwrite'
local graphics		= require 'graphics'
local memory		= require 'memory'
local static		= require 'static'

local draw_dynamic

function conky_start(update_interval)
   conky_set_update_interval(update_interval)

   local update_freq = 1 / update_interval

   local main_state = {}

   local config = {
      filesystem = {
         show_smart = true,
         fs_paths = {
            {'/', 'root'},
            {'/boot', 'boot'},
            {'/home', 'home'},
            {'/mnt/data', 'data'},
            {'/mnt/dcache', 'dcache'},
            {'/tmp', 'tmpfs'}
         }
      },
      graphics = {
         show_temp = true,
         show_clock = true,
         show_gpu_util = true,
         show_mem_util = true,
         show_vid_util = true
      },
      memory = {
         show_stats = true,
         show_plot = true,
         show_table = true,
      },
      power = {
         battery = 'BAT0',
         rapl_specs = {
            {'PKG0', 'intel-rapl:0'},
            {'DRAM', 'intel-rapl:0:2'}
         }
      },
      processor = {
         show_cores = true,
         show_stats = true,
         show_plot = true,
         show_table = true,
      },
      readwrite = {
         devices = {'sda', 'nvme0n1'},
      },
   }

   local mem = pure.partial(memory, update_freq, config.memory)
   local rw = pure.partial(readwrite, update_freq, config.readwrite)
   local net = pure.partial(network, update_freq)
   local pwr = pure.partial(power, update_freq, config.power)
   local fs = pure.partial(filesystem, config.filesystem, main_state)
   local stm = pure.partial(system, main_state)
   local gfx = pure.partial(graphics, update_freq, config.graphics)
   local proc = pure.partial(processor, update_freq, config.processor, main_state)
   local pcm = pure.partial(pacman, main_state)

   local compiled = static(
      geom.make_point(12, 11),
      {
         {{stm, 19, gfx, 16, proc}},
         10,
         {{rw}, 20, {net}},
         10,
         {{pcm, 24, fs, 24, pwr, 19, mem}}
      }
   )

   local STATS_FILE = '/tmp/.conky_pacman'

   draw_dynamic = function(cr, _updates)
      main_state.trigger10 = _updates % (update_freq * 10)
      main_state.pacman_stats = i_o.read_file(STATS_FILE)

      compiled.static(cr)
      compiled.update()
      compiled.dynamic(cr)
   end
end

local updates = -2 -- this accounts for the first few spazzy iterations

function conky_main()
   local _cw = conky_window
   if not _cw then return end

   local cs = __cairo_xlib_surface_create(_cw.display, _cw.drawable,
                                          _cw.visual, 1920, 1080)
   local cr = __cairo_create(cs)
   updates = updates + 1

   draw_dynamic(cr, updates)

   __cairo_surface_destroy(cs)
   __cairo_destroy(cr)
end
