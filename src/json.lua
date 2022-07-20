local M = {}

local __string_gsub 	= string.gsub
local __string_char 	= string.char
local __string_find 	= string.find
local __string_sub 		= string.sub
local __table_concat 	= table.concat
local __math_floor 		= math.floor
local __pairs 			= pairs
local __tonumber 		= tonumber

local decode -- to ref this before definition

local decode_scan_whitespace = function(s, start_pos)
	local whitespace = " \n\r\t"
	local string_len = #s
	
	while (__string_find(whitespace, __string_sub(s, start_pos, start_pos), 1, true) and
	  start_pos <= string_len) do
		start_pos = start_pos + 1
	end
	return start_pos
end

local decode_scan_array = function(s, start_pos)
	local array = {}
	local string_len = #s
	
	start_pos = start_pos + 1

	repeat
		start_pos = decode_scan_whitespace(s, start_pos)
		
		local cur_char = __string_sub(s,start_pos,start_pos)
		
		if (cur_char == ']') then
			return array, start_pos + 1
		end
		
		if (cur_char == ',') then
			start_pos = decode_scan_whitespace(s, start_pos + 1)
		end
		
		object, start_pos = decode(s, start_pos)
		array[#array + 1] = object
	until false
end

local decode_scan_comment = function(s, start_pos)
	local end_pos = __string_find(s, '*/', start_pos + 2)
	return end_pos + 2
end

local decode_scan_constant = function(s, start_pos)
	local consts = {["true"] = true, ["false"] = false,	["null"] = nil}
	local const_names = {"true", "false", "null"}
	
	for _, k in __pairs(const_names) do
		if __string_sub(s, start_pos, start_pos + #k - 1 ) == k then
			return consts[k], start_pos + #k
		end
	end
end

local decode_scan_number = function(s, start_pos)
	local end_pos = start_pos + 1
	local string_len = #s
	local acceptable_chars = "+-0123456789.e"
	
	while (__string_find(acceptable_chars, __string_sub(s, end_pos, end_pos), 1, true)
	  and end_pos <= string_len) do
		end_pos = end_pos + 1
	end

	local number_string = __string_gsub(__string_sub(s, start_pos, end_pos - 1), '+', '')
	return __tonumber(number_string), end_pos
end

local decode_scan_object = function(s, start_pos)
	local object = {}
	local string_len = #s
	local key, value
	
	start_pos = start_pos + 1
	
	repeat
		start_pos = decode_scan_whitespace(s, start_pos)
		
		local cur_char = __string_sub(s, start_pos, start_pos)
		
		if (cur_char == '}') then
			return object, start_pos + 1
		end
		
		if (cur_char == ',') then
			start_pos = decode_scan_whitespace(s, start_pos + 1)
		end
		
		-- Scan the key
		key, start_pos = decode(s, start_pos)
		
		start_pos = decode_scan_whitespace(s, start_pos)
		start_pos = decode_scan_whitespace(s, start_pos + 1)

		value, start_pos = decode(s, start_pos)
		
		object[key] = value
	until false
end

local escape_sequences = {
	["\\t"] = "\t",
	["\\f"] = "\f",
	["\\r"] = "\r",
	["\\n"] = "\n",
	["\\b"] = "\b"
}

setmetatable(escape_sequences, {__index = function(t, k) return __string_sub(k, 2) end})--skip "\"

local decode_scan_string = function (s, start_pos)
	local start_char = __string_sub(s, start_pos, start_pos)
	
	local t = {}
	local i, j = start_pos, start_pos
	
	while __string_find(s, start_char, j + 1) ~= j + 1 do
		local oldj = j
		local x, y = __string_find(s, start_char, oldj + 1)
		
		i, j = __string_find(s, "\\.", j + 1)
		
		if not i or x < i then i, j = x, y - 1 end

		t[#t + 1] = __string_sub(s, oldj + 1, i - 1)
		
		if __string_sub(s, i, j) == "\\u" then
			local a = __string_sub(s, j + 1, j + 4)
			local n = __tonumber(a, 16)
			local x
			
			j = j + 4
			
			if n < 0x80 then
				x = __string_char(n % 0x80)
			elseif n < 0x800 then
				x = __string_char(0xC0 + (__math_floor(n / 64) % 0x20), 0x80 + (n % 0x40))
			else
				x = __string_char(0xE0 + (__math_floor(n / 4096) % 0x10), 0x80 +
				  (__math_floor(n / 64) % 0x40), 0x80 + (n % 0x40))
			end
		
			t[#t + 1] = x
		else
			t[#t + 1] = escape_sequences[__string_sub(s, i, j)]
		end
	end
	t[#t + 1] = __string_sub(j, j + 1)
	
	return __table_concat(t, ""), j + 2
end

decode = function(s, start_pos)
	start_pos = start_pos or 1
	start_pos = decode_scan_whitespace(s, start_pos)
	
	local cur_char = __string_sub(s, start_pos, start_pos)
	
	if cur_char == '{' then
		return decode_scan_object(s, start_pos)
	end
	
	if cur_char == '[' then
		return decode_scan_array(s, start_pos)
	end

	if __string_find("+-0123456789.e", cur_char, 1, true) then
		return decode_scan_number(s, start_pos)
	end

	if cur_char == [["]] or cur_char == [[']] then
		return decode_scan_string(s, start_pos)
	end

	if __string_sub(s, start_pos, start_pos + 1) == '/*' then
		return decode(s, decode_scan_comment(s, start_pos))
	end

	return decode_scan_constant(s, start_pos)
end

M.decode = decode

return M
