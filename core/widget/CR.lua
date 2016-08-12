local cs = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1366, 768)
local CR = cairo_create(cs)
cairo_surface_destroy(cs)

return CR
