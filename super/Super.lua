local c = {}

local Gradient 	= require 'Gradient'
local schema	= require 'default_patterns'

local _TONUMBER = tonumber
local _STRING_SUB = string.sub

--Pattern(pattern, [p1], [p2], [r1], [r2], [key])
local initPattern = function(arg)

	local pattern 	= arg.pattern
	local p1 		= arg.p1
	local p2 		= arg.p2
	local r1 		= arg.r1
	local r2 		= arg.r2
	
	if p1 and p2 and pattern and pattern.ptype == 'Gradient' then		
		Gradient(pattern, p1, p2, r1, r2)
	end

	return pattern.userdata
end

--Critical([critical_pattern], [critical_limit], [p1], [p2], [r1], [r2])

local CRITICAL_PATTERN = schema.red
local CRITICAL_LIMIT = '>80'

local CRITICAL_CREATE_FUNCTION = function(limit)
	local compare = limit and _STRING_SUB(limit, 1, 1)
	local value = limit and _TONUMBER(_STRING_SUB(limit, 2))

	if compare == '>' then return function(n) return (n > value) end end
	if compare == '<' then return function(n) return (n < value) end end
	return function(n) return nil end	--if no limit then return dummy
end

local initCritical = function(arg)

	local obj = {
		source = initPattern{
			pattern	= arg.critical_pattern or CRITICAL_PATTERN,
			p1 		= arg.p1,
			p2 		= arg.p2,
			r1 		= arg.r1,
			r2 		= arg.r2,
		},
		enabled = CRITICAL_CREATE_FUNCTION(arg.critical_limit or CRITICAL_LIMIT)
	}

	return obj
end

c.Pattern = initPattern
c.Critical = initCritical

return c
