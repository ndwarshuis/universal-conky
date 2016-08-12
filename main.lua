--CONVENTIONS:
--0: true, 1: false

local ABS_PATH = os.getenv('CONKY_LUA_HOME')

package.path = ABS_PATH..'/?.lua;'..
  ABS_PATH..'/interface/?.lua;'..
  ABS_PATH..'/module/?.lua;'..
  ABS_PATH..'/schema/?.lua;'..
  ABS_PATH..'/core/func/?.lua;'..
  ABS_PATH..'/core/super/?.lua;'..
  ABS_PATH..'/core/widget/?.lua;'..
  ABS_PATH..'/core/widget/arc/?.lua;'..
  ABS_PATH..'/core/widget/text/?.lua;'..
  ABS_PATH..'/core/widget/plot/?.lua;'..
  ABS_PATH..'/core/widget/rect/?.lua;'..
  ABS_PATH..'/core/widget/poly/?.lua;'..
  ABS_PATH..'/core/widget/image/?.lua;'

local UPDATE_FREQUENCY = 1						--Hz

CONSTRUCTION_GLOBAL = {
	UPDATE_INTERVAL = 1 / UPDATE_FREQUENCY,
	LEFT_X 			= 30,
	CENTER_X 		= 376,
	RIGHT_X 		= 1045,
	TOP_Y			= 21,
	SIDE_WIDTH 		= 300,
	SIDE_HEIGHT 	= 709,
	CENTER_WIDTH 	= 623,
	CENTER_HEIGHT 	= 154,
	ABS_PATH		= ABS_PATH
}

ABS_PATH = nil

conky_set_update_interval(CONSTRUCTION_GLOBAL.UPDATE_INTERVAL)

require 'imlib2'
require 'cairo'

local util 			= require 'util'
local Panel 		= require 'Panel'
local System 		= require 'System'
local Network 		= require 'Network'
local Processor 	= require 'Processor'
local FileSystem 	= require 'FileSystem'
local Pacman 		= require 'Pacman'
local ReadWrite		= require 'ReadWrite'
local Memory		= require 'Memory'
--~ local USB			= require 'USB'
--~ local Remote		= require 'Remote'
local Weather		= require 'Weather'

local updates = -2

local unrequire = function(m)
	package.loaded[m] = nil
	_G[m] = nil
end

unrequire('Super')
unrequire('Color')
unrequire('Gradient')

unrequire = nil

CONSTRUCTION_GLOBAL = nil

local _CAIRO_XLIB_SURFACE_CREATE 	= cairo_xlib_surface_create
local _CAIRO_CREATE 				= cairo_create
local _CAIRO_SURFACE_DESTROY 		= cairo_surface_destroy
local _CAIRO_DESTROY 				= cairo_destroy
local _COLLECTGARBAGE				= collectgarbage
local _OS_EXECUTE					= os.execute

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

_OS_EXECUTE('set_conky_interface.sh 0')
local current_interface = 0

local check_interface = function()
	local next_interface = util.read_file('/tmp/conky_interface', nil, '*n')

	if next_interface ~= '' then
		if next_interface == current_interface then return 1 end
		current_interface = next_interface
		return 0
	else
		_OS_EXECUTE('set_conky_interface.sh 0')
		current_interface = 0
		return 0
	end
end

function conky_main()
	local cw = conky_window
    if not cw then return end
    --~ print(cw.width, cw.height)	###USE THIS TO GET WIDTH AND HEIGHT OF WINDOW
    local cs = _CAIRO_XLIB_SURFACE_CREATE(cw.display, cw.drawable, cw.visual, 1377, 778)
    local cr = _CAIRO_CREATE(cs)

	updates = updates + 1

	local t1 = updates % (UPDATE_FREQUENCY * 10)
	
	local t2
	if using_ac() then
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
	Network(cr, current_interface, UPDATE_FREQUENCY)
	Processor(cr, current_interface)
	FileSystem(cr, current_interface, t1)
	Pacman(cr, current_interface, log_changed)
	ReadWrite(cr, current_interface, UPDATE_FREQUENCY)
	Memory(cr, current_interface)

	--interface 1
	--~ USB(cr, current_interface)
	--~ Remote(cr, current_interface, t1)

	--interface 1
	Weather(cr, current_interface, interface_changed)

    _CAIRO_SURFACE_DESTROY(cs)
    _CAIRO_DESTROY(cr)
    _COLLECTGARBAGE()
end
