local M = {}

local Util = require 'Util'
local Arc = require 'Arc'
local Text = require 'Text'
local CompoundBar = require 'CompoundBar'
local CriticalText = require 'CriticalText'
local TextColumn = require 'TextColumn'
local Line = require 'Line'
local LabelPlot = require 'LabelPlot'
local ScalePlot = require 'ScalePlot'

--------------------------------------------------------------------------------
-- constants

local FONT = 'Neuropolitical'

local NORMAL_FONT_SIZE = 13
local PLOT_LABEL_FONT_SIZE = 8
local TABLE_FONT_SIZE = 11
local HEADER_FONT_SIZE = 15

local HEADER_HEIGHT = 45
local HEADER_UNDERLINE_CAP = CAIRO_LINE_CAP_ROUND
local HEADER_UNDERLINE_OFFSET = 26
local HEADER_UNDERLINE_THICKNESS = 3

local SEPARATOR_THICKNESS = 1

local TABLE_BODY_FORMAT = 8
local TABLE_VERT_PAD = 15
local TABLE_HORZ_PAD = 5
local TABLE_HEADER_PAD = 20
local TABLE_LINE_THICKNESS = 1

local PLOT_NUM_POINTS = 90
local PLOT_GRID_X_N = 9
local PLOT_GRID_Y_N = 4

local ARC_WIDTH = 2

local DIAL_THETA0 = 90
local DIAL_THETA1 = 360

--------------------------------------------------------------------------------
-- helper functions

M.make_font_spec = function(f, s, bold)
   return {
      family = f,
      size = s,
      weight = bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL,
      slant = CAIRO_FONT_WEIGHT_NORMAL,
   }
end

M.normal_font_spec = M.make_font_spec(FONT, NORMAL_FONT_SIZE, false)
M.label_font_spec = M.make_font_spec(FONT, PLOT_LABEL_FONT_SIZE, false)

local _text_row_style = function(x_align, color)
   return _G_Widget_.text_style(M.normal_font_spec, color, x_align, 'center')
end

M.left_text_style = _text_row_style('left', _G_Patterns_.INACTIVE_TEXT_FG)

M.right_text_style = _text_row_style('right', _G_Patterns_.PRIMARY_FG)

local _bare_text = function(pt, text, style)
   return _G_Widget_.plainText(pt, text, style)
end

local _left_text = function(pt, text)
   return _bare_text(pt, text, M.left_text_style)
end

local _right_text = function(pt, text)
   return _bare_text(pt, text, M.right_text_style)
end

--------------------------------------------------------------------------------
-- header

M.Header = function(x, y, w, s)
   local bottom_y = y + HEADER_HEIGHT
   local underline_y = y + HEADER_UNDERLINE_OFFSET
   return {
      text = _G_Widget_.plainText(
         _G_Widget_.make_point(x, y),
         s,
         _G_Widget_.text_style(
            M.make_font_spec(FONT, HEADER_FONT_SIZE, true),
            _G_Patterns_.HEADER_FG,
            'left',
            'top'
         )
      ),
      bottom_y = bottom_y,
      underline = _G_Widget_.Line(
         _G_Widget_.make_point(x, underline_y),
         _G_Widget_.make_point(x + w, underline_y),
         _G_Widget_.line_style(
            HEADER_UNDERLINE_THICKNESS,
            _G_Patterns_.HEADER_FG,
            HEADER_UNDERLINE_CAP
         )
      )
   }
end

M.drawHeader = function(cr, header)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)
end

--------------------------------------------------------------------------------
-- label plot

M.default_grid_style = _G_Widget_.grid_style(
   PLOT_GRID_X_N,
   PLOT_GRID_Y_N,
   _G_Patterns_.BORDER_FG
)

M.default_plot_style = _G_Widget_.plot_style(
   PLOT_NUM_POINTS,
   _G_Patterns_.BORDER_FG,
   _G_Patterns_.PLOT_FILL_BORDER_PRIMARY,
   _G_Patterns_.PLOT_FILL_BG_PRIMARY,
   M.default_grid_style
)

