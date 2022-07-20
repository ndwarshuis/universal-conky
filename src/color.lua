local err = require 'err'

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

local rgb = function(hex)
   return rgba(hex, 1.0)
end

--------------------------------------------------------------------------------
-- Gradients
--
-- these are tables like {[stop] :: color} where stop is a float between 0 and 1
-- and color is a color as defined above

local _make_gradient = function(colorstops, f)
   local c = {}
   for stop, spec in pairs(colorstops) do
      assert(
         stop <= 1 and stop >= 0,
         "ERROR: color stop must be between 0 and 1; got " .. stop
      )
      c[stop] = f(spec)
   end
   return err.set_type(err.safe_table(c), "gradient")
end

-- {[stop] :: hex} -> Gradient
local gradient_rgb = function(colorstops)
   return _make_gradient(colorstops, rgb)
end

-- {[stop] :: {hex, alpha}} -> Gradient
local gradient_rgba = function(colorstops)
   return _make_gradient(
      colorstops,
      function(spec) return rgba(spec[1], spec[2]) end
   )
end

local compile_patterns

compile_patterns = function(patterns)
   local r = {}
   for k, v in pairs(patterns) do
      if type(v) == "number" then
         r[k] = rgb(v)
      elseif v.color ~= nil then
         r[k] = rgba(v.color, v.alpha)
      elseif v.gradient ~= nil then
         local p = {}
         local g = v.gradient
         for i = 1, #g do
            local _g = g[i]
            p[_g.stop] = _g.color
         end
         r[k] = gradient_rgb(p)
      elseif v.gradient_alpha ~= nil then
         local p = {}
         local g = v.gradient_alpha
         for i = 1, #g do
            local _g = g[i]
            p[_g.stop] = {_g.color, _g.alpha}
         end
         r[k] = gradient_rgba(p)
      else
         r[k] = compile_patterns(v)
      end
   end
   return r
end

return compile_patterns
