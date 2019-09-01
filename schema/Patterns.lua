local M = {}

local Color = require 'Color'
local Util 	= require 'Util'

-- text colors
M.WHITE = Color.init{hex_rgba = 0xffffff}

M.LIGHT_GREY = Color.init{hex_rgba = 0xeeeeee}
M.MID_GREY = Color.init{hex_rgba = 0xd6d6d6}
M.DARK_GREY = Color.init{hex_rgba = 0x888888}

M.BLUE = Color.init{hex_rgba = 0xbfe1ff}
M.RED = Color.init{hex_rgba = 0xff8282}
M.PURPLE = Color.init{hex_rgba = 0xcb91ff}
M.YELLOW = Color.init{hex_rgba = 0xefe7aa
}
-- arc patterns
local GREY2 = 0xbfbfbf
local GREY5 = 0x565656
M.GREY_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = GREY5, stop = 0.0},
	Color.ColorStop{hex_rgba = GREY2, stop = 0.5},
	Color.ColorStop{hex_rgba = GREY5, stop = 1.0}	
}

local BLUE1 = 0x99CEFF
local BLUE3 = 0x316BA6
M.BLUE_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = BLUE3, stop = 0.0},
	Color.ColorStop{hex_rgba = BLUE1, stop = 0.5},
	Color.ColorStop{hex_rgba = BLUE3, stop = 1.0}
}

local RED1 = 0xFF3333
local RED3 = 0xFFB8B8
M.RED_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = RED1, stop = 0.0},
	Color.ColorStop{hex_rgba = RED3, stop = 0.5},
	Color.ColorStop{hex_rgba = RED1, stop = 1.0}
}

local PURPLE1 = 0xeecfff
local PURPLE3 = 0x9523ff
M.PURPLE_ROUNDED = Color.Gradient{
	Color.ColorStop{hex_rgba = PURPLE3, stop = 0.0},
	Color.ColorStop{hex_rgba = PURPLE1, stop = 0.5},
	Color.ColorStop{hex_rgba = PURPLE3, stop = 1.0}
}

M.TRANSPARENT_BLUE = Color.Gradient{
	Color.ColorStop{hex_rgba = BLUE3, stop = 0.0, alpha = 0.2},
	Color.ColorStop{hex_rgba = BLUE1, stop = 1.0, alpha = 1.0}
}

-- plot patterns
local PLOT_BLUE1 = 0x003f7c
local PLOT_BLUE2 = 0x1e90ff
local PLOT_BLUE3 = 0x316ece
local PLOT_BLUE4 = 0x8cc7ff
M.PLOT_LINE_BLUE = Color.Gradient{
	Color.ColorStop{hex_rgba = PLOT_BLUE1, stop = 0.0},
	Color.ColorStop{hex_rgba = PLOT_BLUE2, stop = 1.0}
}

M.PLOT_FILL_BLUE = Color.Gradient{
	Color.ColorStop{hex_rgba = PLOT_BLUE3, stop = 0.0, alpha = 0.2},
	Color.ColorStop{hex_rgba = PLOT_BLUE4, stop = 1.0, alpha = 1.0}
}

local PLOT_PURPLE1 = 0x3e0077
local PLOT_PURPLE2 = 0x9523ff
local PLOT_PURPLE3 = 0x7a30a3
local PLOT_PURPLE4 = 0xeac4ff
M.PLOT_LINE_PURPLE = Color.Gradient{
	Color.ColorStop{hex_rgba = PLOT_PURPLE1, stop = 0.0},
	Color.ColorStop{hex_rgba = PLOT_PURPLE2, stop = 1.0}
}

M.PLOT_FILL_PURPLE = Color.Gradient{
	Color.ColorStop{hex_rgba = PLOT_PURPLE3, stop = 0.0, alpha = 0.2},
	Color.ColorStop{hex_rgba = PLOT_PURPLE4, stop = 1.0, alpha = 1.0}
}

local PLOT_YELLOW1 = 0x231f00
local PLOT_YELLOW2 = 0x7c6f00
local PLOT_YELLOW3 = 0x8c8225
local PLOT_YELLOW4 = 0xfff387
M.PLOT_LINE_YELLOW = Color.Gradient{
	Color.ColorStop{hex_rgba = PLOT_YELLOW1, stop = 0.0},
	Color.ColorStop{hex_rgba = PLOT_YELLOW2, stop = 1.0}
}

M.PLOT_FILL_YELLOW = Color.Gradient{
	Color.ColorStop{hex_rgba = PLOT_YELLOW3, stop = 0.0, alpha = 0.2},
	Color.ColorStop{hex_rgba = PLOT_YELLOW4, stop = 1.0, alpha = 1.0}
}

-- panel pattern
M.TRANSPARENT_BLACK = Color.init{hex_rgba = 0x000000, alpha = 0.7}

M = Util.set_finalizer(M, function() print('Cleaning up Patterns.lua') end)

return M
