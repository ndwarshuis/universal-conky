local M = {}

local __tostring		= tostring
local __math_floor 		= math.floor
local __math_log 		= math.log
local __math_ceil 		= math.ceil
local __string_format 	= string.format

M.round = function(x, places)
    local m = 10 ^ (places or 0)
    if x >= 0 then
		return __math_floor(x * m + 0.5) / m
	else
		return __math_ceil(x * m - 0.5) / m
	end
end

M.round_to_string = function(x, places)
	places = places or 0
	if places >= 0 then
       return __string_format('%.'..places..'f', x)
    else
       return __tostring(M.round(x, 0))
    end
end

-- ASSUME domain is (0, inf)
M.precision_round_to_string = function(x, sig_fig)
   local adj = x == 0 and 1 or __math_floor(__math_log(x, 10)) + 1
   return M.round_to_string(x, (sig_fig or 4) - adj)
end

local PREFIXES = {'', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi'}

-- ASSUME domain is (0, inf)
M.convert_data_val = function(x)
   local z = x == 0 and 0 or __math_floor(__math_log(x, 2) / 10)
   return PREFIXES[z + 1], x / 2 ^ (10 * z)
end

return M
