local M = {}

local F = require 'primitive'
local util = require 'util'
local theme = require 'theme'
local dial = require 'dial'
local rect = require 'rect'
local fillrect = require 'fillrect'
local compounddial = require 'compounddial'
local arc = require 'arc'
local text = require 'text'
local tbl = require 'texttable'
local compoundbar = require 'compoundbar'
local thresholdtext = require 'thresholdtext'
local textcolumn = require 'textcolumn'
local line = require 'line'
local timeseries = require 'timeseries'
local scaledtimeseries = require 'scaledtimeseries'
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
-- text helper functions

local make_font_spec = function(f, size, bold)
   return {
      family = f,
      size = size,
      weight = bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL,
      slant = CAIRO_FONT_WEIGHT_NORMAL,
   }
end

local normal_font_spec = make_font_spec(FONT, NORMAL_FONT_SIZE, false)
local label_font_spec = make_font_spec(FONT, PLOT_LABEL_FONT_SIZE, false)

local _text_row_style = function(x_align, color)
   return text.style(normal_font_spec, color, x_align, 'center')
end

local _left_text_style = _text_row_style('left', theme.INACTIVE_TEXT_FG)
local _right_text_style = _text_row_style('right', theme.PRIMARY_FG)

local _bare_text = function(pt, _text, style)
   return text.make_plain(pt, _text, style)
end

local _left_text = function(pt, _text)
   return _bare_text(pt, _text, _left_text_style)
end

local _right_text = function(pt, _text)
   return _bare_text(pt, _text, _right_text_style)
end

--------------------------------------------------------------------------------
-- timeseries helper functions

local _default_grid_config = timeseries.grid_config(
   PLOT_GRID_X_N,
   PLOT_GRID_Y_N,
   theme.PLOT_GRID_FG
)

local _default_plot_config = timeseries.config(
   PLOT_NUM_POINTS,
   theme.PLOT_OUTLINE_FG,
   theme.PLOT_FILL_BORDER_PRIMARY,
   theme.PLOT_FILL_BG_PRIMARY,
   _default_grid_config
)

local _format_percent_label = function(_)
   return function(z) return util.round_to_string(z * 100)..'%' end
end

local _format_percent_maybe = function(z)
   if z == false then return 'N/A' else return string.format('%s%%', z) end
end

local _percent_label_config = timeseries.label_config(
   theme.INACTIVE_TEXT_FG,
   label_font_spec,
   _format_percent_label
)

local _make_timeseries = function(x, y, w, h, label_config, update_freq)
   return timeseries.make(
      F.make_box(x, y, w, h),
      update_freq,
      _default_plot_config,
      label_config
   )
end

local _make_tagged_percent_timeseries = function(x, y, w, h, spacing, label, update_freq, format)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = thresholdtext.make_formatted(
         F.make_point(x + w, y),
         nil,
         _right_text_style,
         format,
         thresholdtext.style(theme.CRITICAL_FG, 80)
      ),
      plot = M.make_percent_timeseries(
         x,
         y + spacing,
         w,
         h,
         update_freq
      ),
   }
end

--------------------------------------------------------------------------------
-- scaled timeseries helper functions

local _base_2_scale_data = function(m)
   return scaledtimeseries.scaling_parameters(2, m, 0.9)
end

local _make_scaled_timeseries = function(x, y, w, h, f, min_domain, update_freq)
   return scaledtimeseries.make(
      F.make_box(x, y, w, h),
      update_freq,
      _default_plot_config,
      timeseries.label_config(theme.INACTIVE_TEXT_FG, label_font_spec, f),
      _base_2_scale_data(min_domain)
   )
end

--------------------------------------------------------------------------------
-- header

