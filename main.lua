--
-- initialialize global geometric data
--
local UPDATE_FREQUENCY = 1 --Hz

_G_INIT_DATA_ = {
	UPDATE_INTERVAL = 1 / UPDATE_FREQUENCY,
}

--
-- init cairo
--
require 'cairo'
local __cairo_xlib_surface_create 	= cairo_xlib_surface_create
local __cairo_set_source_surface    = cairo_set_source_surface
local __cairo_image_surface_create  = cairo_image_surface_create
local __cairo_paint                 = cairo_paint
local __cairo_create 				= cairo_create
local __cairo_surface_destroy 		= cairo_surface_destroy
local __cairo_destroy 				= cairo_destroy
local __cairo_translate 			= cairo_translate

local ABS_PATH = debug.getinfo(1).source:match("@?(.*/)")
package.path = ABS_PATH..'?.lua;'..
   ABS_PATH..'drawing/?.lua;'..
   ABS_PATH..'schema/?.lua;'..
   ABS_PATH..'core/func/?.lua;'..
   ABS_PATH..'core/super/?.lua;'..
   ABS_PATH..'core/widget/?.lua;'..
   ABS_PATH..'core/widget/arc/?.lua;'..
   ABS_PATH..'core/widget/text/?.lua;'..
   ABS_PATH..'core/widget/plot/?.lua;'..
   ABS_PATH..'core/widget/rect/?.lua;'..
   ABS_PATH..'core/widget/poly/?.lua;'..
   ABS_PATH..'core/widget/image/?.lua;'

local Util 			= require 'Util'
local FillRect      = require 'FillRect'
local System 		= require 'System'
local Network 		= require 'Network'
local Processor 	= require 'Processor'
local FileSystem 	= require 'FileSystem'
local Pacman 		= require 'Pacman'
local Power 		= require 'Power'
local ReadWrite		= require 'ReadWrite'
local Graphics		= require 'Graphics'
local Memory		= require 'Memory'
local Common		= require 'Common'
local Geometry		= require 'Geometry'

--
-- initialize static surfaces
--

local _make_static_surface = function(x, y, w, h, modules)
   local panel_line_thickness = 1
   -- move over by half a pixel so the lines don't need to be antialiased
   local _x = x + 0.5
   local _y = y + 0.5
   local panel = Common.initPanel(_x, _y, w, h, panel_line_thickness)
   local cs_x = _x - panel_line_thickness * 0.5
   local cs_y = _y - panel_line_thickness * 0.5
   local cs_w = w + panel_line_thickness
   local cs_h = h + panel_line_thickness

   local cs = __cairo_image_surface_create(CAIRO_FORMAT_ARGB32, cs_w, cs_h)
   local cr = __cairo_create(cs)

   __cairo_translate(cr, -cs_x, -cs_y)

   FillRect.draw(panel, cr)
   for _, f in pairs(modules) do
      f(cr)
   end
   __cairo_destroy(cr)
   return { x = cs_x, y = cs_y, s = cs }
end

local draw_static_surface = function(cr, cs_obj)
   __cairo_set_source_surface(cr, cs_obj.s, cs_obj.x, cs_obj.y)
   __cairo_paint(cr)
end

local cs_left = _make_static_surface(
	Geometry.LEFT_X - Geometry.PANEL_MARGIN_X,
	Geometry.TOP_Y - Geometry.PANEL_MARGIN_Y,
	Geometry.SECTION_WIDTH + Geometry.PANEL_MARGIN_X * 2,
	Geometry.SIDE_HEIGHT + Geometry.PANEL_MARGIN_Y * 2,
    {System.draw_static, Graphics.draw_static, Processor.draw_static}
)

local cs_center = _make_static_surface(
   Geometry.CENTER_LEFT_X - Geometry.PANEL_MARGIN_X,
   Geometry.TOP_Y - Geometry.PANEL_MARGIN_Y,
   Geometry.CENTER_WIDTH + Geometry.PANEL_MARGIN_Y * 2 + Geometry.CENTER_PAD,
   Geometry.CENTER_HEIGHT + Geometry.PANEL_MARGIN_Y * 2,
   {ReadWrite.draw_static, Network.draw_static}
)

local cs_right = _make_static_surface(
   Geometry.RIGHT_X - Geometry.PANEL_MARGIN_X,
   Geometry.TOP_Y - Geometry.PANEL_MARGIN_Y,
   Geometry.SECTION_WIDTH + Geometry.PANEL_MARGIN_X * 2,
   Geometry.SIDE_HEIGHT + Geometry.PANEL_MARGIN_Y * 2,
   {Pacman.draw_static, FileSystem.draw_static, Power.draw_static, Memory.draw_static}
)

--
-- kill all the stuff we don't need for the main loop
--
local _unrequire = function(m) package.loaded[m] = nil end

_unrequire('Super')
_unrequire('Color')
_unrequire('Widget')
_unrequire('Patterns')

_unrequire = nil
_make_static_surface = nil
FillRect = nil
_G_INIT_DATA_ = nil
collectgarbage()

--
-- main loop
--
local using_ac = function()
   -- for some reason it is much more efficient to test if the battery
   -- is off than if the ac is on
   return Util.read_file('/sys/class/power_supply/BAT0/status', nil, '*l') ~= 'Discharging'
end

local updates = -2 -- this accounts for the first few spazzy iterations
local STATS_FILE = '/tmp/.conky_pacman'

function conky_start(update_interval)
   conky_set_update_interval(update_interval)
end

function conky_main()
   local _cw = conky_window
   if not _cw then return end

   local cs = __cairo_xlib_surface_create(_cw.display, _cw.drawable,
                                          _cw.visual, 1920, 1080)
   local cr = __cairo_create(cs)

   draw_static_surface(cr, cs_left)
   draw_static_surface(cr, cs_center)
   draw_static_surface(cr, cs_right)

   updates = updates + 1

   local t1 = updates % (UPDATE_FREQUENCY * 10)

   local is_using_ac = using_ac()
   local pacman_stats = Util.read_file(STATS_FILE)

   System.draw_dynamic(cr, pacman_stats)
   Graphics.draw_dynamic(cr)
   Processor.draw_dynamic(cr, t1)

   ReadWrite.draw_dynamic(cr, UPDATE_FREQUENCY)
   Network.draw_dynamic(cr, UPDATE_FREQUENCY)

   Pacman.draw_dynamic(cr, pacman_stats)
   FileSystem.draw_dynamic(cr, t1)
   Power.draw_dynamic(cr, UPDATE_FREQUENCY, is_using_ac)
   Memory.draw_dynamic(cr)

   __cairo_surface_destroy(cs)
   __cairo_destroy(cr)
end
