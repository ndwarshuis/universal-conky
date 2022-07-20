local M = {}

local err = require 'err'
local pure = require 'pure'

-- TODO generalize these
-- types of dynamic mappers
-- 1 -> 1
-- 1 -> 1 with recursion
-- 1 -> many
-- 1 -> many (nested in many)
-- many -> many

M.single = function(static, setter, init)
   return err.safe_table(
      {
         static = static,
         setter = setter,
         var = setter(init)
      }
   )
end

-- TODO think of a better more mathy name
M.multi = function(static, setter, inits)
   return err.safe_table(
      {
         static = static,
         setter = setter,
         var = pure.map(setter, inits)
      }
   )
end

M.compound = function(static, setters, init)
   return err.safe_table(
      {
         static = static,
         setters = setters,
         var = pure.map(function(setter) return setter(init) end, setters),
      }
   )
end

return M