M.make_header = function(x, y, w, _text)
   local bottom_y = y + HEADER_HEIGHT
   local underline_y = y + HEADER_UNDERLINE_OFFSET
   return {
      text = text.make_plain(
         F.make_point(x, y),
         _text,
         text.style(
            make_font_spec(FONT, HEADER_FONT_SIZE, true),
            theme.HEADER_FG,
            'left',
            'top'
         )
      ),
      bottom_y = bottom_y,
      underline = line.make(
         F.make_point(x, underline_y),
         F.make_point(x + w, underline_y),
         line.config(
            s.line(HEADER_UNDERLINE_THICKNESS, HEADER_UNDERLINE_CAP),
            theme.HEADER_FG,
            true
         )
      )
   }
end

M.draw_header = function(cr, header)
   text.draw(header.text, cr)
   line.draw(header.underline, cr)
end

--------------------------------------------------------------------------------
-- percent timeseries

M.make_percent_timeseries = function(x, y, w, h, update_freq)
   return _make_timeseries(x, y, w, h, _percent_label_config, update_freq)
end

--------------------------------------------------------------------------------
-- tagged percent timeseries

M.make_tagged_percent_timeseries = function(x, y, w, h, spacing, label, update_freq)
   return _make_tagged_percent_timeseries(
      x, y, w, h, spacing, label, update_freq, '%s%%'
   )
end

M.make_tagged_maybe_percent_timeseries = function(x, y, w, h, spacing, label, update_freq)
   return _make_tagged_percent_timeseries(
      x, y, w, h, spacing, label, update_freq, _format_percent_maybe
   )
end

M.tagged_percent_timeseries_draw_static = function(pp, cr)
   text.draw(pp.label, cr)
   timeseries.draw_static(pp.plot, cr)
end

M.tagged_percent_timeseries_draw_dynamic = function(obj, cr)
   thresholdtext.draw(obj.value, cr)
   timeseries.draw_dynamic(obj.plot, cr)
end

M.tagged_percent_timeseries_set = function(obj, value)
   text.set(obj.value, math.floor(value))
   timeseries.update(obj.plot, value * 0.01)
end

M.tagged_maybe_percent_timeseries_set = function(obj, value)
   if value == false then
      text.set(obj.value, false)
      timeseries.update(obj.plot, 0)
   else
      M.tagged_percent_timeseries_set(obj, value)
   end
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
      local new_prefix, new_max = util.convert_data_val(plot_max)
      local conversion_factor = plot_max / new_max
      local fmt = M.y_label_format_string(new_max, new_prefix..unit..'/s')
      return function(bytes)
         return string.format(fmt, bytes / conversion_factor)
      end
   end
end

--------------------------------------------------------------------------------
-- tagged scaled plot

M.make_tagged_scaled_timeseries = function(x, y, w, h, format_fun, label_fun,
                                           spacing, label, min_domain,
                                           update_freq)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = text.make_formatted(
         F.make_point(x + w, y),
         0,
         _right_text_style,
         format_fun
      ),
      plot = _make_scaled_timeseries(x, y + spacing, w, h, label_fun, min_domain, update_freq),
   }
end

M.tagged_scaled_timeseries_draw_static = function(asp, cr)
   text.draw(asp.label, cr)
end

M.tagged_scaled_timeseries_draw_dynamic = function(asp, cr)
   text.draw(asp.value, cr)
   scaledtimeseries.draw_dynamic(asp.plot, cr)
end

M.tagged_scaled_timeseries_set = function(asp, value)
   text.set(asp.value, value)
   scaledtimeseries.update(asp.plot, value)
end

--------------------------------------------------------------------------------
-- rate timecourse plots

local make_differential = function(update_frequency)
   return function(x0, x1)
      -- mask overflow
      if x1 > x0 then
         return (x1 - x0) * update_frequency
      else
         return 0
      end
   end
end

M.make_rate_timeseries = function(x, y, w, h, format_fun, label_fun, spacing,
                                   label, min_domain, update_freq, init)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = text.make_formatted(
         F.make_point(x + w, y),
         0,
         _right_text_style,
         format_fun
      ),
      plot = _make_scaled_timeseries(x, y + spacing, w, h, label_fun, min_domain, update_freq),
      prev_value = init,
      derive = make_differential(update_freq),
   }
end

