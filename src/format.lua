local M = {}

local __tostring		= tostring
local __math_floor 		= math.floor
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

M.precision_round_to_string = function(x, sig_fig)
	sig_fig = sig_fig or 4
	if     x < 10   then return M.round_to_string(x, sig_fig - 1)
	elseif x < 100  then return M.round_to_string(x, sig_fig - 2)
	elseif x < 1000 then return M.round_to_string(x, sig_fig - 3)
	else                 return M.round_to_string(x, sig_fig - 4)
	end
end

M.convert_data_val = function(x)
	if     	x < 1024       then	return '', x
	elseif 	x < 1048576    then	return 'Ki', x / 1024
	elseif 	x < 1073741824 then	return 'Mi', x / 1048576
    else					    return 'Gi', x / 1073741824
    end
end

return M
