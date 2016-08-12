local c = {}

local _STRING_GSUB 	= string.gsub
local _STRING_CHAR 	= string.char
local _STRING_FIND 	= string.find
local _STRING_SUB 	= string.sub
local _TABLE_CONCAT = table.concat
local _MATH_FLOOR 	= math.floor
local _PAIRS 		= pairs
local _TONUMBER 	= tonumber

local decode -- to ref this before definition

local decode_scanWhitespace = function(s, startPos)
	local whitespace = " \n\r\t"
	local stringLen = #s
	
	while (_STRING_FIND(whitespace, _STRING_SUB(s, startPos, startPos), 1, true) and
	  startPos <= stringLen) do
		startPos = startPos + 1
	end
	return startPos
end

local decode_scanArray = function(s, startPos)
	local array = {}
	local stringLen = #s
	
	--~ assert(_STRING_SUB(s, startPos, startPos) == '[',
	  --~ 'decode_scanArray called but array does not start at position ' .. startPos ..
	  --~ ' in string:\n'..s )

	startPos = startPos + 1

	repeat
		startPos = decode_scanWhitespace(s, startPos)
		--~ assert(startPos <= stringLen, 'JSON String ended unexpectedly scanning array.')
		
		local curChar = _STRING_SUB(s,startPos,startPos)
		
		if (curChar == ']') then
			return array, startPos + 1
		end
		
		if (curChar == ',') then
			startPos = decode_scanWhitespace(s, startPos + 1)
		end
		
		--~ assert(startPos <= stringLen, 'JSON String ended unexpectedly scanning array.')
		object, startPos = decode(s, startPos)
		array[#array + 1] = object
	until false
end

local decode_scanComment = function(s, startPos)
	--~ assert(_STRING_SUB(s, startPos, startPos + 1) == '/*',
	  --~ "decode_scanComment called but comment does not start at position " .. startPos)
		
	local endPos = _STRING_FIND(s, '*/', startPos + 2)
	--~ assert(endPos ~= nil, "Unterminated comment in string at " .. startPos)
	return endPos + 2
end

local decode_scanConstant = function(s, startPos)
	local consts = {["true"] = true, ["false"] = false,	["null"] = nil}
	local constNames = {"true", "false", "null"}
	
	for _, k in _PAIRS(constNames) do
		if _STRING_SUB(s, startPos, startPos + #k - 1 ) == k then
			return consts[k], startPos + #k
		end
	end
	--~ assert(nil, 'Failed to scan constant from string ' .. s .. ' at starting position ' ..
	  --~ startPos)
end

local decode_scanNumber = function(s, startPos)
	local endPos = startPos + 1
	local stringLen = #s
	local acceptableChars = "+-0123456789.e"
	
	while (_STRING_FIND(acceptableChars, _STRING_SUB(s, endPos, endPos), 1, true)
	  and endPos <= stringLen) do
		endPos = endPos + 1
	end

	local numberString = _STRING_GSUB(_STRING_SUB(s, startPos, endPos - 1), '+', '')
	return _TONUMBER(numberString), endPos
end

local decode_scanObject = function(s, startPos)
	local object = {}
	local stringLen = #s
	local key, value
	
	--~ assert(_STRING_SUB(s, startPos, startPos) == '{',
	  --~ 'decode_scanObject called but object does not start at position ' .. startPos ..
	  --~ ' in string:\n' .. s)
	  
	startPos = startPos + 1
	
	repeat
		startPos = decode_scanWhitespace(s, startPos)
		
		--~ assert(startPos <= stringLen, 'JSON string ended unexpectedly while scanning object.')
		
		local curChar = _STRING_SUB(s, startPos, startPos)
		
		if (curChar == '}') then
			return object, startPos + 1
		end
		
		if (curChar == ',') then
			startPos = decode_scanWhitespace(s, startPos + 1)
		end
		
		--~ assert(startPos <= stringLen, 'JSON string ended unexpectedly scanning object.')
		
		-- Scan the key
		key, startPos = decode(s, startPos)
		
		--~ assert(startPos <= stringLen,
		  --~ 'JSON string ended unexpectedly searching for value of key ' .. key)
			
		startPos = decode_scanWhitespace(s, startPos)
		
		--~ assert(startPos <= stringLen,
		  --~ 'JSON string ended unexpectedly searching for value of key ' .. key)
			
		--~ assert(_STRING_SUB(s, startPos, startPos) == ':',
		  --~ 'JSON object key-value assignment mal-formed at ' .. startPos)
			
		startPos = decode_scanWhitespace(s, startPos + 1)

		--~ assert(startPos <= stringLen,
		  --~ 'JSON string ended unexpectedly searching for value of key ' .. key)
			
		value, startPos = decode(s, startPos)
		
		object[key] = value
	until false
end

local escapeSequences = {
	["\\t"] = "\t",
	["\\f"] = "\f",
	["\\r"] = "\r",
	["\\n"] = "\n",
	["\\b"] = "\b"
}

setmetatable(escapeSequences, {__index = function(t, k)	return _STRING_SUB(k, 2) end})--skip "\"

local decode_scanString = function (s, startPos)
	--~ assert(startPos, 'decode_scanString(..) called without start position')
	
	local startChar = _STRING_SUB(s, startPos, startPos)
	
	--~ assert(startChar == [["]] or startChar == [[']],
	  --~ 'decode_scanString called for a non-string')
	
	local t = {}
	local i, j = startPos, startPos
	
	while _STRING_FIND(s, startChar, j + 1) ~= j + 1 do
		local oldj = j
		local x, y = _STRING_FIND(s, startChar, oldj + 1)
		
		i, j = _STRING_FIND(s, "\\.", j + 1)
		
		if not i or x < i then i, j = x, y - 1 end
		
		--~ table.insert(t, _STRING_SUB(s, oldj + 1, i - 1))
		t[#t + 1] = _STRING_SUB(s, oldj + 1, i - 1)
		
		if _STRING_SUB(s, i, j) == "\\u" then
			local a = _STRING_SUB(s, j + 1, j + 4)
			local n = _TONUMBER(a, 16)
			local x
			
			j = j + 4
			
			--~ assert(n, "String decoding failed: bad Unicode escape " .. a .. " at position " ..
			  --~ i .. " : " .. j)
				
			if n < 0x80 then
				x = _STRING_CHAR(n % 0x80)
			elseif n < 0x800 then
				x = _STRING_CHAR(0xC0 + (_MATH_FLOOR(n / 64) % 0x20), 0x80 + (n % 0x40))
			else
				x = _STRING_CHAR(0xE0 + (_MATH_FLOOR(n / 4096) % 0x10), 0x80 +
				  (_MATH_FLOOR(n / 64) % 0x40), 0x80 + (n % 0x40))
			end
		
			--~ table.insert(t, x)
			t[#t + 1] = x
		else
			--~ table.insert(t, escapeSequences[_STRING_SUB(s, i, j)])
			t[#t + 1] = escapeSequences[_STRING_SUB(s, i, j)]
		end
	end
	--~ table.insert(t, _STRING_SUB(j, j + 1))
	t[#t + 1] = _STRING_SUB(j, j + 1)
	
	--~ assert(_STRING_FIND(s, startChar, j + 1), "String decoding failed: missing closing " ..
	  --~ startChar .. " at position " .. j .. "(for string at position " .. startPos .. ")")
		
	return _TABLE_CONCAT(t, ""), j + 2
end

decode = function(s, startPos)
	startPos = startPos or 1
	startPos = decode_scanWhitespace(s, startPos)
	
	--~ assert(startPos <= #s,
	  --~ 'Unterminated JSON encoded object found at position in [' .. s .. ']')
		
	local curChar = _STRING_SUB(s, startPos, startPos)
	
	if curChar == '{' then
		return decode_scanObject(s, startPos)
	end
	
	if curChar == '[' then
		return decode_scanArray(s, startPos)
	end

	if _STRING_FIND("+-0123456789.e", curChar, 1, true) then
		return decode_scanNumber(s, startPos)
	end

	if curChar == [["]] or curChar == [[']] then
		return decode_scanString(s, startPos)
	end

	if _STRING_SUB(s, startPos, startPos + 1) == '/*' then
		return decode(s, decode_scanComment(s, startPos))
	end

	return decode_scanConstant(s, startPos)
end

c.decode = decode

return c