M.update_rate_timeseries = function(obj, value)
   local rate = obj.derive(obj.prev_value, value)
   text.set(obj.value, rate)
   scaledtimeseries.update(obj.plot, rate)
   obj.prev_value = value
end

--------------------------------------------------------------------------------
-- circle

M.make_circle = function(x, y, r)
   return arc.make(
      F.make_semicircle(x, y, r, 0, 360),
      arc.config(s.line(ARC_WIDTH, CAIRO_LINE_CAP_BUTT), theme.BORDER_FG)
   )
end

--------------------------------------------------------------------------------
-- ring with text data in the center

M.make_text_circle = function(x, y, r, fmt, limit)
   return {
	  ring = M.make_circle(x, y, r),
	  value = thresholdtext.make_formatted(
         F.make_point(x, y),
         0,
         text.style(normal_font_spec, theme.PRIMARY_FG, 'center', 'center'),
         fmt,
         thresholdtext.style(theme.CRITICAL_FG, limit)
	  ),
   }
end

M.text_circle_draw_static = function(tr, cr)
   arc.draw(tr.ring, cr)
end

M.text_circle_draw_dynamic = function(tr, cr)
   thresholdtext.draw(tr.value, cr)
end

M.text_circle_set = function(tr, value)
   thresholdtext.set(tr.value, value)
end

--------------------------------------------------------------------------------
-- dial

local threshold_indicator = function(threshold)
   return F.threshold_style(
      theme.INDICATOR_FG_PRIMARY,
      theme.INDICATOR_FG_CRITICAL,
      threshold
   )
end

M.make_dial = function(x, y, radius, thickness, threshold, format)
   return {
      dial = dial.make(
         F.make_semicircle(x, y, radius, DIAL_THETA0, DIAL_THETA1),
         arc.config(s.line(thickness, CAIRO_LINE_CAP_BUTT), theme.INDICATOR_BG),
         threshold_indicator(threshold)
      ),
      text_circle = M.make_text_circle(x, y, radius - thickness / 2 - 2, format, threshold),
   }
end

M.dial_set = function(dl, value)
   dial.set(dl.dial, value)
   M.text_circle_set(dl.text_circle, value)
end

M.dial_draw_static = function(dl, cr)
   dial.draw_static(dl.dial, cr)
   M.text_circle_draw_static(dl.text_circle, cr)
end

M.dial_draw_dynamic = function(dl, cr)
   dial.draw_dynamic(dl.dial, cr)
   M.text_circle_draw_dynamic(dl.text_circle, cr)
end

--------------------------------------------------------------------------------
-- compound dial

M.make_compound_dial = function(x, y, outer_radius, inner_radius, thickness,
                           threshold, num_dials)
   return compounddial.make(
      F.make_semicircle(x, y, outer_radius, DIAL_THETA0, DIAL_THETA1),
      arc.config(s.line(thickness, CAIRO_LINE_CAP_BUTT), theme.INDICATOR_BG),
      threshold_indicator(threshold),
      inner_radius,
      num_dials
   )
end

--------------------------------------------------------------------------------
-- annotated compound bar

