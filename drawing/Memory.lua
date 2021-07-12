local M = {}

local Arc			= require 'Arc'
local Dial 			= require 'Dial'
local TextColumn	= require 'TextColumn'
local LabelPlot		= require 'LabelPlot'
local Table			= require 'Table'
local Util			= require 'Util'
local Common		= require 'Common'

local __string_match		= string.match
local __cairo_path_destroy 	= cairo_path_destroy

local _MODULE_Y_ = 712
local _DIAL_THICKNESS_ = 8
local _TEXT_Y_OFFSET_ = 7
local _TEXT_LEFT_X_OFFSET_ = 30
local _TEXT_SPACING_ = 20
local _PLOT_SECTION_BREAK_ = 30
local _PLOT_HEIGHT_ = 56
local _TABLE_SECTION_BREAK_ = 20
local _TABLE_HEIGHT_ = 114

local MEM_TOTAL_KB = tonumber(Util.read_file('/proc/meminfo', '^MemTotal:%s+(%d+)'))

local MEMINFO_REGEX = '\nMemFree:%s+(%d+).+'..
                      '\nBuffers:%s+(%d+).+'..
                      '\nCached:%s+(%d+).+'..
                      '\nSwapTotal:%s+(%d+).+'..
                      '\nSwapFree:%s+(%d+).+'..
                      '\nSReclaimable:%s+(%d+)'

local NUM_ROWS = 5

local TABLE_CONKY = {}

for r = 1, NUM_ROWS do
   TABLE_CONKY[r] = {}
   TABLE_CONKY[r].comm = '${top_mem name '..r..'}'
   TABLE_CONKY[r].pid = '${top_mem pid '..r..'}'
   TABLE_CONKY[r].mem = '${top_mem mem '..r..'}'
end

local header = Common.Header(
	_G_INIT_DATA_.RIGHT_X,
	_MODULE_Y_,
	_G_INIT_DATA_.SECTION_WIDTH,
	'MEMORY'
)

local DIAL_RADIUS = 32
local DIAL_THETA_0 = math.rad(90)
local DIAL_THETA_1 = math.rad(360)
local DIAL_X = _G_INIT_DATA_.RIGHT_X + DIAL_RADIUS + _DIAL_THICKNESS_ / 2
local DIAL_Y = header.bottom_y + DIAL_RADIUS + _DIAL_THICKNESS_ / 2

local dial = Common.dial(DIAL_X, DIAL_Y, DIAL_RADIUS, _DIAL_THICKNESS_, 0.8)
local cache_arc = _G_Widget_.Arc(
   _G_Widget_.make_semicircle(DIAL_X, DIAL_Y, DIAL_RADIUS, 90, 360),
   _G_Widget_.arc_style(
      _DIAL_THICKNESS_,
      _G_Patterns_.INDICATOR_FG_SECONDARY
   )
)

local text_ring = Common.initTextRing(
   DIAL_X,
   DIAL_Y,
   DIAL_RADIUS - _DIAL_THICKNESS_ / 2 - 2,
   '%s%%',
   80
)

local _LINE_1_Y_ = header.bottom_y + _TEXT_Y_OFFSET_
local _TEXT_LEFT_X_ = _G_INIT_DATA_.RIGHT_X + DIAL_RADIUS * 2 + _TEXT_LEFT_X_OFFSET_
local _RIGHT_X_ = _G_INIT_DATA_.RIGHT_X + _G_INIT_DATA_.SECTION_WIDTH

local swap = Common.initTextRowCrit(
   _TEXT_LEFT_X_,
   _LINE_1_Y_,
   -- TODO this is silly
   _RIGHT_X_ - _TEXT_LEFT_X_,
   'Swap Usage',
   '%s%%',
   80
)

local cache = {
   labels = _G_Widget_.TextColumn(
      _G_Widget_.make_point(
         _TEXT_LEFT_X_,
         _LINE_1_Y_ + _TEXT_SPACING_
      ),
      {'Page Cache', 'Buffers', 'Kernel Slab'},
      _G_Widget_.text_style(
         Common.normal_font_spec,
         _G_Patterns_.INACTIVE_TEXT_FG,
         'left',
         'center'
      ),
      nil,
      _TEXT_SPACING_
   ),
   percents = _G_Widget_.initTextColumnN(
      _G_Widget_.make_point(
         _RIGHT_X_,
         _LINE_1_Y_ + _TEXT_SPACING_
      ),
      3,
      _G_Widget_.text_style(
         Common.normal_font_spec,
         _G_Patterns_.SECONDARY_FG,
         'right',
         'center'
      ),
      '%s%%',
      _TEXT_SPACING_
   ),
}

