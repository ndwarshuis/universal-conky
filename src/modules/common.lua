local geom = require 'geom'
local format = require 'format'
local color = require 'color'
local dial = require 'dial'
local rect = require 'rect'
local fill_rect = require 'fill_rect'
local compound_dial = require 'compound_dial'
local arc = require 'arc'
local circle = require 'circle'
local text = require 'text'
local tbl = require 'text_table'
local compound_bar = require 'compound_bar'
local text_threshold = require 'text_threshold'
local text_column = require 'text_column'
local line = require 'line'
local timeseries = require 'timeseries'
local scaled_timeseries = require 'scaled_timeseries'
local style = require 'style'
local source = require 'source'
local pure = require 'pure'

return function(config)
   local M = {}

   local patterns = color(config.theme.patterns)
   local font = config.theme.font
   local font_sizes = font.sizes
   local font_family = font.family
   local geometry = config.theme.geometry

   -----------------------------------------------------------------------------
   -- constants

   local CAP_ROUND = CAIRO_LINE_CAP_ROUND
   local CAP_BUTT = CAIRO_LINE_CAP_BUTT
   local JOIN_MITER = CAIRO_LINE_JOIN_MITER

   local FONT_BOLD = CAIRO_FONT_WEIGHT_BOLD
   local FONT_NORMAL = CAIRO_FONT_WEIGHT_NORMAL

   local HEADER_UNDERLINE_CAP = CAP_ROUND
   local HEADER_UNDERLINE_THICKNESS = 3

   local SEPARATOR_THICKNESS = 1
   local TABLE_LINE_THICKNESS = 1

   local ARC_WIDTH = 2

   local DIAL_THETA0 = 90
   local DIAL_THETA1 = 360

   -----------------------------------------------------------------------------
   -- line helper functions

   local _make_horizontal_line = function(x, y, w)
      return geom.make_line(geom.make_point(x, y), geom.make_point(x + w, y))
   end

   -----------------------------------------------------------------------------
   -- text helper functions

   local make_font_spec = function(f, size, bold)
      return {
         family = f,
         size = size,
         weight = bold and FONT_BOLD or FONT_NORMAL,
         slant = FONT_NORMAL,
      }
   end

   local normal_font_spec = make_font_spec(font_family, font_sizes.normal, false)
   local label_font_spec = make_font_spec(font_family, font_sizes.plot_label, false)

   local _text_row_style = function(x_align, _color)
      return text.config(normal_font_spec, _color, x_align, 'center')
   end

   local _left_text_style = _text_row_style('left', patterns.text.inactive)
   local _right_text_style = _text_row_style('right', patterns.text.active)

   local _bare_text = function(pt, _text, _style)
      return text.make_plain(pt, _text, _style)
   end

   local _left_text = function(pt, _text)
      return _bare_text(pt, _text, _left_text_style)
   end

   local _right_text = function(pt, _text)
      return _bare_text(pt, _text, _right_text_style)
   end

   -----------------------------------------------------------------------------
   -- timeseries helper functions

   local _default_grid_config = timeseries.grid_config(
      geometry.plot.ticks[1],
      geometry.plot.ticks[2],
      patterns.plot.grid
   )

   local _default_plot_config = timeseries.config(
      geometry.plot.seconds,
      patterns.plot.outline,
      patterns.plot.data.border,
      patterns.plot.data.fill,
      _default_grid_config
   )

   local _format_percent_label = function(_)
      return function(z) return string.format('%i%%', math.floor(z * 100)) end
   end

   local _format_percent_maybe = function(z)
      if z == -1 then return 'N/A' else return string.format('%s%%', z) end
   end

   local _percent_label_config = timeseries.label_config(
      patterns.text.inactive,
      label_font_spec,
      _format_percent_label
   )

   local _make_timeseries = function(x, y, w, h, label_config, update_freq)
      return timeseries.make(
         geom.make_box(x, y, w, h),
         update_freq,
         _default_plot_config,
         label_config
      )
   end

   local _make_tagged_percent_timeseries = function(x, y, w, h, spacing, label, update_freq, _format)
      return {
         label = _left_text(geom.make_point(x, y), label),
         value = text_threshold.make_formatted(
            geom.make_point(x + w, y),
            nil,
            _right_text_style,
            _format,
            text_threshold.config(patterns.text.critical, 80, false)
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

   -----------------------------------------------------------------------------
   -- scaled timeseries helper functions

   local _base_2_scale_data = function(m)
      return scaled_timeseries.scaling_parameters(2, m, 0.9)
   end

   local _make_scaled_timeseries = function(x, y, w, h, f, min_domain, update_freq)
      return scaled_timeseries.make(
         geom.make_box(x, y, w, h),
         update_freq,
         _default_plot_config,
         timeseries.label_config(patterns.text.inactive, label_font_spec, f),
         _base_2_scale_data(min_domain)
      )
   end

   -----------------------------------------------------------------------------
   -- header

   M.make_header = function(x, y, w, _text)
      local underline_y = y + geometry.header.underline_offset
      local bottom_y = underline_y + geometry.header.padding
      return {
         text = text.make_plain(
            geom.make_point(x, y),
            _text,
            text.config(
               make_font_spec(font_family, font_sizes.header, true),
               patterns.header,
               'left',
               'top'
            )
         ),
         bottom_y = bottom_y,
         underline = line.make(
            _make_horizontal_line(x, underline_y, w),
            line.config(
               style.line(HEADER_UNDERLINE_THICKNESS, HEADER_UNDERLINE_CAP),
               patterns.header,
               true
            )
         )
      }
   end

   M.draw_header = function(cr, header)
      text.draw(header.text, cr)
      line.draw(header.underline, cr)
   end

   -----------------------------------------------------------------------------
   -- percent timeseries

   M.make_percent_timeseries = function(x, y, w, h, update_freq)
      return _make_timeseries(x, y, w, h, _percent_label_config, update_freq)
   end

   -----------------------------------------------------------------------------
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
      text_threshold.draw(obj.value, cr)
      timeseries.draw_dynamic(obj.plot, cr)
   end

   M.tagged_percent_timeseries_set = function(obj, percent)
      local _percent = pure.round_percent(percent)
      text.set(obj.value, _percent)
      timeseries.update(obj.plot, _percent / 100)
   end

   M.tagged_maybe_percent_timeseries_set = function(obj, percent)
      if percent == false then
         text.set(obj.value, -1)
         timeseries.update(obj.plot, 0)
      else
         M.tagged_percent_timeseries_set(obj, percent)
      end
   end

   -----------------------------------------------------------------------------
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
         local new_prefix, new_max = format.convert_data_val(plot_max)
         local conversion_factor = plot_max / new_max
         local fmt = M.y_label_format_string(new_max, new_prefix..unit..'/s')
         return function(bytes)
            return string.format(fmt, bytes / conversion_factor)
         end
      end
   end

   -----------------------------------------------------------------------------
   -- tagged scaled plot

   M.make_tagged_scaled_timeseries = function(x, y, w, h, format_fun, label_fun,
                                              spacing, label, min_domain,
                                              update_freq)
      return {
         label = _left_text(geom.make_point(x, y), label),
         value = text.make_formatted(
            geom.make_point(x + w, y),
            0,
            _right_text_style,
            format_fun
         ),
         plot = _make_scaled_timeseries(
            x,
            y + spacing,
            w,
            h,
            label_fun,
            min_domain,
            update_freq
         ),
      }
   end

   M.tagged_scaled_timeseries_draw_static = function(asp, cr)
      text.draw(asp.label, cr)
   end

   M.tagged_scaled_timeseries_draw_dynamic = function(asp, cr)
      text.draw(asp.value, cr)
      scaled_timeseries.draw_dynamic(asp.plot, cr)
   end

   M.tagged_scaled_timeseries_set = function(asp, value)
      text.set(asp.value, value)
      scaled_timeseries.update(asp.plot, value)
   end

   -----------------------------------------------------------------------------
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
         label = _left_text(geom.make_point(x, y), label),
         value = text.make_formatted(
            geom.make_point(x + w, y),
            0,
            _right_text_style,
            format_fun
         ),
         plot = _make_scaled_timeseries(
            x,
            y + spacing,
            w,
            h,
            label_fun,
            min_domain,
            update_freq
         ),
         prev_value = init,
         derive = make_differential(update_freq),
      }
   end

   M.update_rate_timeseries = function(obj, value)
      local rate = obj.derive(obj.prev_value, value)
      text.set(obj.value, rate)
      scaled_timeseries.update(obj.plot, rate)
      obj.prev_value = value
   end

   -----------------------------------------------------------------------------
   -- circle

   M.make_circle = function(x, y, r)
      return circle.make(
         geom.make_circle(x, y, r),
         circle.config(style.line(ARC_WIDTH, CAP_BUTT), patterns.border)
      )
   end

   -----------------------------------------------------------------------------
   -- ring with text data in the center

   M.make_text_circle = function(x, y, r, fmt, threshhold, pre_function)
      return {
         ring = M.make_circle(x, y, r),
         value = text_threshold.make_formatted(
            geom.make_point(x, y),
            0,
            text.config(normal_font_spec, patterns.text.active, 'center', 'center'),
            fmt,
            text_threshold.config(patterns.text.critical, threshhold, pre_function)
         ),
      }
   end

   M.text_circle_draw_static = function(tr, cr)
      arc.draw(tr.ring, cr)
   end

   M.text_circle_draw_dynamic = function(tr, cr)
      text_threshold.draw(tr.value, cr)
   end

   M.text_circle_set = function(tr, value)
      text_threshold.set(tr.value, value)
   end

   -----------------------------------------------------------------------------
   -- dial

   local threshold_indicator = function(threshold)
      return source.threshold_config(
         patterns.indicator.fg.active,
         patterns.indicator.fg.critical,
         threshold
      )
   end

   M.make_dial = function(x, y, radius, thickness, threshold, _format, pre_function)
      return {
         dial = dial.make(
            geom.make_arc(x, y, radius, DIAL_THETA0, DIAL_THETA1),
            arc.config(style.line(thickness, CAP_BUTT), patterns.indicator.bg),
            threshold_indicator(threshold)
         ),
         text_circle = M.make_text_circle(x, y, radius - thickness / 2 - 2, _format, threshold, pre_function),
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

   -----------------------------------------------------------------------------
   -- compound dial

   M.make_compound_dial = function(x, y, outer_radius, inner_radius, thickness,
                                   threshold, num_dials)
      return compound_dial.make(
         geom.make_arc(x, y, outer_radius, DIAL_THETA0, DIAL_THETA1),
         arc.config(style.line(thickness, CAP_BUTT), patterns.indicator.bg),
         threshold_indicator(threshold),
         inner_radius,
         num_dials
      )
   end

   -----------------------------------------------------------------------------
   -- annotated compound bar

   M.make_compound_bar = function(x, y, w, pad, labels, spacing, thickness, threshold)
      return {
         labels = text_column.make(
            geom.make_point(x, y),
            labels,
            _left_text_style,
            nil,
            spacing
         ),
         bars = compound_bar.make(
            geom.make_point(x + pad, y),
            w - pad,
            line.config(
               style.line(thickness, CAP_BUTT),
               patterns.indicator.bg,
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
      text_column.draw(cb.labels, cr)
      compound_bar.draw_static(cb.bars, cr)
   end

   M.compound_bar_draw_dynamic = function(cb, cr)
      compound_bar.draw_dynamic(cb.bars, cr)
   end

   M.compound_bar_set = function(cb, i, value)
      compound_bar.set(cb.bars, i, value)
   end

   -----------------------------------------------------------------------------
   -- separator (eg a horizontal line)

   M.make_separator = function(x, y, w)
      return line.make(
         _make_horizontal_line(x, y, w),
         line.config(
            style.line(SEPARATOR_THICKNESS, CAP_BUTT),
            patterns.border,
            true
         )
      )
   end

   -----------------------------------------------------------------------------
   -- text row (label with a value, aligned as far apart as possible)

   M.make_text_row = function(x, y, w, label)
      return {
         label = _left_text(geom.make_point(x, y), label),
         value = _right_text(geom.make_point(x + w, y), nil),
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

   -----------------------------------------------------------------------------
   -- text row with critical indicator

   M.make_threshold_text_row = function(x, y, w, label, append_end, limit)
      return{
         label = _left_text(geom.make_point(x, y), label),
         value = text_threshold.make_formatted(
            geom.make_point(x + w, y),
            nil,
            _right_text_style,
            append_end,
            text_threshold.config(patterns.text.critical, limit, false)
         )
      }
   end

   M.threshold_text_row_draw_static = M.text_row_draw_static

   M.threshold_text_row_draw_dynamic = function(row, cr)
      text_threshold.draw(row.value, cr)
   end

   M.threshold_text_row_set = function(row, value)
      text_threshold.set(row.value, value)
   end

   -----------------------------------------------------------------------------
   -- multiple text row separated by spacing

   M.make_text_rows_formatted = function(x, y, w, spacing, labels, _format)
      return {
         labels = text_column.make(
            geom.make_point(x, y),
            labels,
            _left_text_style,
            nil,
            spacing
         ),
         values = text_column.make_n(
            geom.make_point(x + w, y),
            #labels,
            _right_text_style,
            _format,
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
      text_column.draw(rows.labels, cr)
   end

   M.text_rows_draw_dynamic = function(rows, cr)
      text_column.draw(rows.values, cr)
   end

   M.text_rows_set = function(rows, i, value)
      text_column.set(rows.values, i, value)
   end

   -----------------------------------------------------------------------------
   -- table

   local gtable = geometry.table
   local padding = gtable.padding
   local xpad = padding[1]
   local ypad = padding[2]

   local default_table_font_spec = make_font_spec(font_family, font_sizes.table, false)

   local col_fmt = gtable.name_chars > 0 and gtable.name_chars

   local default_table_config = function(label)
      return tbl.config(
         rect.config(
            style.closed_poly(TABLE_LINE_THICKNESS, JOIN_MITER),
            patterns.border
         ),
         line.config(
            style.line(TABLE_LINE_THICKNESS, CAP_BUTT),
            patterns.border,
            true
         ),
         tbl.header_config(
            default_table_font_spec,
            patterns.text.active,
            gtable.header_padding
         ),
         tbl.body_config(
            default_table_font_spec,
            patterns.text.inactive,
            {
               tbl.column_config('Name', col_fmt),
               tbl.column_config('PID', false),
               tbl.column_config(label, false),
            }
         ),
         tbl.padding(xpad, ypad, xpad, ypad)
      )
   end

   M.table_height = function(n)
      return ypad * 2 + gtable.header_padding + gtable.row_spacing * n
   end

   M.make_text_table = function(x, y, w, n, label)
      local h = M.table_height(n)
      return tbl.make(
         geom.make_box(x, y, w, h),
         n,
         default_table_config(label)
      )
   end

   -----------------------------------------------------------------------------
   -- panel

   M.make_panel = function(x, y, w, h, thickness)
      return fill_rect.make(
         geom.make_box(x, y, w, h),
         rect.config(
            style.closed_poly(thickness, JOIN_MITER),
            patterns.border
         ),
         patterns.panel.bg
      )
   end

   ----------------------------------------------------------------------------
   -- compile individual module

   local _combine_blocks = function(acc, new)
      if new.active == true then
         local n = new.f(acc.next_y)
         table.insert(acc.objs, n.obj)
         acc.w = math.max(acc.w, n.w)
         acc.final_y = acc.next_y + n.h
         acc.next_y = acc.final_y + new.offset
      end
      return acc
   end

   local non_false = function(xs)
      return pure.filter(function(x) return x ~= false end, xs)
   end

   local mk_block = function(f, active, offset)
      return {f = f, active = active, offset = offset}
   end

   local active_blocks = function(blockspecs)
      local bs = pure.filter(function(b) return b[2] end, blockspecs)
      return pure.map(function(b) return mk_block(table.unpack(b)) end, bs)
   end

   local mk_separator = function(width, x, y)
      local separator = M.make_separator(x, y, width)
      return M.mk_acc_static(width, 0, pure.partial(line.draw, separator))
   end

   local flatten_sections = function(point, width, top, ...)
      local f = function(acc, new)
         if #new.blocks == 0 then
            return acc
         elseif #acc == 0 then
            return new.blocks
         else
            return pure.flatten(
               {
                  acc,
                  {mk_block(pure.partial(mk_separator, width, point.x), true, new.top)},
                  new.blocks
               }
            )
         end
      end
      return pure.reduce(f, active_blocks(top), {...})
   end

   M.mk_section = function(top, ...)
      return {
         top = top,
         blocks = active_blocks({...})
      }
   end

   M.mk_acc = function(w, h, u, s, d)
      return {w = w, h = h, obj = {u, s, d}}
   end

   M.mk_acc_static = function(w, h, s)
      return M.mk_acc(w, h, false, s, false)
   end

   M.compile_module = function(header, point, width, top_blocks, ...)
      local mk_header = function(y)
         local obj = M.make_header(point.x, y, width, header)
         return M.mk_acc_static(
            width,
            obj.bottom_y - y,
            function(cr) M.draw_header(cr, obj) end
         )
      end
      local blocks = flatten_sections(point, width, top_blocks, ...)
      local r = pure.reduce(
         _combine_blocks,
         {w = 0, next_y = point.y, final_y = point.y, objs = {}},
         {mk_block(mk_header, true, 0), table.unpack(blocks)}
      )
      local us, ss, ds = table.unpack(pure.unzip(r.objs))
      return {
         next_x = point.x + r.w,
         next_y = r.final_y,
         update = pure.sequence(table.unpack(non_false(us))),
         static = pure.sequence(table.unpack(ss)),
         dynamic = pure.sequence(table.unpack(non_false(ds)))
      }
   end

   return M
end
