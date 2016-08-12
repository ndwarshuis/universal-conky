local c = {}

local Text = require 'Text'

local _TONUMBER = tonumber

local set = function(obj, cr, text, force)
	if text and text ~= obj.pretext then
		obj.value = _TONUMBER(text) or 0

		if force == 0 then
			obj.current_source = obj.critical.source
		elseif force == 1 then
			obj.current_source = obj.source
		else
			if obj.critical.enabled(obj.value) then
				obj.current_source = obj.critical.source
			else
				obj.current_source = obj.source
			end
		end
		Text.set(obj, cr, text)
	end
end

c.draw = Text.draw
c.set = set

return c
