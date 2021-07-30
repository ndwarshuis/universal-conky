local M = {}

local color = require 'color'

M.FONT = 'Neuropolitical'

-- text colors
M.HEADER_FG = color.rgb(0xefefef)

M.PRIMARY_FG = color.rgb(0xbfe1ff)
M.CRITICAL_FG = color.rgb(0xff8282)

M.INACTIVE_TEXT_FG = color.rgb(0xc8c8c8)
M.MID_GREY = color.rgb(0xd6d6d6)
M.BORDER_FG = color.rgb(0x888888)
M.PLOT_GRID_FG = color.rgb(0x666666)
M.PLOT_OUTLINE_FG = color.rgb(0x777777)


-- arc bg colors
local GREY2 = 0xbfbfbf
local GREY5 = 0x565656
M.INDICATOR_BG = color.gradient_rgb{
   [0.0] = GREY5,
   [0.5] = GREY2,
   [1.0] = GREY5
}

-- arc/bar fg colors
local PRIMARY1 = 0x99CEFF
local PRIMARY3 = 0x316BA6
M.INDICATOR_FG_PRIMARY = color.gradient_rgb{
   [0.0] = PRIMARY3,
   [0.5] = PRIMARY1,
   [1.0] = PRIMARY3
}

local CRITICAL1 = 0xFF3333
local CRITICAL3 = 0xFFB8B8
M.INDICATOR_FG_CRITICAL = color.gradient_rgb{
   [0.0] = CRITICAL1,
   [0.5] = CRITICAL3,
   [1.0] = CRITICAL1
}

-- plot colors
local PLOT_PRIMARY1 = 0x003f7c
local PLOT_PRIMARY2 = 0x1e90ff
local PLOT_PRIMARY3 = 0x316ece
local PLOT_PRIMARY4 = 0x8cc7ff
M.PLOT_FILL_BORDER_PRIMARY = color.gradient_rgb{
   [0.0] = PLOT_PRIMARY1,
   [1.0] = PLOT_PRIMARY2
}

M.PLOT_FILL_BG_PRIMARY = color.gradient_rgba{
   [0.2] = {PLOT_PRIMARY3, 0.5},
   [1.0] = {PLOT_PRIMARY4, 1.0}
}

-- panel pattern
M.PANEL_BG = color.rgba(0x121212, 0.7)

return M
