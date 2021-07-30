local common		= require 'common'
local geometry		= require 'geometry'
local fillrect      = require 'fillrect'

return function(left_modules, center_modules, right_modules)
   local __cairo_set_source_surface = cairo_set_source_surface
   local __cairo_image_surface_create = cairo_image_surface_create
   local __cairo_translate = cairo_translate
   local __cairo_create = cairo_create
   local __cairo_destroy = cairo_destroy
   local __cairo_paint = cairo_paint

   local _make_static_surface = function(x, y, w, h, modules)
      local panel_line_thickness = 1
      -- move over by half a pixel so the lines don't need to be antialiased
      local _x = x + 0.5
      local _y = y + 0.5
      local panel = common.initPanel(_x, _y, w, h, panel_line_thickness)
      local cs_x = _x - panel_line_thickness * 0.5
      local cs_y = _y - panel_line_thickness * 0.5
      local cs_w = w + panel_line_thickness
      local cs_h = h + panel_line_thickness

      local cs = __cairo_image_surface_create(CAIRO_FORMAT_ARGB32, cs_w, cs_h)
      local cr = __cairo_create(cs)

      __cairo_translate(cr, -cs_x, -cs_y)

      fillrect.draw(panel, cr)
      for _, f in pairs(modules) do
         f(cr)
      end
      __cairo_destroy(cr)
      return { x = cs_x, y = cs_y, s = cs }
   end

   local cs_left = _make_static_surface(
      geometry.LEFT_X - geometry.PANEL_MARGIN_X,
      geometry.TOP_Y - geometry.PANEL_MARGIN_Y,
      geometry.SECTION_WIDTH + geometry.PANEL_MARGIN_X * 2,
      geometry.SIDE_HEIGHT + geometry.PANEL_MARGIN_Y * 2,
      left_modules
   )

   local cs_center = _make_static_surface(
      geometry.CENTER_LEFT_X - geometry.PANEL_MARGIN_X,
      geometry.TOP_Y - geometry.PANEL_MARGIN_Y,
      geometry.CENTER_WIDTH + geometry.PANEL_MARGIN_Y * 2 + geometry.CENTER_PAD,
      geometry.CENTER_HEIGHT + geometry.PANEL_MARGIN_Y * 2,
      center_modules
   )

   local cs_right = _make_static_surface(
      geometry.RIGHT_X - geometry.PANEL_MARGIN_X,
      geometry.TOP_Y - geometry.PANEL_MARGIN_Y,
      geometry.SECTION_WIDTH + geometry.PANEL_MARGIN_X * 2,
      geometry.SIDE_HEIGHT + geometry.PANEL_MARGIN_Y * 2,
      right_modules
   )

   local draw_static_surface = function(cr, cs_obj)
      __cairo_set_source_surface(cr, cs_obj.s, cs_obj.x, cs_obj.y)
      __cairo_paint(cr)
   end

   return function(cr)
      draw_static_surface(cr, cs_left)
      draw_static_surface(cr, cs_center)
      draw_static_surface(cr, cs_right)
   end
end
