local M = {}

local err = require 'err'

local __math_floor = math.floor
local __table_insert = table.insert

--------------------------------------------------------------------------------
-- zippy functions

-- TODO generalize to arbitrary number of sequences
M.zip_with = function(f, seq1, seq2)
   local r = {}
   for i = 1, #seq1 do
      r[i] = f(seq1[i], seq2[i])
   end
   return r
end

M.zip = function(...)
   local seqs = {...}
   local imax = math.min(table.unpack(M.map(function(t) return #t end, seqs)))
   local jmax = #seqs
   local r = {}
   for i = 1, imax do
      r[i] = {}
      for j = 1, jmax do
         r[i][j] = seqs[j][i]
      end
   end
   return r
end

M.unzip = function(seqs)
   return M.zip(table.unpack(seqs))
end

--------------------------------------------------------------------------------
-- reductions

M.reduce = function(f, init, seq)
   if seq == nil then
      return init
   else
      local r = init
      for i = 1, #seq do
         r = f(r, seq[i])
      end
      return r
   end
end

--------------------------------------------------------------------------------
-- mappy functions

M.map = function(f, seq, ...)
   local r = {}
   for i = 1, #seq do
      r[i] = f(seq[i], ...)
   end
   return r
end

M.map_n = function(f, n, ...)
   local r = {}
   for i = 1, n do
      r[i] = f(i, ...)
   end
   return r
end

M.imap = function(f, seq)
   local r = {}
   for i = 1, #seq do
      r[i] = f(i, seq[i])
   end
   return r
end

M.map_keys = function(key, tbls)
   local r = {}
   for i = 1, #tbls do
      r[i] = tbls[i][key]
   end
   return r
end

M.map_at = function(key, f, tbl)
   local r = {}
   for k, v in pairs(tbl) do
      if k == key then
         r[k] = f(v)
      else
         r[k] = v
      end
   end
   return r
end

--------------------------------------------------------------------------------
-- generations

M.seq = function(n, start)
   start = start or 1
   local r = {}
   for i = 1, n do
      r[i] = i + start - 1
   end
   return r
end

M.rep = function(n, x)
   local r = {}
   for i = 1, n do
      r[i] = x
   end
   return r
end

M.array_to_map = function(arr)
   local r = {}
   for i = 1, #arr do
      r[arr[i][1]] = arr[i][2]
   end
   return r
end

--------------------------------------------------------------------------------
-- random list things

M.set = function(tbl, key, value)
   local r = {}
   for k, v in pairs(tbl) do
      if k == key then
         r[k] = value
      else
         r[k] = v
      end
   end
   return r
end

M.reverse = function(xs)
   local j = 1
   local r = {}
   for i = #xs, 1, -1 do
      r[j] = xs[i]
      j = j + 1
   end
   return r
end

M.filter = function(f, seq)
   local r = {}
   local j = 1
   for i = 1, #seq do
      if f(seq[i]) == true then
         r[j] = seq[i]
         j = j + 1
      end
   end
   return r
end

M.flatten = function(xs)
   local r = {}
   for i = 1, #xs do
      for j = 1, #xs[i] do
         table.insert(r, xs[i][j])
      end
   end
   return r
end

M.concat = function(...)
   return M.flatten({...})
end

M.table_array = function(tbl)
   local r = {}
   for i = 1, #tbl do
      r[i] = tbl[i]
   end
   return r
end

M.iter_to_table1 = function(iter)
   local r = {}
   for next in iter do
      __table_insert(r, next)
   end
   return r
end

M.iter_to_tableN = function(iter)
   local r = {}
   local next = {iter()}
   while #next > 0 do
      __table_insert(r, next)
      next = {iter()}
   end
   return r
end

--------------------------------------------------------------------------------
-- functional functions

local get_arity = function(f, args)
   local i = #args
   while args[i] == true do
      i = i - 1
   end
   if i < #args then
      return table.move(args, 1, #args - i, 1, {}), #args
   else
      local arity = debug.getinfo(f, "u")["nparams"]
      err.assert_trace(arity > #args, 'too many arguments for partial')
      return args, arity
   end
end

-- poor man's Lisp macro :)
M.partial = function(f, ...)
   local args, arity = get_arity(f, {...})
   local format_args = function(fmt, n, start)
      return table.concat(
         M.map(function(i) return string.format(fmt, i) end, M.seq(n, start)),
         ','
      )
   end
   local partial_args = format_args('args[%i]', #args, 1)
   local rem_args = format_args('x%i', arity - #args, #args + 1)
   local src = string.format(
      'return function(%s) return f(%s,%s) end',
      rem_args,
      partial_args,
      rem_args
   )
   return load(src, 'partial_apply', 't', {f = f, args = args})()
end

M.compose = function(f, ...)
   if #{...} == 0 then
      return f
   else
      local g = M.compose(...)
      return function(x) return f(g(x)) end
   end
end

-- TODO is there a way to do this without nesting a zillion function calls?
M.sequence = function(...)
   local fs = {...}
   return function(x)
      for i = 1, #fs do
         fs[i](x)
      end
   end
end

M.memoize = function(f)
   local mem = {} -- memoizing table
   setmetatable(mem, {__mode = "kv"}) -- make it weak
   return function (x, ...)
      local r = mem[x]
      if not r then
         r = f(x, ...)
         mem[x] = r
      end
      return r
   end
end

M.maybe = function(def, f, x)
   if x == nil then
      return def
   else
      return f(x)
   end
end

M.fmap_maybe = function(f, x)
   return M.maybe(nil, f, x)
end

-- round to whole numbers since I don't need more granularity and extra values
-- will lead to cache misses
M.round_percent = __math_floor

return M
