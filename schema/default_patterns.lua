local c = {}

local Color = require 'Color'

local white = 0xffffffff
	
local grey1 = 0xeeeeeeff
local grey2 = 0xbfbfbfff
local grey3 = 0xd6d6d6ff
local grey4 = 0x888888ff
local grey5 = 0x565656ff
local grey6 = 0x2f2f2fb2
local black = 0x000000ff

local blue1 = 0x99CEFFff
local blue2 = 0xBFE1FFff
local blue3 = 0x316BA6ff

local red1 = 0xFF3333ff
local red2 = 0xFF8282ff
local red3 = 0xFFB8B8ff

local purple1 = 0xeecfffff
local purple2 = 0xcb91ffff
local purple3 = 0x9523ffff

c.white = Color.init{hex_rgba = white}

c.light_grey = Color.init{hex_rgba = grey1}
c.mid_grey = Color.init{hex_rgba = grey3}
c.dark_grey = Color.init{hex_rgba = grey4}

c.blue = Color.init{hex_rgba = blue2}
c.red = Color.init{hex_rgba = red2}
c.purple = Color.init{hex_rgba = purple2}

c.grey_rounded = Color.Gradient{
	Color.ColorStop{hex_rgba = grey5, stop = 0.0},
	Color.ColorStop{hex_rgba = grey2, stop = 0.5},
	Color.ColorStop{hex_rgba = grey5, stop = 1.0}	
}

c.blue_rounded = Color.Gradient{
	Color.ColorStop{hex_rgba = blue3, stop = 0.0},
	Color.ColorStop{hex_rgba = blue1, stop = 0.5},
	Color.ColorStop{hex_rgba = blue3, stop = 1.0}
}

c.red_rounded = Color.Gradient{
	Color.ColorStop{hex_rgba = red1, stop = 0.0},
	Color.ColorStop{hex_rgba = red3, stop = 0.5},
	Color.ColorStop{hex_rgba = red1, stop = 1.0}
}

c.purple_rounded = Color.Gradient{
	Color.ColorStop{hex_rgba = purple3, stop = 0.0},
	Color.ColorStop{hex_rgba = purple1, stop = 0.5},
	Color.ColorStop{hex_rgba = purple3, stop = 1.0}
}

--~ c.transparent_black = Color.Gradient{
	--~ Color.ColorStop{hex_rgba = grey6, stop = 0.0, force_alpha = 0.7},
	--~ Color.ColorStop{hex_rgba = black, stop = 1.0, force_alpha = 0.7}
--~ }

c.transparent_black = Color.init{hex_rgba = black, force_alpha = 0.7}

c.transparent_blue = Color.Gradient{
	Color.ColorStop{hex_rgba = blue3, stop = 0.0, force_alpha = 0.2},
	Color.ColorStop{hex_rgba = blue1, stop = 1.0, force_alpha = 1.0}
}

return c
