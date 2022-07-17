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
   ABS_PATH..'core/widget/line/?.lua;'..
   ABS_PATH..'lib/share/lua/5.4/?.lua;'

local i_o 			= require 'i_o'
local geom 			= require 'geom'
local pure 			= require 'pure'
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
local yaml          = require 'tinyyaml'

local draw_dynamic

function conky_start(update_interval)
   conky_set_update_interval(update_interval)

   local update_freq = 1 / update_interval

   local main_state = {}

   local config = yaml.parse(i_o.read_file(ABS_PATH..'config.yml'))
   local cmods = config.modules

   local mem = pure.partial(memory, update_freq, cmods.memory)
   local rw = pure.partial(readwrite, update_freq, cmods.readwrite)
   local net = pure.partial(network, update_freq)
   local pwr = pure.partial(power, update_freq, cmods.power)
   local fs = pure.partial(filesystem, cmods.filesystem, main_state)
   local stm = pure.partial(system, main_state)
   local gfx = pure.partial(graphics, update_freq, cmods.graphics)
   local proc = pure.partial(processor, update_freq, cmods.processor, main_state)
   local pcm = pure.partial(pacman, main_state)

   local compiled = static(
      geom.make_point(table.unpack(config.layout.anchor)),
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
