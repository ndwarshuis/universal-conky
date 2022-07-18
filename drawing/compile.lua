local M = {}

local pure = require 'pure'
local geom = require 'geom'
local fill_rect = require 'fill_rect'

--------------------------------------------------------------------------------
-- compile entire layout

local reduce_modules_y = function(common, modlist, init_x, width, acc, new)
   if type(new) == "number" then
      acc.next_y = acc.next_y + new
   else
      local m = modlist[new](common, width, geom.make_point(init_x, acc.next_y))
      local r = common.compile_module(
         m.header,
         m.point,
         m.width,
         m.top,
         table.unpack(pure.table_array(m))
      )
      local update = pure.maybe(
         r.update,
         function(f) return function() f() r.update() end end,
         m.set_state
      )
      table.insert(acc.fgroups, {update = update, static = r.static, dynamic = r.dynamic})
      acc.next_x = math.max(acc.next_x, r.next_x)
      acc.next_y = r.next_y
   end
   return acc
end

local reduce_modules_x = function(common, modlist, init_y, acc, x_mods)
   if type(x_mods) == "number" then
      acc.next_x = acc.next_x + x_mods
   else
      local r = pure.reduce(
         pure.partial(reduce_modules_y, common, modlist, acc.next_x, x_mods.width),
         {next_x = acc.next_x, next_y = init_y, fgroups = acc.fgroups},
         x_mods.blocks
      )
      acc.fgroups = r.fgroups
      acc.next_x = r.next_x
      acc.next_y = math.max(acc.next_y, r.next_y)
   end
   return acc
end

local arrange_panel_modules = function(common, modlist, point, mods)
   local r = pure.reduce(
      pure.partial(reduce_modules_x, common, modlist, point.y),
      {next_x = point.x, next_y = point.y, fgroups = {}},
      mods
   )
   return {
      point_ul = point,
      width = r.next_x - point.x,
      height = r.next_y - point.y,
      update = pure.map_keys('update', r.fgroups),
      static = pure.map_keys('static', r.fgroups),
      dynamic = pure.map_keys('dynamic', r.fgroups),
   }
end

local build_surface = function(common, box, fs)
   local panel_line_thickness = 1
   -- move over by half a pixel so the lines don't need to be antialiased
   local _x = box.corner.x + 0.5
   local _y = box.corner.y + 0.5
   local panel = common.make_panel(_x, _y, box.width, box.height, panel_line_thickness)
   local cs_x = _x - panel_line_thickness * 0.5
   local cs_y = _y - panel_line_thickness * 0.5
   local cs_w = box.width + panel_line_thickness
   local cs_h = box.height + panel_line_thickness

   local cs = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, cs_w, cs_h)
   local cr = cairo_create(cs)

   cairo_translate(cr, -cs_x, -cs_y)

   fill_rect.draw(panel, cr)
   for i = 1, #fs do
      fs[i](cr)
   end
   cairo_destroy(cr)
   return {x = cs_x, y = cs_y, s = cs}
end

local reduce_static = function(common, mods, y, acc, panel_mods)
   if type(panel_mods) == "number" then
      acc.next_x = acc.next_x + panel_mods
   else
      local margins = panel_mods.margins
      local margin_x = margins[1]
      local margin_y = margins[2]
      local mpoint = geom.make_point(acc.next_x + margin_x, y + margin_y)
      local r = arrange_panel_modules(common, mods, mpoint, panel_mods.columns)
      local w = r.width + margin_x * 2
      local h = r.height + margin_y * 2
      local pbox = geom.make_box(acc.next_x, y, w, h)
      acc.next_x = acc.next_x + w
      acc.static = pure.flatten({acc.static, {build_surface(common, pbox, r.static)}})
      acc.update = pure.flatten({acc.update, r.update})
      acc.dynamic = pure.flatten({acc.dynamic, r.dynamic})
   end
   return acc
end

M.compile_layout = function(common, point, mods, module_sets)
   local __cairo_set_source_surface = cairo_set_source_surface
   local __cairo_paint = cairo_paint

   local r = pure.reduce(
      pure.partial(
         reduce_static,
         common,
         mods,
         point.y
      ),
      {next_x = point.x, static = {}, update = {}, dynamic = {}},
      module_sets
   )

   local cs = r.static

   return {
      static = function(cr)
         for i = 1, #cs do
            local c = cs[i]
            __cairo_set_source_surface(cr, c.s, c.x, c.y)
            __cairo_paint(cr)
         end
      end,
      update = pure.sequence(table.unpack(r.update)),
      dynamic = pure.sequence(table.unpack(r.dynamic)),
   }
end

return M