M.percent_label_style = _G_Widget_.label_style(
   _G_Patterns_.INACTIVE_TEXT_FG,
   M.label_font_spec,
   function(z) return Util.round_to_string(z * 100)..'%' end
)

M.initThemedLabelPlot = function(x, y, w, h, label_style)
   return _G_Widget_.LabelPlot(
      _G_Widget_.make_box(x, y, w, h),
      1 / _G_INIT_DATA_.UPDATE_INTERVAL,
      M.default_plot_style,
      label_style
   )
end

--------------------------------------------------------------------------------
-- percent plot (label plot with percent signs and some indicator data above it)

M.initPercentPlot_formatted = function(x, y, w, h, spacing, label, format)
   return {
      label = _left_text(_G_Widget_.make_point(x, y), label),
      value = _G_Widget_.formattedThresholdText(
         _G_Widget_.make_point(x + w, y),
         nil,
         M.right_text_style,
         format,
         _G_Widget_.threshold_text_style(_G_Patterns_.CRITICAL_FG, 80)
      ),
      plot = M.initThemedLabelPlot(
         x,
         y + spacing,
         w,
         h,
         M.percent_label_style
      ),
   }
end

M.initPercentPlot = function(x, y, w, h, spacing, label)
   return M.initPercentPlot_formatted(x, y, w, h, spacing, label, '%s%%')
end

M.percent_plot_draw_static = function(pp, cr)
   Text.draw(pp.label, cr)
   LabelPlot.draw_static(pp.plot, cr)
end

M.percent_plot_draw_dynamic = function(pp, cr)
   CriticalText.draw(pp.value, cr)
   LabelPlot.draw_dynamic(pp.plot, cr)
end

-- TODO this is pretty confusing, nil means -1 which gets fed to any text
-- formatting functions
M.percent_plot_set = function(pp, cr, value)
   local t = -1
   local p = 0
   if value ~= nil then
      t = math.floor(value)
      p = value * 0.01
   end
   Text.set(pp.value, cr, t)
   LabelPlot.update(pp.plot, p)
end

--------------------------------------------------------------------------------
-- scaled plot

M.base_2_scale_data = function(m)
   return _G_Widget_.scale_data(2, m, 0.9)
end

M.initThemedScalePlot = function(x, y, w, h, f, min_domain)
   return _G_Widget_.ScalePlot(
      _G_Widget_.make_box(x, y, w, h),
      1 / _G_INIT_DATA_.UPDATE_INTERVAL,
      M.default_plot_style,
      _G_Widget_.label_style(
         _G_Patterns_.INACTIVE_TEXT_FG,
         M.label_font_spec,
         f
      ),
      M.base_2_scale_data(min_domain)
   )
end

--------------------------------------------------------------------------------
-- scaled plot (with textual data above it)

M.initLabeledScalePlot = function(x, y, w, h, format_fun, label_fun, spacing,
                                  label, min_domain)
   return {
      label = _left_text(_G_Widget_.make_point(x, y), label),
      value = _G_Widget_.formatted_text(
         _G_Widget_.make_point(x + w, y),
         0,
         M.right_text_style,
         format_fun
      ),
      plot = M.initThemedScalePlot(x, y + spacing, w, h, label_fun, min_domain),
   }
end

M.annotated_scale_plot_draw_static = function(asp, cr)
   Text.draw(asp.label, cr)
end

M.annotated_scale_plot_draw_dynamic = function(asp, cr)
   Text.draw(asp.value, cr)
   ScalePlot.draw_dynamic(asp.plot, cr)
end

M.annotated_scale_plot_set = function(asp, cr, value)
   Text.set(asp.value, cr, value)
   ScalePlot.update(asp.plot, cr, value)
end

