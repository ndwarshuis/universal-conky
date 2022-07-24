local err = require 'err'
local pure = require 'pure'

--------------------------------------------------------------------------------
-- colors
--
-- these are tables like {red :: Int, green :: Int, blue :: Int, alpha :: Int}

local rgba = function(hex, alpha)
   local obj = err.safe_table(
      {
         r = ((hex / 0x10000) % 0x100) / 255.,
         g = ((hex / 0x100) % 0x100) / 255.,
         b = (hex % 0x100) / 255.,
         a = alpha,
      }
   )
   return err.set_type(obj, "color")
end

local rgb = pure.partial(pure.flip(rgba), 1.0)

--------------------------------------------------------------------------------
-- Gradients
--
-- these are tables like {[stop] :: color} where stop is a float between 0 and 1
-- and color is a color as defined above

local _make_gradient = function(f)
   return pure.compose(
      pure.partial(pure.flip(err.set_type), "gradient"),
      err.safe_table,
      pure.array_to_map,
      pure.partial(pure.kmap, function(stop, spec) return {stop, f(spec)} end)
   )
end

-- {[stop] :: hex} -> Gradient
local gradient_rgb = _make_gradient(rgb)

-- {[stop] :: {hex, alpha}} -> Gradient
local gradient_rgba = _make_gradient(function(spec) return rgba(spec[1], spec[2]) end)

--------------------------------------------------------------------------------
-- Yaml config to pattern tree

local compile_gradient = pure.compose(
   gradient_rgb,
   pure.array_to_map,
   pure.partial(pure.map, function(g) return {g.stop, g.color} end)
)

local compile_gradient_alpha = pure.compose(
   gradient_rgba,
   pure.array_to_map,
   pure.partial(pure.map, function(g) return {g.stop, {g.color, g.alpha}} end)
)

local compile_patterns

compile_patterns = function(patterns)
   local r = {}
   for k, v in pairs(patterns) do
      if type(v) == "number" then
         r[k] = rgb(v)
      elseif v.color ~= nil then
         r[k] = rgba(v.color, v.alpha)
      elseif v.gradient ~= nil then
         r[k] = compile_gradient(v.gradient)
      elseif v.gradient_alpha ~= nil then
         r[k] = compile_gradient_alpha(v.gradient_alpha)
      else
         r[k] = compile_patterns(v)
      end
   end
   return r
end

return compile_patterns