M.make_compound_bar = function(x, y, w, pad, labels, spacing, thickness, threshold)
   return {
      labels = textcolumn.make(
         F.make_point(x, y),
         labels,
         _left_text_style,
         nil,
         spacing
      ),
      bars = compoundbar.make(
         F.make_point(x + pad, y),
         w - pad,
         line.config(
            s.line(thickness, CAIRO_LINE_CAP_BUTT),
            theme.INDICATOR_BG,
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
   textcolumn.draw(cb.labels, cr)
   compoundbar.draw_static(cb.bars, cr)
end

M.compound_bar_draw_dynamic = function(cb, cr)
   compoundbar.draw_dynamic(cb.bars, cr)
end

M.compound_bar_set = function(cb, i, value)
   compoundbar.set(cb.bars, i, value)
end

--------------------------------------------------------------------------------
-- separator (eg a horizontal line)

M.make_separator = function(x, y, w)
   return line.make(
      F.make_point(x, y),
      F.make_point(x + w, y),
      line.config(
         s.line(SEPARATOR_THICKNESS, CAIRO_LINE_CAP_BUTT),
         theme.BORDER_FG,
         true
      )
   )
end

--------------------------------------------------------------------------------
-- text row (label with a value, aligned as far apart as possible)

M.make_text_row = function(x, y, w, label)
   return {
      label = _left_text(F.make_point(x, y), label),
      value = _right_text(F.make_point(x + w, y), nil),
   }
end

M.text_row_draw_static = function(row, cr)
   text.draw(row.label, cr)
end

M.text_row_draw_dynamic = function(row, cr)
   text.draw(row.value, cr)
end

M.text_row_set = function(row, value)
   text.set(row.value, value)
end

--------------------------------------------------------------------------------
-- text row with critical indicator

M.make_threshold_text_row = function(x, y, w, label, append_end, limit)
   return{
      label = _left_text(F.make_point(x, y), label),
      value = thresholdtext.make_formatted(
         F.make_point(x + w, y),
         nil,
         _right_text_style,
         append_end,
         thresholdtext.style(theme.CRITICAL_FG, limit)
      )
   }
end

M.threshold_text_row_draw_static = M.text_row_draw_static

M.threshold_text_row_draw_dynamic = function(row, cr)
   thresholdtext.draw(row.value, cr)
end

M.threshold_text_row_set = function(row, value)
   thresholdtext.set(row.value, value)
end

--------------------------------------------------------------------------------
-- multiple text row separated by spacing

M.make_text_rows_formatted = function(x, y, w, spacing, labels, format)
   return {
      labels = textcolumn.make(
         F.make_point(x, y),
         labels,
         _left_text_style,
         nil,
         spacing
      ),
      values = textcolumn.make_n(
         F.make_point(x + w, y),
         #labels,
         _right_text_style,
         format,
         spacing,
         0
      )
   }
end

M.make_text_rows = function(x, y, w, spacing, labels)
   return M.make_text_rows_formatted(
      x,
      y,
      w,
      spacing,
      labels,
      nil
   )
end

M.text_rows_draw_static = function(rows, cr)
   textcolumn.draw(rows.labels, cr)
end

M.text_rows_draw_dynamic = function(rows, cr)
   textcolumn.draw(rows.values, cr)
end

M.text_rows_set = function(rows, i, value)
   textcolumn.set(rows.values, i, value)
end

--------------------------------------------------------------------------------
-- table

local default_table_font_spec = make_font_spec(FONT, TABLE_FONT_SIZE, false)

local default_table_style = tbl.style(
   rect.config(
      s.closed_poly(TABLE_LINE_THICKNESS, CAIRO_LINE_JOIN_MITER),
      theme.BORDER_FG
   ),
   line.config(
      s.line(TABLE_LINE_THICKNESS, CAIRO_LINE_CAP_BUTT),
      theme.BORDER_FG,
      true
   ),
   tbl.header_config(
      default_table_font_spec,
      theme.PRIMARY_FG,
      TABLE_HEADER_PAD
   ),
   tbl.body_config(
      default_table_font_spec,
      theme.INACTIVE_TEXT_FG,
      TABLE_BODY_FORMAT
   ),
   F.padding(
      TABLE_HORZ_PAD,
      TABLE_VERT_PAD,
      TABLE_HORZ_PAD,
      TABLE_VERT_PAD
   )
)

M.make_text_table = function(x, y, w, h, n, labels)
   return tbl.make(
      F.make_box(x, y, w, h),
      n,
      labels,
      default_table_style
   )
end

--------------------------------------------------------------------------------
-- panel

M.make_panel = function(x, y, w, h, thickness)
   return fillrect.make(
      F.make_box(x, y, w, h),
      rect.config(
         s.closed_poly(thickness, CAIRO_LINE_JOIN_MITER),
         theme.BORDER_FG
      ),
      theme.PANEL_BG
   )
end

return M