--------------------------------------------------------------------------------
-- arc (TODO this is just a dummy now to make everything organized

-- TODO perhaps implement this is a special case of compound dial where
-- I have multiple layers on top of each other

M.arc = function(x, y, r, thickness, pattern)
   return _G_Widget_.Arc(
      _G_Widget_.make_semicircle(x, y, r, 90, 360),
      _G_Widget_.arc_style(thickness, pattern)
   )
end

--------------------------------------------------------------------------------
-- ring

M.initRing = function(x, y, r)
   return _G_Widget_.Arc(
      _G_Widget_.make_semicircle(x, y, r, 0, 360),
      _G_Widget_.arc_style(ARC_WIDTH, _G_Patterns_.BORDER_FG)
   )
end

--------------------------------------------------------------------------------
-- ring with text data in the center

M.initTextRing = function(x, y, r, fmt, limit)
   return {
	  ring = M.initRing(x, y, r),
	  value = _G_Widget_.formattedThresholdText(
         _G_Widget_.make_point(x, y),
         nil,
         _G_Widget_.text_style(
            M.normal_font_spec,
            _G_Patterns_.PRIMARY_FG,
            'center',
            'center'
         ),
         fmt,
         _G_Widget_.threshold_text_style(_G_Patterns_.CRITICAL_FG, limit)
	  ),
   }
end

M.text_ring_draw_static = function(tr, cr)
   Arc.draw(tr.ring, cr)
end

M.text_ring_draw_dynamic = function(tr, cr)
   CriticalText.draw(tr.value, cr)
end

M.text_ring_set = function(tr, cr, value)
   CriticalText.set(tr.value, cr, value)
end

--------------------------------------------------------------------------------
-- dial

local threshold_indicator = function(threshold)
   return _G_Widget_.threshold_style(
      _G_Patterns_.INDICATOR_FG_PRIMARY,
      _G_Patterns_.INDICATOR_FG_CRITICAL,
      threshold
   )
end

M.dial = function(x, y, radius, thickness, threshold)
   return _G_Widget_.Dial(
      _G_Widget_.make_semicircle(x, y, radius, DIAL_THETA0, DIAL_THETA1),
      _G_Widget_.arc_style(thickness, _G_Patterns_.INDICATOR_BG),
      threshold_indicator(threshold)
   )
end

--------------------------------------------------------------------------------
-- compound dial

M.compound_dial = function(x, y, outer_radius, inner_radius, thickness,
                           threshold, num_dials)
   return _G_Widget_.CompoundDial(
      _G_Widget_.make_semicircle(x, y, outer_radius, DIAL_THETA0, DIAL_THETA1),
      _G_Widget_.arc_style(thickness, _G_Patterns_.INDICATOR_BG),
      threshold_indicator(threshold),
      inner_radius,
      num_dials
   )
end

--------------------------------------------------------------------------------
-- annotated compound bar

M.compound_bar = function(x, y, w, pad, labels, spacing, thickness, threshold)
   return {
      labels = _G_Widget_.TextColumn(
         _G_Widget_.make_point(x, y),
         labels,
         M.left_text_style,
         nil,
         spacing
      ),
      bars = _G_Widget_.CompoundBar(
         _G_Widget_.make_point(x + pad, y),
         w - pad,
         _G_Widget_.line_style(
            thickness,
            _G_Patterns_.INDICATOR_BG,
            CAIRO_LINE_JOIN_MITER
         ),
         threshold_indicator(threshold),
         spacing,
         #labels,
         false
      )
   }
end

M.compound_bar_draw_static = function(cb, cr)
   TextColumn.draw(cb.labels, cr)
   CompoundBar.draw_static(cb.bars, cr)
end

M.compound_bar_draw_dynamic = function(cb, cr)
   CompoundBar.draw_dynamic(cb.bars, cr)
end

M.compound_bar_set = function(cb, i, value)
   CompoundBar.set(cb.bars, i, value)
end

--------------------------------------------------------------------------------
-- separator (eg a horizontal line)

M.initSeparator = function(x, y, w)
   return _G_Widget_.Line(
      _G_Widget_.make_point(x, y),
      _G_Widget_.make_point(x + w, y),
      _G_Widget_.line_style(
         SEPARATOR_THICKNESS,
         _G_Patterns_.BORDER_FG,
         CAIRO_LINE_CAP_BUTT
      )
   )
end

--------------------------------------------------------------------------------
-- text row (label with a value, aligned as far apart as possible)

M.initTextRow = function(x, y, w, label)
   return {
      label = _left_text(_G_Widget_.make_point(x, y), label),
      value = _right_text(_G_Widget_.make_point(x + w, y), nil),
   }
end

M.text_row_draw_static = function(row, cr)
   Text.draw(row.label, cr)
end

M.text_row_draw_dynamic = function(row, cr)
   Text.draw(row.value, cr)
end

M.text_row_set = function(row, cr, value)
   Text.set(row.value, cr, value)
end

--------------------------------------------------------------------------------
-- text row with critical indicator

M.initTextRowCrit = function(x, y, w, label, append_end, limit)
   return{
      label = _left_text(_G_Widget_.make_point(x, y), label),
      value = _G_Widget_.formattedThresholdText(
         _G_Widget_.make_point(x + w, y),
         nil,
         _G_Widget_.text_style(
            M.normal_font_spec,
            _G_Patterns_.PRIMARY_FG,
            'right',
            'center'
         ),
         append_end,
         _G_Widget_.threshold_text_style(_G_Patterns_.CRITICAL_FG, limit)
      )
   }
end

M.text_row_crit_draw_static = M.text_row_draw_static

M.text_row_crit_draw_dynamic = function(row, cr)
   CriticalText.draw(row.value, cr)
end

M.text_row_crit_set = function(row, cr, value)
   CriticalText.set(row.value, cr, value)
end

--------------------------------------------------------------------------------
-- text column

M.text_column = function(x, y, spacing, labels, x_align, color)
   return _G_Widget_.TextColumn(
      _G_Widget_.make_point(x, y),
      labels,
      _text_row_style(x_align, color),
      nil,
      spacing
   )
end

--------------------------------------------------------------------------------
-- multiple text row separated by spacing

M.initTextRows_color = function(x, y, w, spacing, labels, color, format)
   return {
      labels = _G_Widget_.TextColumn(
         _G_Widget_.make_point(x, y),
         labels,
         M.left_text_style,
         nil,
         spacing
      ),
      values = _G_Widget_.initTextColumnN(
         _G_Widget_.make_point(x + w, y),
         #labels,
         _text_row_style('right', color),
         format,
         spacing
      )
   }
end

M.initTextRows = function(x, y, w, spacing, labels)
   return M.initTextRows_color(
      x,
      y,
      w,
      spacing,
      labels,
      _G_Patterns_.PRIMARY_FG,
      nil
   )
end

M.text_rows_draw_static = function(rows, cr)
   TextColumn.draw(rows.labels, cr)
end

M.text_rows_draw_dynamic = function(rows, cr)
   TextColumn.draw(rows.values, cr)
end

M.text_rows_set = function(rows, cr, i, value)
   TextColumn.set(rows.values, cr, i, value)
end

--------------------------------------------------------------------------------
-- table

M.default_table_font_spec = M.make_font_spec(FONT, TABLE_FONT_SIZE, false)

M.default_table_style = _G_Widget_.table_style(
   _G_Widget_.rect_style(
      TABLE_LINE_THICKNESS,
      _G_Patterns_.BORDER_FG
   ),
   _G_Widget_.line_style(
      TABLE_LINE_THICKNESS,
      _G_Patterns_.BORDER_FG,
      CAIRO_LINE_CAP_BUTT
   ),
   _G_Widget_.table_header_style(
      M.default_table_font_spec,
      _G_Patterns_.PRIMARY_FG,
      TABLE_HEADER_PAD
   ),
   _G_Widget_.table_body_style(
      M.default_table_font_spec,
      _G_Patterns_.INACTIVE_TEXT_FG,
      TABLE_BODY_FORMAT
   ),
   _G_Widget_.padding(
      TABLE_HORZ_PAD,
      TABLE_VERT_PAD,
      TABLE_HORZ_PAD,
      TABLE_VERT_PAD
   )
)

M.initTable = function(x, y, w, h, n, labels)
   return _G_Widget_.Table(
      _G_Widget_.make_box(x, y, w, h),
      n,
      labels,
      M.default_table_style
   )
end

--------------------------------------------------------------------------------
-- panel

M.initPanel = function(x, y, w, h, thickness)
   return _G_Widget_.FillRect(
      _G_Widget_.make_box(x, y, w, h),
      _G_Widget_.rect_style(thickness, _G_Patterns_.BORDER_FG),
      _G_Patterns_.PANEL_BG
   )
end

return M
