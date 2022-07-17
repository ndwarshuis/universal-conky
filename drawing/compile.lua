local M = {}

local pure = require 'pure'
local geom = require 'geom'
local fill_rect = require 'fill_rect'
local line = require 'line'

--------------------------------------------------------------------------------
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

local flatten_sections = function(top, ...)
   local f = function(acc, new)
      if #new.blocks == 0 then
         return acc
      elseif #acc == 0 then
         return new.blocks
      else
         return pure.flatten(
            {acc, {mk_block(new.sep_fun, true, new.top)}, new.blocks}
         )
      end
   end
   return pure.reduce(f, active_blocks(top), {...})
end

M.mk_section = function(top, sep_fun, ...)
   return {
      top = top,
      sep_fun = sep_fun,
      blocks = active_blocks({...})
   }
end

M.mk_seperator = function(common, width, x, y)
   local separator = common.make_separator(x, y, width)
   return M.mk_acc_static(width, 0, pure.partial(line.draw, separator))
end

M.mk_acc = function(w, h, u, s, d)
   return {w = w, h = h, obj = {u, s, d}}
end

M.mk_acc_static = function(w, h, s)
   return M.mk_acc(w, h, false, s, false)
end

M.compile_module = function(common, header, point, width, top_blocks, ...)
   local mk_header = function(y)
      local obj = common.make_header(point.x, y, width, header)
      return M.mk_acc_static(
         width,
         obj.bottom_y - y,
         function(cr) common.draw_header(cr, obj) end
      )
   end
   local blocks = flatten_sections(top_blocks, ...)
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

--------------------------------------------------------------------------------
-- compile entire layout

local reduce_modules_y = function(common, modlist, init_x, width, acc, new)
   if type(new) == "number" then
      acc.next_y = acc.next_y + new
   else
      print(new)
      local r = modlist[new](common, width, geom.make_point(init_x, acc.next_y))
      table.insert(acc.fgroups, {update = r.update, static = r.static, dynamic = r.dynamic})
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
