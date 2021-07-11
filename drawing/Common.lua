local M = {}

local Util = require 'Util'
local Arc = require 'Arc'
local Text = require 'Text'
local CriticalText = require 'CriticalText'
local TextColumn = require 'TextColumn'
local Line = require 'Line'
local LabelPlot = require 'LabelPlot'
local ScalePlot = require 'ScalePlot'

local HEADER_HEIGHT = 45
local HEADER_FONT_SIZE = 15
-- TODO move all this font stuff to the theme file
local HEADER_UNDERLINE_CAP = CAIRO_LINE_CAP_ROUND
local HEADER_UNDERLINE_OFFSET = -20
local HEADER_UNDERLINE_THICKNESS = 3

M.make_font_spec = function(f, s, bold)
   return {
      family = f,
      size = s,
      weight = bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL,
      slant = CAIRO_FONT_WEIGHT_NORMAL,
   }
end

M.normal_font_spec = M.make_font_spec(_G_Patterns_.FONT, 13, false)
M.label_font_spec = M.make_font_spec(_G_Patterns_.FONT, 8, false)

M.left_text_style = _G_Widget_.text_style(
   M.normal_font_spec,
   _G_Patterns_.INACTIVE_TEXT_FG,
   'left',
   'center'
)

M.right_text_style = _G_Widget_.text_style(
   M.normal_font_spec,
   _G_Patterns_.PRIMARY_FG,
   'right',
   'center'
)

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
   -- TODO what's the point of bottom_y?
   local bottom_y = y + HEADER_HEIGHT
   local underline_y = bottom_y + HEADER_UNDERLINE_OFFSET

   local obj = {
      text = _G_Widget_.plainText(
         _G_Widget_.make_point(x, y),
         s,
         _G_Widget_.text_style(
            M.make_font_spec(_G_Patterns_.FONT, HEADER_FONT_SIZE, true),
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

   return obj
end

M.drawHeader = function(cr, header)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)
end

--------------------------------------------------------------------------------
-- label plot

M.default_grid_style = _G_Widget_.grid_style(9, 4, _G_Patterns_.BORDER_FG)

M.default_plot_style = _G_Widget_.plot_style(
   90,
   _G_Patterns_.BORDER_FG,
   _G_Patterns_.PLOT_FILL_BORDER_PRIMARY,
   _G_Patterns_.PLOT_FILL_BG_PRIMARY,
   M.default_grid_style
)

M.percent_label_style = _G_Widget_.label_style(
   _G_Patterns_.INACTIVE_TEXT_FG,
   M.label_font_spec,
   function(z) return Util.round_to_string(z * 100)..'%' end,
   1
)

M.initThemedLabelPlot = function(x, y, w, h, label_style)
   return _G_Widget_.LabelPlot(
      _G_Widget_.make_box(_G_Widget_.make_point(x, y), w, h),
      M.default_plot_style,
      label_style
   )
end

--------------------------------------------------------------------------------
-- percent plot (label plot with percent signs and some indicator data above it)

M.initPercentPlot = function(x, y, w, h, spacing, label)
   return {
      label = _left_text(_G_Widget_.make_point(x, y), label),
      value = _G_Widget_.formattedThresholdText(
         _G_Widget_.make_point(x + w, y),
         nil,
         M.right_text_style,
         '%s%%',
         _G_Widget_.threshold_text_style(
            _G_Patterns_.CRITICAL_FG,
            80
         )
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

M.percent_plot_draw_static = function(pp, cr)
   Text.draw(pp.label, cr)
   LabelPlot.draw_static(pp.plot, cr)
end

M.percent_plot_draw_dynamic = function(pp, cr)
   CriticalText.draw(pp.value, cr)
   LabelPlot.draw_dynamic(pp.plot, cr)
end

M.percent_plot_set = function(pp, cr, value)
   Text.set(pp.value, cr, math.floor(value))
   LabelPlot.update(pp.plot, value * 0.01)
end

--------------------------------------------------------------------------------
-- scaled plot

M.base_2_scale_data = _G_Widget_.scale_data(2, 1, 0.9)

M.initThemedScalePlot = function(x, y, w, h, f)
   return _G_Widget_.ScalePlot(
      _G_Widget_.make_box(_G_Widget_.make_point(x, y), w, h),
      M.default_plot_style,
      _G_Widget_.label_style(
         _G_Patterns_.INACTIVE_TEXT_FG,
         M.label_font_spec,
         f,
         1
      ),
      M.base_2_scale_data
   )
end

--------------------------------------------------------------------------------
-- scaled plot (with textual data above it)

M.initLabeledScalePlot = function(x, y, w, h, f, spacing, label)
   return {
      label = _left_text(
         _G_Widget_.make_point(x, y),
         label
      ),
      value = _right_text(
         _G_Widget_.make_point(x + w, y),
         label
      ),
      plot = M.initThemedScalePlot(x, y + spacing, w, h, f),
   }
end

M.annotated_scale_plot_draw_static = function(asp, cr)
   Text.draw(asp.label, cr)
end

M.annotated_scale_plot_draw_dynamic = function(asp, cr)
   Text.draw(asp.value, cr)
   ScalePlot.draw_dynamic(asp.plot, cr)
end

M.annotated_scale_plot_set = function(asp, cr, text_value, plot_value)
   -- TODO this could be made more intelligent
   Text.set(asp.value, cr, text_value)
   ScalePlot.update(asp.plot, cr, plot_value)
end

--------------------------------------------------------------------------------
-- ring

M.initRing = function(x, y, r)
   return _G_Widget_.Arc(
      _G_Widget_.make_semicircle(
         _G_Widget_.make_point(x, y),
         r,
         0,
         360
      ),
      _G_Widget_.arc_style(
         2,
         _G_Patterns_.BORDER_FG
      )
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
         _G_Widget_.threshold_text_style(
            _G_Patterns_.CRITICAL_FG,
            limit
         )
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
-- separator (eg a horizontal line)

M.initSeparator = function(x, y, w)
   return _G_Widget_.Line(
      _G_Widget_.make_point(x, y),
      _G_Widget_.make_point(x + w, y),
      _G_Widget_.line_style(
         1,
         _G_Patterns_.BORDER_FG,
         CAIRO_LINE_CAP_BUTT
      )
   )
end

--------------------------------------------------------------------------------
-- text row (label with a value, aligned as far apart as possible)


M.initTextRow = function(x, y, w, label)
   return {
      label = _left_text(
         _G_Widget_.make_point(x, y),
         label
      ),
      value = _right_text(
         _G_Widget_.make_point(x + w, y),
         nil
      ),
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

-- TODO add limit to this
M.initTextRowCrit = function(x, y, w, label, append_end, limit)
   return{
      label = _left_text(
         _G_Widget_.make_point(x, y),
         label
      ),
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
         _G_Widget_.threshold_text_style(
            _G_Patterns_.CRITICAL_FG,
            limit
         )
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
-- multiple text row separated by spacing

M.initTextRows = function(x, y, w, spacing, labels)
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
         M.right_text_style,
         nil,
         spacing
      )
   }
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

M.default_table_font_spec = M.make_font_spec(_G_Patterns_.FONT, 11, false)

M.default_table_style = _G_Widget_.table_style(
   _G_Widget_.rect_style(
      1,
      _G_Patterns_.BORDER_FG
   ),
   _G_Widget_.line_style(
      1,
      _G_Patterns_.BORDER_FG,
      CAIRO_LINE_CAP_BUTT
   ),
   _G_Widget_.table_header_style(
      M.default_table_font_spec,
      _G_Patterns_.PRIMARY_FG,
      20
   ),
   _G_Widget_.table_body_style(
      M.default_table_font_spec,
      _G_Patterns_.INACTIVE_TEXT_FG,
      8
   ),
   _G_Widget_.padding(5, 15, 5, 15)
)

M.initTable = function(x, y, w, h, n, labels)
   return _G_Widget_.Table(
      _G_Widget_.make_box(_G_Widget_.make_point(x, y), w, h),
      n,
      labels,
      M.default_table_style
   )
end

--------------------------------------------------------------------------------
-- panel

M.initPanel = function(x, y, w, h, thickness)
   return _G_Widget_.FillRect(
      _G_Widget_.make_box(
         _G_Widget_.make_point(x, y),
         w,
         h
      ),
      _G_Widget_.rect_style(
         thickness,
         _G_Patterns_.BORDER_FG
      ),
      _G_Patterns_.PANEL_BG
   )
end

return M
