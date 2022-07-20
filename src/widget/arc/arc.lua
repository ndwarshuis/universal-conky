local M = {}

local geom = require 'geom'
local circle = require 'circle'
local path = require 'path'
local shape = require 'shape'

--------------------------------------------------------------------------------
-- pure

M.make_shape = function(arc, thickness, pattern)
   return shape.shape(
      path.create_arc_from_geom(geom.CR_DUMMY, arc),
      circle.make_source(pattern, arc.center, arc.radius, thickness)
   )
end

M.make = function(arc, config)
   return circle._make(arc, config, M.make_shape)
end

--------------------------------------------------------------------------------
-- impure

M.config = circle.config

M.draw = circle.draw

return M
