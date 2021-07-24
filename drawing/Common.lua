local M = {}

local F = require 'Fundamental'
local Util = require 'Util'
local Theme = require 'Theme'
local Dial = require 'Dial'
local Rect = require 'Rect'
local FillRect = require 'FillRect'
local CompoundDial = require 'CompoundDial'
local Arc = require 'Arc'
local Text = require 'Text'
local Table = require 'Table'
local CompoundBar = require 'CompoundBar'
local ThresholdText = require 'ThresholdText'
local TextColumn = require 'TextColumn'
local Line = require 'Line'
local Timeseries = require 'Timeseries'
local ScaledTimeseries = require 'ScaledTimeseries'
local s = require 'style'

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
   return Text.style(M.normal_font_spec, color, x_align, 'center')
end

M.left_text_style = _text_row_style('left', Theme.INACTIVE_TEXT_FG)

M.right_text_style = _text_row_style('right', Theme.PRIMARY_FG)

local _bare_text = function(pt, text, style)
   return Text.build_plain(pt, text, style)
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
      text = Text.build_plain(
         F.make_point(x, y),
         s,
         Text.style(
            M.make_font_spec(FONT, HEADER_FONT_SIZE, true),
            Theme.HEADER_FG,
            'left',
            'top'
         )
      ),
      bottom_y = bottom_y,
      underline = Line.build(
         F.make_point(x, underline_y),
         F.make_point(x + w, underline_y),
         Line.style(
            HEADER_UNDERLINE_THICKNESS,
            Theme.HEADER_FG,
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

M.default_grid_config = Timeseries.grid_config(
   PLOT_GRID_X_N,
   PLOT_GRID_Y_N,
   Theme.PLOT_GRID_FG
)

M.default_plot_style = Timeseries.config(
   PLOT_NUM_POINTS,
   Theme.PLOT_OUTLINE_FG,
   Theme.PLOT_FILL_BORDER_PRIMARY,
   Theme.PLOT_FILL_BG_PRIMARY,
   M.default_grid_config
)

M.percent_label_config = Timeseries.label_config(
   Theme.INACTIVE_TEXT_FG,
   M.label_font_spec,
   function(_) return function(z) return Util.round_to_string(z * 100)..'%' end end
)

M.initThemedLabelPlot = function(x, y, w, h, label_config, update_freq)
   return Timeseries.build(
      F.make_box(x, y, w, h),
      update_freq,
      M.default_plot_style,
      label_config
   )
end

--------------------------------------------------------------------------------
-- percent plot (label plot with percent signs and some indicator data above it)

M.initPercentPlot_formatted = function(x, y, w, h, spacing, label, update_freq, format)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = ThresholdText.build_formatted(
         F.make_point(x + w, y),
         nil,
         M.right_text_style,
         format,
         ThresholdText.style(Theme.CRITICAL_FG, 80)
      ),
      plot = M.initThemedLabelPlot(
         x,
         y + spacing,
         w,
         h,
         M.percent_label_config,
         update_freq
      ),
   }
end

M.initPercentPlot = function(x, y, w, h, spacing, label, update_freq)
   return M.initPercentPlot_formatted(x, y, w, h, spacing, label, update_freq, '%s%%')
end

M.percent_plot_draw_static = function(pp, cr)
   Text.draw(pp.label, cr)
   Timeseries.draw_static(pp.plot, cr)
end

M.percent_plot_draw_dynamic = function(pp, cr)
   ThresholdText.draw(pp.value, cr)
   Timeseries.draw_dynamic(pp.plot, cr)
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
   Text.set(pp.value, t)
   Timeseries.update(pp.plot, p)
end

--------------------------------------------------------------------------------
-- scaled plot

-- Generate a format string for labels on y axis of plots. If the max of the
-- plot if numerically less than the number of grid lines, this means that
-- some number of decimal places are necessary to accurately display the number.
-- Note that this for now only works when the number of y grid lines if 4, as
-- it gives enough resolution for 1, 0.75, 0.5, and 0.25 but no more
M.y_label_format_string = function(plot_max, unit)
   local num_fmt
   if plot_max < 2 then
      num_fmt = '%.2f'
   elseif plot_max < 4 then
      num_fmt = '%.1f'
   else
      num_fmt = '%.0f'
   end
   return string.format('%s %s', num_fmt, unit)
end

M.converted_y_label_format_generator = function(unit)
   return function(plot_max)
      local new_prefix, new_max = Util.convert_data_val(plot_max)
      local conversion_factor = plot_max / new_max
      local fmt = M.y_label_format_string(new_max, new_prefix..unit..'/s')
      return function(bytes)
         return string.format(fmt, bytes / conversion_factor)
      end
   end
end

M.base_2_scale_data = function(m)
   return ScaledTimeseries.scaling_parameters(2, m, 0.9)
end

M.initThemedScalePlot = function(x, y, w, h, f, min_domain, update_freq)
   return ScaledTimeseries.build(
      F.make_box(x, y, w, h),
      update_freq,
      M.default_plot_style,
      Timeseries.label_config(
         Theme.INACTIVE_TEXT_FG,
         M.label_font_spec,
         f
      ),
      M.base_2_scale_data(min_domain)
   )
end

--------------------------------------------------------------------------------
-- scaled plot (with textual data above it)

M.initLabeledScalePlot = function(x, y, w, h, format_fun, label_fun, spacing,
                                  label, min_domain, update_freq)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = Text.build_formatted(
         F.make_point(x + w, y),
         0,
         M.right_text_style,
         format_fun
      ),
      plot = M.initThemedScalePlot(x, y + spacing, w, h, label_fun, min_domain, update_freq),
   }
