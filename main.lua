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
   local devices = {'sda', 'nvme0n1'}
   local battery = 'BAT0'
   local fs_paths = {
      {'/', 'root'},
      {'/boot', 'boot'},
      {'/home', 'home'},
      {'/mnt/data', 'data'},
      {'/mnt/dcache', 'dcache'},
      {'/tmp', 'tmpfs'}
   }

   local mem = memory(update_freq)
   local rw = readwrite(update_freq, devices)
   local net = network(update_freq)
   local pwr = power(update_freq, battery)
   local fs = filesystem(fs_paths)
   local stm = system()
   local gfx = graphics(update_freq)
   local proc = processor(update_freq)
   local pcm = pacman()

   local using_ac = sys.battery_status_reader(battery)

   local draw_static = static(
      {
         {stm.static, gfx.static, proc.static},
         {rw.static, net.static},
         {pcm.static, fs.static, pwr.static, mem.static}
      }
   )

   local STATS_FILE = '/tmp/.conky_pacman'

   draw_dynamic = function(cr, _updates)
      -- draw static components
      draw_static(cr)

      -- update dynamic components
      local t1 = _updates % (update_freq * 10)
      local pacman_stats = i_o.read_file(STATS_FILE)
      local is_using_ac = using_ac()

      stm.update(pacman_stats)
      gfx.update()
      proc.update(t1)
      rw.update()
      net.update()
      pcm.update(pacman_stats)
      fs.update(t1)
      pwr.update(is_using_ac)
      mem.update()

      -- draw dynamic components
      stm.dynamic(cr)
      gfx.dynamic(cr)
      proc.dynamic(cr)
      rw.dynamic(cr)
      net.dynamic(cr)
      pcm.dynamic(cr)
      fs.dynamic(cr)
      pwr.dynamic(cr)
      mem.dynamic(cr)
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
