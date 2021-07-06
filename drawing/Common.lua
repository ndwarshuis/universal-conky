local M = {}

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
local HEADER_FONT_SLANT = CAIRO_FONT_SLANT_NORMAL
local HEADER_FONT_WEIGHT = CAIRO_FONT_WEIGHT_BOLD
local HEADER_UNDERLINE_CAP = CAIRO_LINE_CAP_ROUND
local HEADER_UNDERLINE_OFFSET = -20
local HEADER_UNDERLINE_THICKNESS = 3

--------------------------------------------------------------------------------
-- header

M.Header = function(x, y, w, s)
   -- TODO what's the point of bottom_y?
   local bottom_y = y + HEADER_HEIGHT
   local underline_y = bottom_y + HEADER_UNDERLINE_OFFSET

   local obj = {
      text = _G_Widget_.Text{
         x 			= x,
         y 			= y,
         text 		= s,
         font_size 	= HEADER_FONT_SIZE,
         x_align 	= 'left',
         y_align 	= 'top',
         text_color = _G_Patterns_.HEADER_FG,
         slant 		= HEADER_FONT_SLANT,
         weight 	= HEADER_FONT_WEIGHT
      },
      bottom_y = bottom_y,
      underline = _G_Widget_.Line{
         p1 			= {x = x, y = underline_y},
         p2 			= {x = x + w, y = underline_y},
         thickness 		= HEADER_UNDERLINE_THICKNESS,
         line_pattern 	= _G_Patterns_.HEADER_FG,
         cap 			= HEADER_UNDERLINE_CAP
      }
   }

   return obj
end

M.drawHeader = function(cr, header)
   Text.draw(header.text, cr)
   Line.draw(header.underline, cr)
end

--------------------------------------------------------------------------------
-- label plot

M.initThemedLabelPlot = function(x, y, w, h)
   return _G_Widget_.LabelPlot{
      x = x,
      y = y,
      width = w,
      height = h,
      outline_pattern = _G_Patterns_.BORDER_FG,
      intrvl_pattern = _G_Patterns_.BORDER_FG,
      data_line_pattern = _G_Patterns_.PLOT_FILL_BORDER_PRIMARY,
      data_fill_pattern = _G_Patterns_.PLOT_FILL_BG_PRIMARY,
      label_color = _G_Patterns_.INACTIVE_TEXT_FG,
   }
end

--------------------------------------------------------------------------------
-- percent plot (label plot with percent signs and some indicator data above it)

M.initPercentPlot = function(x, y, w, h, spacing, label)
   return {
      label = _G_Widget_.Text{
         x = x,
         y = y,
         text = label,
         text_color = _G_Patterns_.INACTIVE_TEXT_FG,
      },
      value = _G_Widget_.CriticalText{
         x = x + w,
         y = y,
         x_align = 'right',
         append_end = '%',
         critical_limit = '>80',
         text_color = _G_Patterns_.PRIMARY_FG,
         critical_color = _G_Patterns_.PRIMARY_FG,
      },
      plot = M.initThemedLabelPlot(x, y + spacing, w, h),
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

M.initThemedScalePlot = function(x, y, w, h, f)
   return _G_Widget_.ScalePlot{
      x = x,
      y = y,
      width = w,
      height = h,
      y_label_func = f,
      outline_pattern = _G_Patterns_.BORDER_FG,
      intrvl_pattern = _G_Patterns_.BORDER_FG,
      data_line_pattern = _G_Patterns_.PLOT_FILL_BORDER_PRIMARY,
      data_fill_pattern = _G_Patterns_.PLOT_FILL_BG_PRIMARY,
      label_color = _G_Patterns_.INACTIVE_TEXT_FG,
   }
end

--------------------------------------------------------------------------------
-- scaled plot (with textual data above it)

M.initLabeledScalePlot = function(x, y, w, h, f, spacing, label)
   return {
      label = _G_Widget_.Text{
         x = x,
         y = y,
         text = label,
         text_color = _G_Patterns_.INACTIVE_TEXT_FG,
      },
      value = _G_Widget_.Text{
         x = x + w,
         y = y,
         x_align = 'right',
         text_color = _G_Patterns_.PRIMARY_FG
      },
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
   return _G_Widget_.Arc{
      x = x,
      y = y,
      radius = r,
      theta0 = 0,
      theta1 = 360,
      arc_pattern = _G_Patterns_.BORDER_FG
   }
end

--------------------------------------------------------------------------------
-- ring with text data in the center

M.initTextRing = function(x, y, r, append_end, limit)
   return {
	  ring = M.initRing(x, y, r),
	  value = _G_Widget_.CriticalText{
		 x = x,
		 y = y,
		 x_align = 'center',
		 y_align = 'center',
		 append_end = append_end,
		 critical_limit = limit,
         text_color = _G_Patterns_.PRIMARY_FG,
         critical_color = _G_Patterns_.CRITICAL_FG,
	  },
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
   return _G_Widget_.Line{
      p1 = {x = x, y = y},
      p2 = {x = x + w, y = y},
      line_pattern = _G_Patterns_.BORDER_FG,
   }
end

--------------------------------------------------------------------------------
-- text row (label with a value, aligned as far apart as possible)

M.initTextRow = function(x, y, w, label)
   return {
      label = _G_Widget_.Text{
         x = x,
         y = y,
         text_color = _G_Patterns_.INACTIVE_TEXT_FG,
         text = label,
      },
      value = _G_Widget_.Text{
         x = x + w,
         y = y,
         x_align = 'right',
         text_color = _G_Patterns_.PRIMARY_FG,
         text = "<NA>",
      }
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
M.initTextRowCrit = function(x, y, w, label, append_end)
   return{
      label = _G_Widget_.Text{
         x = x,
         y = y,
         text = label,
         text_color = _G_Patterns_.INACTIVE_TEXT_FG,
      },
      value = _G_Widget_.CriticalText{
         x = x + w,
         y = y,
         x_align = 'right',
         text_color = _G_Patterns_.PRIMARY_FG,
         critical_color = _G_Patterns_.CRITICAL_FG,
         append_end = append_end,
         text = '<NA>',
      }
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
      labels = _G_Widget_.TextColumn{
         x = x,
         y = y,
         spacing = spacing,
         text_color = _G_Patterns_.INACTIVE_TEXT_FG,
         table.unpack(labels),
      },
      values = _G_Widget_.TextColumn{
         x = x + w,
         y = y,
         spacing = spacing,
         x_align = 'right',
         text_color = _G_Patterns_.PRIMARY_FG,
         num_rows = #labels,
      }
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

M.initTable = function(x, y, w, h, n, labels)
   return _G_Widget_.Table{
      x = x,
      y = y,
      width = w,
      height = h,
      num_rows = n,
      body_color = _G_Patterns_.INACTIVE_TEXT_FG,
      header_color = _G_Patterns_.PRIMARY_FG,
      line_pattern = _G_Patterns_.BORDER_FG,
      separator_pattern = _G_Patterns_.BORDER_FG,
      table.unpack(labels),
   }
end

--------------------------------------------------------------------------------
-- panel

M.initPanel = function(x, y, w, h)
   return _G_Widget_.FillRect{
      x	= x + 0.5,
      y	= y + 0.5,
      width	= w,
      height = h,
      line_pattern = _G_Patterns_.BORDER_FG,
      fill_pattern = _G_Patterns_.PANEL_BG,
   }
end

return M
