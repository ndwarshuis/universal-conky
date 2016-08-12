local c = {}

local _PAIRS 			= pairs
local _TYPE 			= type
local _TONUMBER			= tonumber
local _TOSTRING			= tostring
local _IO_POPEN 		= io.popen
local _IO_OPEN 			= io.open
local _MATH_FLOOR 		= math.floor
local _MATH_CEIL 		= math.ceil
local _STRING_SUB 		= string.sub
local _STRING_GSUB 		= string.gsub
local _STRING_MATCH 	= string.match
local _STRING_FORMAT 	= string.format
local _STRING_UPPER 	= string.upper
local _CONKY_PARSE		= conky_parse
local _SELECT			= select
local _SETMETATABLE 	= setmetatable

local copy_table = function(t)
	local s = {}
	for i, v in _PAIRS(t) do s[i] = _TYPE(v) == 'table' and copy_table(v) or v end
	return s
end

local round = function(x, places)
    local m = 10 ^ (places or 0)
    if x >= 0 then
		return _MATH_FLOOR(x * m + 0.5) / m
	else
		return _MATH_CEIL(x * m - 0.5) / m
	end
end

local get_bytes_power = function(unit)
	if     unit == 'KiB' then return 10
	elseif unit == 'MiB' then return 20
	elseif unit == 'GiB' then return 30
	elseif unit == 'TiB' then return 40
	else                      return 0
	end
end

local convert_bytes = function(x, old_unit, new_unit)
	if old_unit == new_unit then
		return _TONUMBER(x)
	else
		return x * 2 ^ (get_bytes_power(old_unit) - get_bytes_power(new_unit))
	end
end

local round_to_string = function(x, places)
	places = places or 0
	local y = round(x, places)
	if places > 0 then return _STRING_FORMAT('%.'..places..'f', y) else return _TOSTRING(y) end
end

local precision_round_to_string = function(x, sig_fig)
	sig_fig = sig_fig or 4
	if     x < 10   then return round_to_string(x, sig_fig - 1)
	elseif x < 100  then return round_to_string(x, sig_fig - 2)
	elseif x < 1000 then return round_to_string(x, sig_fig - 3)
	else                 return round_to_string(x, sig_fig - 4)
	end
end

local read_entire_file = function(file, regex, mode)
	if not file then return '' end
	local str = file:read(mode or '*a')
	file:close()
	if not str then return '' end
	if regex then return _STRING_MATCH(str, regex) or '' else return str end
end

local conky = function(expr, regex)
	local ans = _CONKY_PARSE(expr)
	if regex then return _STRING_MATCH(ans, regex) or '' else return ans end
end

local precision_convert_bytes = function(val, old_unit, new_unit, sig_fig)
	return precision_round_to_string(convert_bytes(val, old_unit, new_unit), sig_fig)
end

local get_unit = function(bytes)
	if     	bytes < 1024       then	return 'B'
	elseif 	bytes < 1048576    then	return 'KiB'
	elseif 	bytes < 1073741824 then	return 'MiB'
	else							return 'GiB'  
	end
end

local get_unit_base_K = function(kilobytes)
	if 		kilobytes < 1024       then	return 'KiB'
	elseif 	kilobytes < 1048576    then	return 'MiB'
	elseif	kilobytes < 1073741824 then	return 'GiB'
	else								return 'TiB'
	end
end

local parse_unit = function(str)
	return _STRING_MATCH(str, '^([%d%p]-)(%a+)')
end

local char_count = function(str, char)
	return _SELECT(2, _STRING_GSUB(str, char, char))
end

local line_count = function(str)
	return char_count(str, '\n')
end

local execute_cmd = function(cmd, regex, mode)
	return read_entire_file(_IO_POPEN(cmd), regex, mode)
end

local read_file = function(path, regex, mode)
	return read_entire_file(_IO_OPEN(path, 'rb'), regex, mode)
end

local write_file = function(path, str)
	local file = _IO_OPEN(path, 'w+')
	if file then
		file:write(str)
		file:close()
	end
end

local conky_numeric = function(expr, regex)
	return _TONUMBER(conky(expr, regex)) or 0
end

local memoize = function(f)
	local mem = {} -- memoizing table
	_SETMETATABLE(mem, {__mode = "kv"}) -- make it weak
	return function (x) 	-- new version of ’f’, with memoizing
		local r = mem[x]
		if not r then 		-- no previous result?
			r = f(x) 		-- calls original function
			mem[x] = r 		-- store result for reuse
		end
		return r
	end
end

local convert_unix_time = function(unix_time, frmt)
	local cmd = 'date -d @'..unix_time
	if frmt then cmd = cmd..' +\''..frmt..'\'' end
	return _STRING_MATCH(execute_cmd(cmd), '(.-)\n')
end

local capitalize_each_word = function(str)
	return _STRING_SUB(_STRING_GSUB(" "..str, "%W%l", _STRING_UPPER), 2)
end

c.round = round
c.get_bytes_power = get_bytes_power
c.convert_bytes = convert_bytes
c.copy_table = copy_table
c.conky = conky
c.round_to_string = round_to_string
c.precision_round_to_string = precision_round_to_string
c.precision_convert_bytes = precision_convert_bytes
c.get_unit = get_unit
c.get_unit_base_K = get_unit_base_K
c.parse_unit = parse_unit
c.char_count = char_count
c.line_count = line_count
c.execute_cmd = execute_cmd
c.read_file = read_file
c.write_file = write_file
c.conky_numeric = conky_numeric
c.memoize = memoize
c.convert_unix_time = convert_unix_time
c.capitalize_each_word = capitalize_each_word

return c
