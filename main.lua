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

  RENDERING MODULE STRUCTURE (only used in this module; main.lua):
    local modname = requires 'modname'
    -- import all required modules

    local foo = function()
      -- code
    end

    local draw = function(args)
       -- drawing code that uses foo()
    end

    return draw -- only draw is returned (use as modname(args))

Var names:
  - delimiters: all words separated by _ (unless camalCase)
  - booleans: preceed by is_ (as in is_awesome)
  - Spacial scope:
    - Everything declared local by default
    - reassigning to local:
      - upval to local: preceed with _
      - global to local: preceed with __
      - replace . with _ if callng from table
    - global: preceed with g_
  - Temporal Scope
    - init: only relevent to startup (nil'ed before first rendering loop)
    - persistant: always relevent (potentially)
    - init vars end with _
  - Mutability
    - variable: lowercase
    - constant: ALL_CAPS
    - constants can be anything except functions
  - Module Names:
    - CapCamalCase
    - var name is exactly the same as module name
--]]

local UPDATE_FREQUENCY = 1						--Hz

G_DIMENSIONS_ = {
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

	ABS_PATH			= os.getenv('CONKY_LUA_HOME')
}

G_DIMENSIONS_.CENTER_LEFT_X = G_DIMENSIONS_.LEFT_X + G_DIMENSIONS_.SECTION_WIDTH + G_DIMENSIONS_.PANEL_MARGIN_X * 2 + G_DIMENSIONS_.PANEL_HORZ_SPACING
G_DIMENSIONS_.CENTER_RIGHT_X = G_DIMENSIONS_.CENTER_LEFT_X + G_DIMENSIONS_.SECTION_WIDTH + G_DIMENSIONS_.CENTER_PAD
G_DIMENSIONS_.CENTER_WIDTH = G_DIMENSIONS_.SECTION_WIDTH * 2 + G_DIMENSIONS_.CENTER_PAD
G_DIMENSIONS_.RIGHT_X = G_DIMENSIONS_.CENTER_LEFT_X + G_DIMENSIONS_.CENTER_WIDTH + G_DIMENSIONS_.PANEL_MARGIN_X * 2 + G_DIMENSIONS_.PANEL_HORZ_SPACING

package.path = G_DIMENSIONS_.ABS_PATH..'/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/interface/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/module/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/schema/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/func/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/super/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/arc/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/text/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/plot/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/rect/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/poly/?.lua;'..
  G_DIMENSIONS_.ABS_PATH..'/core/widget/image/?.lua;'

conky_set_update_interval(G_DIMENSIONS_.UPDATE_INTERVAL)

require 'imlib2'
require 'cairo'

local util 			= require 'util'
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
local Weather		= require 'Weather'

local updates = -2

local _unrequire = function(m)
	package.loaded[m] = nil
	_G[m] = nil
end

_unrequire('Super')
_unrequire('Color')
_unrequire('Gradient')

_unrequire = nil

G_DIMENSIONS_ = nil

local __cairo_xlib_surface_create 	= cairo_xlib_surface_create
local __cairo_create 				= cairo_create
local __cairo_surface_destroy 		= cairo_surface_destroy
local __cairo_destroy 				= cairo_destroy
local __collectgarbage				= collectgarbage
local __os_execute					= os.execute

local using_ac = function()
	if util.conky('${acpiacadapter AC}') == 'on-line' then return 0 end
end

local current_last_log_entry = util.execute_cmd('tail -1 /var/log/pacman.log')

local check_if_log_changed = function()
	local new_last_log_entry = util.execute_cmd('tail -1 /var/log/pacman.log')
	if new_last_log_entry == current_last_log_entry then return 1 end
	current_last_log_entry = new_last_log_entry
	return 0
end

__os_execute('set_conky_interface.sh 0')
local current_interface = 0

local check_interface = function()
	local next_interface = util.read_file('/tmp/conky_interface', nil, '*n')

	if next_interface ~= '' then
		if next_interface == current_interface then return 1 end
		current_interface = next_interface
		return 0
	else
		__os_execute('set_conky_interface.sh 0')
		current_interface = 0
		return 0
	end
end

function conky_main()
	local cw = conky_window
    if not cw then return end
    local cs = __cairo_xlib_surface_create(cw.display, cw.drawable, cw.visual, 1920, 1080)
    local cr = __cairo_create(cs)

	updates = updates + 1

	local t1 = updates % (UPDATE_FREQUENCY * 10)
	
	local t2
	local is_using_ac = using_ac()
	if is_using_ac then
		t2 = updates % (UPDATE_FREQUENCY * 60)
	else
		t2 = updates % (UPDATE_FREQUENCY * 300)
	end

	local log_changed = 1
	if t2 == 0 then log_changed = check_if_log_changed() end
	local interface_changed = check_interface()

	Panel(cr)

	--interface 0
	System(cr, current_interface, log_changed)
	Graphics(cr, current_interface)
	Processor(cr, current_interface)

	ReadWrite(cr, current_interface, UPDATE_FREQUENCY)
	Network(cr, current_interface, UPDATE_FREQUENCY)
	
	Pacman(cr, current_interface, log_changed)
	FileSystem(cr, current_interface, t1)
	Power(cr, current_interface, UPDATE_FREQUENCY, is_using_ac)
	Memory(cr, current_interface)

	--interface 1
	Weather(cr, current_interface, interface_changed)

    __cairo_surface_destroy(cs)
    __cairo_destroy(cr)
    __collectgarbage()
end
