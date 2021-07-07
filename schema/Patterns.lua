local M = {}

local Color = require 'Color'
local Util 	= require 'Util'

M.FONT = 'Neuropolitical'
-- text colors
M.HEADER_FG = Color.rgb(0xffffff)

M.INACTIVE_TEXT_FG = Color.rgb(0xeeeeee)
-- TODO this is also the plot label color
M.MID_GREY = Color.rgb(0xd6d6d6)
M.BORDER_FG = Color.rgb(0x888888)

M.PRIMARY_FG = Color.rgb(0xbfe1ff)
M.SECONDARY_FG = Color.rgb(0xcb91ff)
M.TERTIARY_FG = Color.rgb(0xefe7aa)
M.CRITICAL_FG = Color.rgb(0xff8282)

-- arc patterns
local GREY2 = 0xbfbfbf
local GREY5 = 0x565656
M.INDICATOR_BG = Color.gradient{
	Color.colorstop_rgb(GREY5, 0.0),
	Color.colorstop_rgb(GREY2, 0.5),
	Color.colorstop_rgb(GREY5, 1.0)
}

local BLUE1 = 0x99CEFF
local BLUE3 = 0x316BA6
M.INDICATOR_FG_PRIMARY = Color.gradient{
	Color.colorstop_rgb(BLUE3, 0.0),
	Color.colorstop_rgb(BLUE1, 0.5),
	Color.colorstop_rgb(BLUE3, 1.0)
}

local PURPLE1 = 0xeecfff
local PURPLE3 = 0x9523ff
M.INDICATOR_FG_SECONDARY = Color.gradient{
	Color.colorstop_rgb(PURPLE3, 0.0),
	Color.colorstop_rgb(PURPLE1, 0.5),
	Color.colorstop_rgb(PURPLE3, 1.0)
}

local RED1 = 0xFF3333
local RED3 = 0xFFB8B8
M.INDICATOR_FG_CRITICAL = Color.gradient{
	Color.colorstop_rgb(RED1, 0.0),
	Color.colorstop_rgb(RED3, 0.5),
	Color.colorstop_rgb(RED1, 1.0)
}

-- plot patterns
local PLOT_BLUE1 = 0x003f7c
local PLOT_BLUE2 = 0x1e90ff
local PLOT_BLUE3 = 0x316ece
local PLOT_BLUE4 = 0x8cc7ff
M.PLOT_FILL_BORDER_PRIMARY = Color.gradient{
	Color.colorstop_rgb(PLOT_BLUE1, 0.0),
	Color.colorstop_rgb(PLOT_BLUE2, 1.0)
}

M.PLOT_FILL_BG_PRIMARY = Color.gradient{
	Color.colorstop_rgba(PLOT_BLUE3, 0.2, 0.0),
	Color.colorstop_rgba(PLOT_BLUE4, 1.0, 1.0)
}

local PLOT_PURPLE1 = 0x3e0077
local PLOT_PURPLE2 = 0x9523ff
local PLOT_PURPLE3 = 0x7a30a3
local PLOT_PURPLE4 = 0xeac4ff
M.PLOT_FILL_BORDER_SECONDARY = Color.gradient{
	Color.colorstop_rgb(PLOT_PURPLE1, 0.0),
	Color.colorstop_rgb(PLOT_PURPLE2, 1.0)
}

M.PLOT_FILL_BG_SECONDARY = Color.gradient{
	Color.colorstop_rgba(PLOT_PURPLE3, 0.2, 0.0),
	Color.colorstop_rgba(PLOT_PURPLE4, 1.0, 1.0)
}

local PLOT_YELLOW1 = 0x231f00
local PLOT_YELLOW2 = 0x7c6f00
local PLOT_YELLOW3 = 0x8c8225
local PLOT_YELLOW4 = 0xfff387
M.PLOT_FILL_BORDER_TERTIARY = Color.gradient{
	Color.colorstop_rgb(PLOT_YELLOW1, 0.0),
	Color.colorstop_rgb(PLOT_YELLOW2, 1.0)
}

M.PLOT_FILL_BG_TERTIARY = Color.gradient{
	Color.colorstop_rgba(PLOT_YELLOW3, 0.2, 0.0),
	Color.colorstop_rgba(PLOT_YELLOW4, 1.0, 1.0)
}

-- panel pattern
M.PANEL_BG = Color.rgba(0x000000, 0.7)

return Util.set_finalizer(M, function() print('Cleaning up Patterns.lua') end)
