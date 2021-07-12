local M = {}

local Line 			= require 'Line'
local Util			= require 'Util'
local Common		= require 'Common'

local _FS_PATHS_ = {'/', '/boot', '/home', '/mnt/data', '/mnt/dcache', "/tmp"}
local _MODULE_Y_ = 170
local _SPACING_ = 20
local _BAR_PAD_ = 100
local _SEPARATOR_SPACING_ = 20

local FS_NUM = #_FS_PATHS_

local header = Common.Header(
	_G_INIT_DATA_.RIGHT_X,
	_MODULE_Y_,
	_G_INIT_DATA_.SECTION_WIDTH,
	'FILE SYSTEMS'
)

local conky_used_perc = {}

for i, v in pairs(_FS_PATHS_) do
	conky_used_perc[i] = '${fs_used_perc '..v..'}'
end

local smart = Common.initTextRow(
   _G_INIT_DATA_.RIGHT_X,
   header.bottom_y,
   _G_INIT_DATA_.SECTION_WIDTH,
   'SMART Daemon'
)

local _SEP_Y_ = header.bottom_y + _SEPARATOR_SPACING_

local separator = Common.initSeparator(
   _G_INIT_DATA_.RIGHT_X,
   _SEP_Y_,
   _G_INIT_DATA_.SECTION_WIDTH
)

local _BAR_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local fs = Common.compound_bar(
   _G_INIT_DATA_.RIGHT_X,
   _BAR_Y_,
   _G_INIT_DATA_.SECTION_WIDTH,
   _BAR_PAD_,
   {'root', 'boot', 'home', 'data', 'dcache', 'tmpfs'},
   _SPACING_,
   12,
   0.8
)

_SPACING_ = nil
_BAR_PAD_ = nil
_FS_PATHS_ = nil
_SEPARATOR_SPACING_ = nil
_BAR_Y_ = nil
_SEP_Y_ = nil

local update = function(cr)
   local smart_pid = Util.execute_cmd('pidof smartd', nil, '*n')
   Common.text_row_set(smart, cr, (smart_pid == '') and 'Error' or 'Running')

   for i = 1, FS_NUM do
      local percent = Util.conky_numeric(conky_used_perc[i])
      Common.compound_bar_set(fs, i, percent * 0.01)
   end
end

M.draw_static = function(cr)
   Common.drawHeader(cr, header)
   Common.text_row_draw_static(smart, cr)
   Line.draw(separator, cr)
   Common.compound_bar_draw_static(fs, cr)
end

M.draw_dynamic = function(cr, trigger)
   if trigger == 0 then update(cr) end
   Common.text_row_draw_dynamic(smart, cr)
   Common.compound_bar_draw_dynamic(fs, cr)
end

return M
