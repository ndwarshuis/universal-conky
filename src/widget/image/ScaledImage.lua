local M = {}

local __imlib_load_image    					= imlib_load_image
local __imlib_context_set_image 				= imlib_context_set_image
local __imlib_render_image_on_drawable_at_size  = imlib_render_image_on_drawable_at_size
local __imlib_free_image    					= imlib_free_image
local __imlib_image_get_width					= imlib_image_get_width
local __imlib_image_get_height					= imlib_image_get_height

local set = function(obj, path)
	local img = __imlib_load_image(path)
	__imlib_context_set_image(img)

	obj.img_width = __imlib_image_get_width()
	obj.img_height = __imlib_image_get_height()
	obj.path = path

	__imlib_free_image()
end

local draw = function(obj)
	local img = __imlib_load_image(obj.path)
	__imlib_context_set_image(img)
	__imlib_render_image_on_drawable_at_size(obj.x, obj.y, obj.width, obj.height)
	__imlib_free_image()
end

M.set = set
M.draw = draw

return M
