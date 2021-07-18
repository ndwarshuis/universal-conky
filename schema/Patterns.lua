local M = {}

local Color = require 'Color'
local Util 	= require 'Util'

M.FONT = 'Neuropolitical'
-- text colors
M.HEADER_FG = Color.rgb(0xeeeeee)

M.INACTIVE_TEXT_FG = Color.rgb(0xaaaaaa)
-- TODO this is also the plot label color
M.MID_GREY = Color.rgb(0xa6a6a6)
M.BORDER_FG = Color.rgb(0x666666)

M.PRIMARY_FG = Color.rgb(0xC7BDFF)
M.SECONDARY_FG = Color.rgb(0xE6D3AC)
M.CRITICAL_FG = Color.rgb(0xff8282)

-- arc bg colors
local GREY2 = 0x9f9f9f
local GREY5 = 0x363636
M.INDICATOR_BG = Color.gradient_rgb{
   [0.0] = GREY5,
   [0.5] = GREY2,
   [1.0] = GREY5
}

-- arc/bar fg colors
local PRIMARY1 = 0xAD9DFB
local PRIMARY3 = 0x4020DF
M.INDICATOR_FG_PRIMARY = Color.gradient_rgb{
   [0.0] = PRIMARY3,
   [0.5] = PRIMARY1,
   [1.0] = PRIMARY3
}

local SECONDARY1 = 0xD9BC87
local SECONDARY3 = 0x59451B
M.INDICATOR_FG_SECONDARY = Color.gradient_rgb{
   [0.0] = SECONDARY3,
   [0.5] = SECONDARY1,
   [1.0] = SECONDARY3
}

local CRITICAL1 = 0xFF3333
local CRITICAL3 = 0xFFB8B8
M.INDICATOR_FG_CRITICAL = Color.gradient_rgb{
   [0.0] = CRITICAL1,
   [0.5] = CRITICAL3,
   [1.0] = CRITICAL1
}

-- plot patterns
local PLOT_PRIMARY1 = 0x15007C
local PLOT_PRIMARY2 = 0x431EFF
local PLOT_PRIMARY3 = 0x4B31CE
local PLOT_PRIMARY4 = 0x9F8CFF
M.PLOT_FILL_BORDER_PRIMARY = Color.gradient_rgb{
   [0.0] = PLOT_PRIMARY1,
   [1.0] = PLOT_PRIMARY2
}

M.PLOT_FILL_BG_PRIMARY = Color.gradient_rgba{
   [0.2] = {PLOT_PRIMARY3, 0.5},
   [1.0] = {PLOT_PRIMARY4, 1.0}
}

-- panel pattern
M.PANEL_BG = Color.rgba(0x000000, 0.7)

return Util.set_finalizer(M, function() print('Cleaning up Patterns.lua') end)
