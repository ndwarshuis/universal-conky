local M = {}

local Color = require 'Color'

local WHITE = 0xffffffff
	
local GREY1 = 0xeeeeeeff
local GREY2 = 0xbfbfbfff
local GREY3 = 0xd6d6d6ff
local GREY4 = 0x888888ff
local GREY5 = 0x565656ff
local GREY6 = 0x2f2f2fb2
local BLACK = 0x000000ff

local BLUE1 = 0x99CEFFff
local BLUE2 = 0xBFE1FFff
local BLUE3 = 0x316BA6ff

local RED1 = 0xFF3333ff
local RED2 = 0xFF8282ff
local RED3 = 0xFFB8B8ff

local PURPLE1 = 0xeecfffff
local PURPLE2 = 0xcb91ffff
local PURPLE3 = 0x9523ffff

M.WHITE = Color.init{hex_rgba = WHITE}

M.LIGHT_GREY = Color.init{hex_rgba = GREY1}
M.MID_GREY = Color.init{hex_rgba = GREY3}
M.DARK_GREY = Color.init{hex_rgba = GREY4}

M.BLUE = Color.init{hex_rgba = BLUE2}
M.RED = Color.init{hex_rgba = RED2}
M.PURPLE = Color.init{hex_rgba = PURPLE2}

M.GREY_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = GREY5, stop = 0.0},
	Color.ColorStop{hex_rgba = GREY2, stop = 0.5},
	Color.ColorStop{hex_rgba = GREY5, stop = 1.0}	
}

M.BLUE_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = BLUE3, stop = 0.0},
	Color.ColorStop{hex_rgba = BLUE1, stop = 0.5},
	Color.ColorStop{hex_rgba = BLUE3, stop = 1.0}
}

M.RED_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = RED1, stop = 0.0},
	Color.ColorStop{hex_rgba = RED3, stop = 0.5},
	Color.ColorStop{hex_rgba = RED1, stop = 1.0}
}

M.PURPLE_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = PURPLE3, stop = 0.0},
	Color.ColorStop{hex_rgba = PURPLE1, stop = 0.5},
	Color.ColorStop{hex_rgba = PURPLE3, stop = 1.0}
}

M.TRANSPARENT_BLACK = Color.init{hex_rgba = BLACK, force_alpha = 0.7}

M.TRANSPARENT_BLUE = Color.Gradient{
	Color.ColorStop{hex_rgba = BLUE3, stop = 0.0, force_alpha = 0.2},
	Color.ColorStop{hex_rgba = BLUE1, stop = 1.0, force_alpha = 1.0}
}

return M