end

M.annotated_scale_plot_draw_static = function(asp, cr)
   Text.draw(asp.label, cr)
end

M.annotated_scale_plot_draw_dynamic = function(asp, cr)
   Text.draw(asp.value, cr)
   ScaledTimeseries.draw_dynamic(asp.plot, cr)
end

M.annotated_scale_plot_set = function(asp, cr, value)
   Text.set(asp.value, value)
   ScaledTimeseries.update(asp.plot, value)
end

--------------------------------------------------------------------------------
-- rate timecourse plots

M.compute_derivative = function(x0, x1, update_frequency)
   -- mask overflow
   if x1 > x0 then
      return (x1 - x0) * update_frequency
   else
      return 0
   end
end

local build_differential = function(update_frequency)
   return function(x0, x1)
      -- mask overflow
      if x1 > x0 then
         return (x1 - x0) * update_frequency
      else
         return 0
      end
   end
end

M.build_rate_timeseries = function(x, y, w, h, format_fun, label_fun, spacing,
                                   label, min_domain, update_freq, init)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = Text.build_formatted(
         F.make_point(x + w, y),
         0,
         M.right_text_style,
         format_fun
      ),
      plot = M.initThemedScalePlot(x, y + spacing, w, h, label_fun, min_domain, update_freq),
      prev_value = init,
      derive = build_differential(update_freq),
   }
end

M.update_rate_timeseries = function(obj, cr, value)
   local rate = obj.derive(obj.prev_value, value)
   Text.set(obj.value, rate)
   ScaledTimeseries.update(obj.plot, rate)
   obj.prev_value = value
end

