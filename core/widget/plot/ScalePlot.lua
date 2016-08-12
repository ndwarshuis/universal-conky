local c = {}

local LabelPlot = require 'LabelPlot'

local _TABLE_INSERT	= table.insert
local _TABLE_REMOVE	= table.remove

local __scale_data = function(obj, cr, new_domain, new_factor)
	local y = obj.y
	local current_factor = obj.scale.factor
	local data = obj.plot.data
	local h = obj.plot.height
	for i = 1, #data do
		data[i] = y + h * (1 - (1 - (data[i] - y) / h) * (new_factor / current_factor))
	end
	obj.scale.domain = new_domain
	obj.scale.factor = new_factor
	LabelPlot.populate_y_labels(obj, cr, 1 / new_factor)
	LabelPlot.position_x_labels(obj)
	LabelPlot.position_x_intrvls(obj.plot)
	LabelPlot.position_y_intrvls(obj.plot)
	LabelPlot.position_graph_outline(obj.plot)
end

local update = function(obj, cr, value)
	local scale = obj.scale
	local new_domain, new_factor = obj.scale._func(value)
	
	--###tick/tock timers
	
	local timers = scale.timers
	local n = #timers
	for i = n, 1, -1 do
		local current_timer = timers[i]
		current_timer.remaining = current_timer.remaining - 1
		if current_timer.remaining == 0 then
			_TABLE_REMOVE(timers, i)
			n = n - 1
		end
	end

	--###create/destroy timers
	if new_domain > scale.previous_domain then						--zap all timers less than/equal to s
		for i = n, 1, -1 do
			if timers[i].domain <= new_domain then
				_TABLE_REMOVE(timers, i)
				n = n - 1
			end
		end
	elseif new_domain < scale.previous_domain then					--create new timer for prev_s
		timers[n + 1] = {
			domain = scale.previous_domain,
			factor = scale.previous_factor,
			remaining = obj.plot.data.n
		}
		n = n + 1
	end
	
	--###scale data
	
	if new_domain > scale.domain then 								--scale up
		__scale_data(obj, cr, new_domain, new_factor)
	elseif new_domain < scale.domain then							--check timers
		if n == 0 then 												--scale down bc no timers to block
			__scale_data(obj, cr, new_domain, new_factor)
		elseif scale.timers[1].domain < scale.domain then			--scale down to active timer
			__scale_data(obj, cr, scale.timers[1].domain, scale.timers[1].factor)
		end
	end
	
	scale.previous_domain = new_domain
	scale.previous_factor = new_factor
	
	local data = obj.plot.data

	_TABLE_INSERT(data, 1, obj.y + obj.plot.height * (1 - value * scale.factor))
	if #data == data.n + 2 then data[#data] = nil end
	--~ print('----------------------------------------------------------------------')
	--~ print('value', value, 'f', scale.factor, 's', scale.domain, 'curr_s', scale.previous_domain)
	--~ for i, v in pairs(timers) do
		--~ print('timers', 'i', i, 's', v.domain, 't', v.remaining, 'f', v.factor)
	--~ end
	--~ print('length', #timers)
end

c.draw = LabelPlot.draw
c.update = update

return c
