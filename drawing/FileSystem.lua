local M = {}

local Patterns      = require 'Patterns'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local CompoundBar	= require 'CompoundBar'
local Util			= require 'Util'

local __string_match 	= string.match

local _FS_PATHS_ = {'/', '/boot', '/home', '/mnt/data', '/mnt/dcache', "/tmp"}
local _MODULE_Y_ = 170
local _SPACING_ = 20
local _BAR_PAD_ = 100
local _SEPARATOR_SPACING_ = 20

local FS_NUM = #_FS_PATHS_

local header = _G_Widget_.Header{
	x = _G_INIT_DATA_.RIGHT_X,
	y = _MODULE_Y_,
	width = _G_INIT_DATA_.SECTION_WIDTH,
	header = 'FILE SYSTEMS'
}

local conky_used_perc = {}

for i, v in pairs(_FS_PATHS_) do
	conky_used_perc[i] = '${fs_used_perc '..v..'}'
end

local smart = {
   label = _G_Widget_.Text{
      x    = _G_INIT_DATA_.RIGHT_X,
      y    = header.bottom_y,
      text = 'SMART Daemon'
   },
   value = _G_Widget_.Text{
	  x          = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH,
	  y 	     = header.bottom_y,
	  x_align 	 = 'right',
	  text_color = Patterns.BLUE,
	  text       = '<smartd>',
   }
}

local _SEP_Y_ = header.bottom_y + _SEPARATOR_SPACING_

local separator = _G_Widget_.Line{
   p1 = {
      x = _G_INIT_DATA_.RIGHT_X,
      y = _SEP_Y_,
   },
   p2 = {
      x = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH,
      y = _SEP_Y_,
   }
}

local _BAR_Y_ = _SEP_Y_ + _SEPARATOR_SPACING_

local bars = _G_Widget_.CompoundBar{
	x 				= _G_INIT_DATA_.RIGHT_X + _BAR_PAD_,
	y 				= _BAR_Y_,
	length 			= _G_INIT_DATA_.SECTION_WIDTH - _BAR_PAD_,
	spacing 		= _SPACING_,
	num_bars 		= FS_NUM,
    -- thickness       = 12,
	critical_limit	= '>0.8'
}

local labels = _G_Widget_.TextColumn{
	x 		= _G_INIT_DATA_.RIGHT_X,
	y 		= _BAR_Y_,
	spacing = _SPACING_,
	'root',
	'boot',
	'home',
	'data',
	'dcache',
	'tmpfs',
}

_SPACING_ = nil
_BAR_PAD_ = nil
_FS_PATHS_ = nil
_SEPARATOR_SPACING_ = nil
_BAR_Y_ = nil
_SEPARATOR_SPACING_ = nil
_SEP_Y_ = nil

local update = function(cr)
   local smart_pid = Util.execute_cmd('pidof smartd', nil, '*n')
   Text.set(smart.value, cr, (smart_pid == '') and 'Error' or 'Running')
   
   for i = 1, FS_NUM do
      local percent = Util.conky_numeric(conky_used_perc[i])
      CompoundBar.set(bars, i, percent * 0.01)
   end
end

local draw_static = function(cr)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)

   Text.draw(smart.label, cr)
   Line.draw(separator, cr)

   TextColumn.draw(labels, cr)
   CompoundBar.draw_static(bars, cr)
end

local draw_dynamic = function(cr, trigger)
   if trigger == 0 then update(cr) end

   Text.draw(smart.value, cr)

   CompoundBar.draw_dynamic(bars, cr)
end

M.draw_static = draw_static
M.draw_dynamic = draw_dynamic

return M