local _PLOT_Y_ = _PLOT_SECTION_BREAK_ + header.bottom_y + DIAL_RADIUS * 2

local plot = Common.initThemedLabelPlot(
   _G_INIT_DATA_.RIGHT_X,
   _PLOT_Y_,
   _G_INIT_DATA_.SECTION_WIDTH,
   _PLOT_HEIGHT_,
   Common.percent_label_style
)

local tbl = Common.initTable(
   _G_INIT_DATA_.RIGHT_X,
   _PLOT_Y_ + _PLOT_HEIGHT_ + _TABLE_SECTION_BREAK_,
   _G_INIT_DATA_.SECTION_WIDTH,
   _TABLE_HEIGHT_,
   NUM_ROWS,
   {'Name', 'PID', 'Mem (%)'}
)

local update = function(cr)
   local conky = Util.conky
   -- see source for the 'free' command (sysinfo.c) for formulas

   local memfree_kb, buffers_kb, cached_kb, swap_total_kb, swap_free_kb,
       slab_reclaimable_kb = __string_match(Util.read_file('/proc/meminfo'), MEMINFO_REGEX)

   local used_percent = (MEM_TOTAL_KB - memfree_kb - cached_kb - buffers_kb - slab_reclaimable_kb) / MEM_TOTAL_KB

   Dial.set(dial, used_percent)
   Common.text_ring_set(text_ring, cr, Util.round_to_string(used_percent * 100))

   local cache_theta = (DIAL_THETA_0 - DIAL_THETA_1) / MEM_TOTAL_KB * memfree_kb + DIAL_THETA_1
   __cairo_path_destroy(cache_arc.path)
   cache_arc.path = Arc.create_path(cr, DIAL_X, DIAL_Y, DIAL_RADIUS, dial.dial_angle, cache_theta)

   Common.text_row_crit_set(swap, cr,
                            Util.precision_round_to_string(
                               (swap_total_kb - swap_free_kb)
                               / swap_total_kb * 100))

   local _percents = cache.percents

   TextColumn.set(_percents, cr, 1, Util.precision_round_to_string(
       cached_kb / MEM_TOTAL_KB * 100))

   TextColumn.set(_percents, cr, 2, Util.precision_round_to_string(
       buffers_kb / MEM_TOTAL_KB * 100))

   TextColumn.set(_percents, cr, 3, Util.precision_round_to_string(
       slab_reclaimable_kb / MEM_TOTAL_KB * 100))

   LabelPlot.update(plot, used_percent)

   for r = 1, NUM_ROWS do
      local comm = conky(TABLE_CONKY[r].comm, '(%S+)') -- may have trailing space
      local pid = conky(TABLE_CONKY[r].pid)
      local mem = conky(TABLE_CONKY[r].mem)
      Table.set(tbl, cr, 1, r, comm)
      Table.set(tbl, cr, 2, r, pid)
      Table.set(tbl, cr, 3, r, mem)
   end
end

_MODULE_Y_ = nil
_DIAL_THICKNESS_ = nil
_DIAL_SPACING_ = nil
_TEXT_Y_OFFSET_ = nil
_TEXT_LEFT_X_OFFSET_ = nil
_TEXT_SPACING_ = nil
_PLOT_SECTION_BREAK_ = nil
_PLOT_HEIGHT_ = nil
_TABLE_SECTION_BREAK_ = nil
_TABLE_HEIGHT_ = nil
_LINE_1_Y_ = nil
_TEXT_LEFT_X_ = nil
_RIGHT_X_ = nil
_PLOT_Y_ = nil

M.draw_static = function(cr)
   Common.drawHeader(cr, header)

   Common.text_ring_draw_static(text_ring, cr)
   Dial.draw_static(dial, cr)

   Common.text_row_crit_draw_static(swap, cr)
   TextColumn.draw(cache.labels, cr)
   LabelPlot.draw_static(plot, cr)

   Table.draw_static(tbl, cr)
end

M.draw_dynamic = function(cr)
   update(cr)

   Dial.draw_dynamic(dial, cr)
   Arc.draw(cache_arc, cr)
   Common.text_ring_draw_dynamic(text_ring, cr)

   Common.text_row_crit_draw_dynamic(swap, cr)
   TextColumn.draw(cache.percents, cr)

   LabelPlot.draw_dynamic(plot, cr)

   Table.draw_dynamic(tbl, cr)
end

return M
