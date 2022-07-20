local M = {}

M.sequence = function(...)
   local fs = {...}
   for i = 1, #fs do
      fs[i]()
   end
end

M.each = function(f, seq, ...)
   for i = 1, #seq do
      f(seq[i], ...)
   end
end

M.ieach = function(f, seq, ...)
   for i = 1, #seq do
      f(i, seq[i], ...)
   end
end

M.each2 = function(f, seq1, seq2, ...)
   for i = 1, #seq1 do
      f(seq1[i], seq2[i], ...)
   end
end

return M
