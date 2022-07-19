--------------------------------------------------------------------------------
-- startup - this is where the modules are compiled and arranged

local draw_dynamic

local __cairo_xlib_surface_create
local __cairo_create
local __cairo_surface_destroy
local __cairo_destroy

function conky_start(update_interval, conky_dir)
   local subdirs = {
      '?.lua',
      'drawing/?.lua',
      'schema/?.lua',
      'core/?.lua',
      'core/widget/?.lua',
      'core/widget/arc/?.lua',
      'core/widget/text/?.lua',
      'core/widget/timeseries/?.lua',
      'core/widget/rect/?.lua',
      'core/widget/line/?.lua',
      'lib/share/lua/5.4/?.lua',
      'lib/share/lua/5.4/?/init.lua',
   }

   for i = 1, #subdirs do
      package.path = package.path..';'..conky_dir..subdirs[i]
   end

   package.cpath = package.cpath..';'..conky_dir..'lib/lib/lua/5.4/?.so;'

   require 'cairo'

   __cairo_xlib_surface_create = cairo_xlib_surface_create
   __cairo_create = cairo_create
   __cairo_surface_destroy = cairo_surface_destroy
   __cairo_destroy = cairo_destroy

   local compile = require 'compile'

   conky_set_update_interval(update_interval)

   draw_dynamic = compile(update_interval, conky_dir..'config.yml')
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
