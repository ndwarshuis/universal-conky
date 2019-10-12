--[[
Boolean conventions:
  0 is true, 1 is false

Module format:
  LIBRARY STRUCTURE (a collection of functions/values in a table):
    local M = {}  -- define module-level table to return

    local modname = requires 'modname'
    -- import all required modules

    local foo = function()
      -- code
    end

    -- define more functions

    M.foo = foo -- dump all functions into table

    return M  -- return entire table (use functions as modname.foo)

Var names:
  - delimiters: all words separated by _ (unless camalCase)
  - booleans: preceed by is_ (as in is_awesome)
  - Spacial scope:
    - Everything declared local by default
    - reassigning to local:
      - upval to local: prefix with _
      - global to local: prefix with __
      - replace . with _ if callng from table
      - the only reason to do either of these is for performance, therefore
        no need to localize variables that are only used during init
    - global: preceed with g_
  - Temporal Scope
    - init: only relevent to startup (nil'ed before first rendering loop)
    - persistant: always relevent (potentially)
    - flank init vars with _
  - Mutability
    - variable: lowercase
    - constant: ALL_CAPS
    - constants can be anything except functions
  - Module Names:
    - CapCamalCase
    - var name is exactly the same as module name
--]]

--
-- initialialize global geometric data
--
local UPDATE_FREQUENCY = 1 --Hz

_G_INIT_DATA_ = {
	UPDATE_INTERVAL 	= 1 / UPDATE_FREQUENCY,

	LEFT_X 				= 32,
	SECTION_WIDTH		= 436,
	CENTER_PAD 			= 20,
	PANEL_HORZ_SPACING 	= 10,
	PANEL_MARGIN_X		= 20,
	PANEL_MARGIN_Y		= 10,

	TOP_Y				= 21,
	SIDE_HEIGHT 		= 1020,
	CENTER_HEIGHT 		= 220,

	-- silly hack, the price of a litewait language
	ABS_PATH			= debug.getinfo(1).source:match("@?(.*/)")
}

_G_INIT_DATA_.CENTER_LEFT_X = _G_INIT_DATA_.LEFT_X +
   _G_INIT_DATA_.SECTION_WIDTH + _G_INIT_DATA_.PANEL_MARGIN_X * 2 +
   _G_INIT_DATA_.PANEL_HORZ_SPACING

_G_INIT_DATA_.CENTER_RIGHT_X = _G_INIT_DATA_.CENTER_LEFT_X +
   _G_INIT_DATA_.SECTION_WIDTH + _G_INIT_DATA_.CENTER_PAD

_G_INIT_DATA_.CENTER_WIDTH = _G_INIT_DATA_.SECTION_WIDTH * 2 +
   _G_INIT_DATA_.CENTER_PAD

_G_INIT_DATA_.RIGHT_X = _G_INIT_DATA_.CENTER_LEFT_X +
   _G_INIT_DATA_.CENTER_WIDTH + _G_INIT_DATA_.PANEL_MARGIN_X * 2 +
   _G_INIT_DATA_.PANEL_HORZ_SPACING

conky_set_update_interval(_G_INIT_DATA_.UPDATE_INTERVAL)

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

--
-- import all packages and init with global geometric data
--
package.path = _G_INIT_DATA_.ABS_PATH..'?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'drawing/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'schema/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/func/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/super/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/arc/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/text/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/plot/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/rect/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/poly/?.lua;'..
  _G_INIT_DATA_.ABS_PATH..'core/widget/image/?.lua;'

_G_Widget_ 		= require 'Widget'
_G_Patterns_ 	= require 'Patterns'

local Util 			= require 'Util'
local Panel 		= require 'Panel'
local System 		= require 'System'
local Network 		= require 'Network'
local Processor 	= require 'Processor'
local FileSystem 	= require 'FileSystem'
local Pacman 		= require 'Pacman'
local Power 		= require 'Power'
local ReadWrite		= require 'ReadWrite'
local Graphics		= require 'Graphics'
local Memory		= require 'Memory'

local _unrequire = function(m) package.loaded[m] = nil end

_G_Widget_ = nil
_G_Patterns_ = nil

_unrequire('Super')
_unrequire('Color')
_unrequire('Gradient')
_unrequire('Widget')
_unrequire('Patterns')

_unrequire = nil

_G_INIT_DATA_ = nil

--
-- initialize static surface
--
local cs_static = __cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1920, 1080)
local cr_static = __cairo_create(cs_static)

Panel.draw_static(cr_static)

System.draw_static(cr_static)
Graphics.draw_static(cr_static)
Processor.draw_static(cr_static)

ReadWrite.draw_static(cr_static)
Network.draw_static(cr_static)

Pacman.draw_static(cr_static)
FileSystem.draw_static(cr_static)
Power.draw_static(cr_static)
Memory.draw_static(cr_static)

__cairo_destroy(cr_static)

cr_static = nil

--
-- create some useful functions
--
local using_ac = function()
   return Util.read_file('/sys/class/power_supply/AC/online', nil, '*n') == 1
end

--
-- main loop
--
local updates = -2 -- this accounts for the first few spazzy iterations
local __collectgarbage = collectgarbage

local STATS_FILE = '/tmp/.conky_pacman'

function conky_main()
   local _cw = conky_window
   if not _cw then return end

   -- local time = os.clock()

   local cs = __cairo_xlib_surface_create(_cw.display, _cw.drawable,
										  _cw.visual, 1920, 1080)
   local cr = __cairo_create(cs)

   __cairo_set_source_surface(cr, cs_static, 0, 0)
   __cairo_paint(cr)

   updates = updates + 1

   local t1 = updates % (UPDATE_FREQUENCY * 10)

   local is_using_ac = using_ac()
   local pacman_stats = Util.read_file(STATS_FILE)

   System.draw_dynamic(cr, pacman_stats)
   Graphics.draw_dynamic(cr)
   Processor.draw_dynamic(cr)

   ReadWrite.draw_dynamic(cr, UPDATE_FREQUENCY)
   Network.draw_dynamic(cr, UPDATE_FREQUENCY)

   Pacman.draw_dynamic(cr, pacman_stats)
   FileSystem.draw_dynamic(cr, t1)
   Power.draw_dynamic(cr, UPDATE_FREQUENCY, is_using_ac)
   Memory.draw_dynamic(cr)

   __cairo_surface_destroy(cs)
   __cairo_destroy(cr)
   __collectgarbage()

   -- print(os.clock() - time)
end
