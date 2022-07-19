--------------------------------------------------------------------------------
-- startup - this is where the modules are compiled and arranged

local draw_dynamic

local __cairo_xlib_surface_create
local __cairo_create
local __cairo_surface_destroy
local __cairo_destroy

function conky_start(update_interval, config_path, path, cpath)
   package.path = package.path..';'..path
   package.cpath = package.cpath..';'..cpath

   require 'cairo'

   __cairo_xlib_surface_create = cairo_xlib_surface_create
   __cairo_create = cairo_create
   __cairo_surface_destroy = cairo_surface_destroy
   __cairo_destroy = cairo_destroy

   local compile = require 'compile'

   conky_set_update_interval(update_interval)

   draw_dynamic = compile(update_interval, config_path)
end

--------------------------------------------------------------------------------
-- main loop - where all the drawing/updating happens

local updates = -2 -- this accounts for the first few spazzy iterations

function conky_main()
   local _cw = conky_window
   if not _cw then return end

   local cs = __cairo_xlib_surface_create(_cw.display, _cw.drawable,
                                          _cw.visual, _cw.width, _cw.height)
   local cr = __cairo_create(cs)
   updates = updates + 1

   draw_dynamic(cr, updates)

   __cairo_surface_destroy(cs)
   __cairo_destroy(cr)
end
