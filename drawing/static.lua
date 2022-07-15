local common = require 'common'
local pure = require 'pure'
local geometry = require 'geometry'
local geom = require 'geom'
local fill_rect = require 'fill_rect'

local _combine_modules = function(acc, new)
   local n = new(acc.point)
   table.insert(acc.funs, n.fun)
   acc.point = geom.make_point(acc.point.x, acc.point + n.y)
   return acc
end

local reduce_modules_inner = function(y, mods)
   local r = pure.reduce(_combine_modules, {y = y, mods = {}}, mods)
   -- local us, ss, ds = table.unpack(pure.unzip(r.mods))
   return pure.unzip(r.mods)
   -- return {
   --    updater = pure.sequence(table.unpack(us)),
   --    draw_static = pure.sequence(table.unpack(ss)),
   --    draw_dynamic = pure.sequence(table.unpack(ds))
   -- }
end

return function(module_sets)
   local __cairo_set_source_surface = cairo_set_source_surface
   local __cairo_image_surface_create = cairo_image_surface_create
   local __cairo_translate = cairo_translate
   local __cairo_create = cairo_create
   local __cairo_destroy = cairo_destroy
   local __cairo_paint = cairo_paint

   local _make_static_surface = function(box, modules)
      local panel_line_thickness = 1
      -- move over by half a pixel so the lines don't need to be antialiased
      local _x = box.corner.x + 0.5
      local _y = box.corner.y + 0.5
      local panel = common.make_panel(_x, _y, box.width, box.height, panel_line_thickness)
      local cs_x = _x - panel_line_thickness * 0.5
      local cs_y = _y - panel_line_thickness * 0.5
      local cs_w = box.width + panel_line_thickness
      local cs_h = box.height + panel_line_thickness

      local cs = __cairo_image_surface_create(CAIRO_FORMAT_ARGB32, cs_w, cs_h)
      local cr = __cairo_create(cs)

      __cairo_translate(cr, -cs_x, -cs_y)

      fill_rect.draw(panel, cr)
      for _, f in pairs(modules) do
         f(cr)
      end
      __cairo_destroy(cr)
      return { x = cs_x, y = cs_y, s = cs }
   end

   -- TODO pull this out eventually
   local boxes = {
      geom.make_box(
         geometry.LEFT_X - geometry.PANEL_MARGIN_X,
         geometry.TOP_Y - geometry.PANEL_MARGIN_Y,
         geometry.SECTION_WIDTH + geometry.PANEL_MARGIN_X * 2,
         geometry.SIDE_HEIGHT + geometry.PANEL_MARGIN_Y * 2
      ),
      geom.make_box(
         geometry.CENTER_LEFT_X - geometry.PANEL_MARGIN_X,
         geometry.TOP_Y - geometry.PANEL_MARGIN_Y,
         geometry.CENTER_WIDTH + geometry.PANEL_MARGIN_Y * 2 + geometry.CENTER_PAD,
         geometry.CENTER_HEIGHT + geometry.PANEL_MARGIN_Y * 2
      ),
      geom.make_box(
         geometry.RIGHT_X - geometry.PANEL_MARGIN_X,
         geometry.TOP_Y - geometry.PANEL_MARGIN_Y,
         geometry.SECTION_WIDTH + geometry.PANEL_MARGIN_X * 2,
         geometry.SIDE_HEIGHT + geometry.PANEL_MARGIN_Y * 2
      )
   }

   local cs = pure.zip_with(_make_static_surface, boxes, module_sets)

   local draw_static_surface = function(cr, cs_obj)
      __cairo_set_source_surface(cr, cs_obj.s, cs_obj.x, cs_obj.y)
      __cairo_paint(cr)
   end

   -- return a table with update, static, and dynamic components
   return function(cr)
      for i = 1, #cs do
         draw_static_surface(cr, cs[i])
      end
   end
end