--------------------------------------------------------------------------------
-- arc (TODO this is just a dummy now to make everything organized

-- TODO perhaps implement this is a special case of compound dial where
-- I have multiple layers on top of each other

M.arc = function(x, y, r, thickness, pattern)
   return Arc.build(
      F.make_semicircle(x, y, r, 90, 360),
      Arc.config(s.line(thickness, CAIRO_LINE_CAP_BUTT), pattern)
   )
end

--------------------------------------------------------------------------------
-- ring

M.initRing = function(x, y, r)
   return Arc.build(
      F.make_semicircle(x, y, r, 0, 360),
      Arc.config(s.line(ARC_WIDTH, CAIRO_LINE_CAP_BUTT), Theme.BORDER_FG)
   )
end

--------------------------------------------------------------------------------
-- ring with text data in the center

M.initTextRing = function(x, y, r, fmt, limit)
   return {
	  ring = M.initRing(x, y, r),
	  value = ThresholdText.build_formatted(
         F.make_point(x, y),
         0,
         Text.style(
            M.normal_font_spec,
            Theme.PRIMARY_FG,
            'center',
            'center'
         ),
         fmt,
         ThresholdText.style(Theme.CRITICAL_FG, limit)
	  ),
   }
end

M.text_ring_draw_static = function(tr, cr)
   Arc.draw(tr.ring, cr)
end

M.text_ring_draw_dynamic = function(tr, cr)
   ThresholdText.draw(tr.value, cr)
end

M.text_ring_set = function(tr, cr, value)
   ThresholdText.set(tr.value, value)
end

--------------------------------------------------------------------------------
-- dial

local threshold_indicator = function(threshold)
   return F.threshold_style(
      Theme.INDICATOR_FG_PRIMARY,
      Theme.INDICATOR_FG_CRITICAL,
      threshold
   )
end

M.dial = function(x, y, radius, thickness, threshold, format)
   return {
      dial = Dial.build(
         F.make_semicircle(x, y, radius, DIAL_THETA0, DIAL_THETA1),
         Arc.config(s.line(thickness, CAIRO_LINE_CAP_BUTT), Theme.INDICATOR_BG),
         threshold_indicator(threshold)
      ),
      text_ring = M.initTextRing(x, y, radius - thickness / 2 - 2, format, threshold),
   }
end

M.dial_set = function(dl, cr, value)
   Dial.set(dl.dial, value)
   M.text_ring_set(dl.text_ring, cr, value)
end

M.dial_draw_static = function(dl, cr)
   Dial.draw_static(dl.dial, cr)
   M.text_ring_draw_static(dl.text_ring, cr)
end

M.dial_draw_dynamic = function(dl, cr)
   Dial.draw_dynamic(dl.dial, cr)
   M.text_ring_draw_dynamic(dl.text_ring, cr)
end

--------------------------------------------------------------------------------
-- compound dial

M.compound_dial = function(x, y, outer_radius, inner_radius, thickness,
                           threshold, num_dials)
   return CompoundDial.build(
      F.make_semicircle(x, y, outer_radius, DIAL_THETA0, DIAL_THETA1),
      Arc.config(s.line(thickness, CAIRO_LINE_CAP_BUTT), Theme.INDICATOR_BG),
      threshold_indicator(threshold),
      inner_radius,
      num_dials
   )
end

--------------------------------------------------------------------------------
-- annotated compound bar

M.compound_bar = function(x, y, w, pad, labels, spacing, thickness, threshold)
   return {
      labels = TextColumn.build(
         F.make_point(x, y),
         labels,
         M.left_text_style,
         nil,
         spacing
      ),
      bars = CompoundBar.build(
         F.make_point(x + pad, y),
         w - pad,
         Line.style(
            thickness,
            Theme.INDICATOR_BG,
            CAIRO_LINE_JOIN_MITER,
            true
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
   return Line.build(
      F.make_point(x, y),
      F.make_point(x + w, y),
      Line.style(
         SEPARATOR_THICKNESS,
         Theme.BORDER_FG,
         CAIRO_LINE_CAP_BUTT
      )
   )
end

--------------------------------------------------------------------------------
-- text row (label with a value, aligned as far apart as possible)

M.initTextRow = function(x, y, w, label)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = _right_text(F.make_point(x + w, y), nil),
   }
end

M.text_row_draw_static = function(row, cr)
   Text.draw(row.label, cr)
end

M.text_row_draw_dynamic = function(row, cr)
   Text.draw(row.value, cr)
end

M.text_row_set = function(row, cr, value)
   Text.set(row.value, value)
end

--------------------------------------------------------------------------------
-- text row with critical indicator

M.initTextRowCrit = function(x, y, w, label, append_end, limit)
   return{
      label = _left_text(F.make_point(x, y), label),
      value = ThresholdText.build_formatted(
         F.make_point(x + w, y),
         nil,
         Text.style(
            M.normal_font_spec,
            Theme.PRIMARY_FG,
            'right',
            'center'
         ),
         append_end,
         ThresholdText.style(Theme.CRITICAL_FG, limit)
      )
   }
end

M.text_row_crit_draw_static = M.text_row_draw_static

M.text_row_crit_draw_dynamic = function(row, cr)
   ThresholdText.draw(row.value, cr)
end

M.text_row_crit_set = function(row, cr, value)
   ThresholdText.set(row.value, value)
end

--------------------------------------------------------------------------------
-- text column

M.text_column = function(x, y, spacing, labels, x_align, color)
   return TextColumn.build(
      F.make_point(x, y),
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
      labels = TextColumn.build(
         F.make_point(x, y),
         labels,
         M.left_text_style,
         nil,
         spacing
      ),
      values = TextColumn.build_n(
         F.make_point(x + w, y),
         #labels,
         _text_row_style('right', color),
         format,
         spacing,
         0
      )
   }
end

M.initTextRows_formatted = function(x, y, w, spacing, labels, format)
   return M.initTextRows_color(
      x,
      y,
      w,
      spacing,
      labels,
      Theme.PRIMARY_FG,
      format
   )
end

M.initTextRows = function(x, y, w, spacing, labels)
   return M.initTextRows_formatted(
      x,
      y,
      w,
      spacing,
      labels,
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
   TextColumn.set(rows.values, i, value)
end

--------------------------------------------------------------------------------
-- table

M.default_table_font_spec = M.make_font_spec(FONT, TABLE_FONT_SIZE, false)

M.default_table_style = Table.style(
   Rect.config(
      s.closed_poly(TABLE_LINE_THICKNESS, CAIRO_LINE_JOIN_MITER),
      Theme.BORDER_FG
   ),
   Line.style(
      TABLE_LINE_THICKNESS,
      Theme.BORDER_FG,
      CAIRO_LINE_CAP_BUTT
   ),
   Table.header_style(
      M.default_table_font_spec,
      Theme.PRIMARY_FG,
      TABLE_HEADER_PAD
   ),
   Table.body_style(
      M.default_table_font_spec,
      Theme.INACTIVE_TEXT_FG,
      TABLE_BODY_FORMAT
   ),
   F.padding(
      TABLE_HORZ_PAD,
      TABLE_VERT_PAD,
      TABLE_HORZ_PAD,
      TABLE_VERT_PAD
   )
)

M.initTable = function(x, y, w, h, n, labels)
   return Table.build(
      F.make_box(x, y, w, h),
      n,
      labels,
      M.default_table_style
   )
end

--------------------------------------------------------------------------------
-- panel

M.initPanel = function(x, y, w, h, thickness)
   return FillRect.build(
      F.make_box(x, y, w, h),
      Rect.config(
         s.closed_poly(thickness, CAIRO_LINE_JOIN_MITER),
         Theme.BORDER_FG
      ),
      Theme.PANEL_BG
   )
end

return M
