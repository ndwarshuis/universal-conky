local M = {}

local i_o = require 'i_o'

M.assert_trace = function(test, msg)
   if not test then
      i_o.errorf(msg)
      print(debug.traceback())
      os.exit(1)
   end
end

M.safe_table = function(tbl)
   local ck_key = function(_, key)
      local v = rawget(tbl, key)
      M.assert_trace(v ~= nil, "key doesn't exist: "..key)
      return v
   end
   return setmetatable(tbl, {__index = ck_key})
end

local TYPE_KEY = '__type'

M.set_type = function(tbl, _type)
   local mt = getmetatable(tbl)
   mt[TYPE_KEY] = _type
   return setmetatable(tbl, mt)
end

M.get_type = function(x)
   local ltype = type(x)
   if ltype == "table" then
      local mt = getmetatable(x)
      if mt == nil then
         return ltype
      else
         return mt[TYPE_KEY]
      end
   else
      return ltype
   end
end

M.check_type = function(x, _type)
   local xtype = nil
   if x ~= nil then
      xtype = M.get_type(x)
   end
   i_o.assertf(xtype == _type, "type must be '%s' got '%s' instead", _type, xtype)
end

return M
