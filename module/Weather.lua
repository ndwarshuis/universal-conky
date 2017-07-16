local _CR			= require 'CR'
local Widget		= require 'Widget'
local Text 			= require 'Text'
local Line 			= require 'Line'
local TextColumn	= require 'TextColumn'
local ScaledImage	= require 'ScaledImage'
local util			= require 'util'
local json			= require 'json'
local schema		= require 'default_patterns'

local _STRING_MATCH = string.match
local _STRING_SUB	= string.sub
local _STRING_UPPER	= string.upper
local _OS_EXECUTE	= os.execute

local TIME_FORMAT = '%-I:%M %p'
local DATE_FORMAT = '%A'

local SECTIONS = 8
local WEATHER_UPDATE_INTERVAL = 900

local WEATHER_PATH = '/tmp/weather.json'
local ICON_PATH = CONSTRUCTION_GLOBAL.ABS_PATH .. '/images/weather/'
local RECENTLY_UPDATED_PATH = '/tmp/weather_recently_updated'
local NA = 'N/A'
local NA_IMAGE_PATH = ICON_PATH .. 'na.png'

--construction params
local SPACING = 20
local HEADER_PAD = 20
local ICON_PAD = 20
local ICON_SIDE_LENGTH = 75
local TEMP_SECTION_WIDTH = 220
local SECTION_HEIGHT = HEADER_PAD + ICON_SIDE_LENGTH + 30

local __create_side_section = function(x_offset, y_offset, section_table)
	for i = 1, SECTIONS do
		section_table[i] = {}
		local current_widget = section_table[i]
		local current_y = y_offset + (i - 1) * SECTION_HEIGHT

		current_widget.desc = Widget.Text{
			x = x_offset,
			y = current_y,
			text_color = schema.blue,
		}
		
		current_widget.period = Widget.Text{
			x 			= x_offset + CONSTRUCTION_GLOBAL.SECTION_WIDTH,
			y 			= current_y,
			x_align 	= 'right',
			text_color 	= schema.blue
		}
		
		current_widget.icon = Widget.ScaledImage{
			x 		= x_offset,
			y 		= current_y + HEADER_PAD,
			width 	= ICON_SIDE_LENGTH,
			height 	= ICON_SIDE_LENGTH
		}

		current_widget.temp1 = Widget.Text{
			x			= x_offset + ICON_SIDE_LENGTH + 0.5 * TEMP_SECTION_WIDTH,
			y 			= current_y + HEADER_PAD + 20,
			x_align		= 'center',
			font_size 	= 28,
			text_color 	= schema.blue
		}
		
		current_widget.temp2 = Widget.Text{
			x			= x_offset + ICON_SIDE_LENGTH + 0.5 * TEMP_SECTION_WIDTH,
			y 			= current_y + HEADER_PAD + 50,
			x_align		= 'center',
			font_size 	= 11
		}

		current_widget.label_column = Widget.TextColumn{
			x = x_offset + ICON_SIDE_LENGTH + TEMP_SECTION_WIDTH,
			y = current_y + HEADER_PAD + 10,
			spacing = SPACING,
			'H',
			'P',
			'W'
		}
		
		current_widget.info_column = Widget.TextColumn{
			x = x_offset + CONSTRUCTION_GLOBAL.SECTION_WIDTH,
			y = current_y + HEADER_PAD + 10,
			spacing = SPACING,
			x_align = 'right',
			text_color = schema.blue,
			num_rows = 3
		}
		
		if i < SECTIONS then
			current_widget.divider = Widget.Line{
				p1 = {
					x = x_offset,
					y = current_y + SECTION_HEIGHT - 18
				},
				p2 = {
					x = x_offset + CONSTRUCTION_GLOBAL.SECTION_WIDTH,
					y = current_y + SECTION_HEIGHT - 18
				},
				line_pattern = schema.mid_grey
			}
		end
	end
end

--LEFT
local left = {
	header = Widget.Header{
		x = CONSTRUCTION_GLOBAL.LEFT_X,
		y = CONSTRUCTION_GLOBAL.TOP_Y,
		width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		header = 'HOURLY FORECAST'
	},
	hours = {}
}

__create_side_section(CONSTRUCTION_GLOBAL.LEFT_X, left.header.bottom_y, left.hours)

--CENTER
local center = {}

center.header = Widget.Header{
	x = CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
	y = CONSTRUCTION_GLOBAL.TOP_Y,
	width = CONSTRUCTION_GLOBAL.CENTER_WIDTH,
	header = 'CURRENT CONDITIONS'
}

center.current_desc = Widget.Text{
	x 			= CONSTRUCTION_GLOBAL.CENTER_LEFT_X,
	y 			= center.header.bottom_y + 8,
	text_color 	= schema.blue,
	font_size	= 24
}

local CENTER_X_1 = CONSTRUCTION_GLOBAL.CENTER_LEFT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH * 0.25
local CENTER_ICON_WIDTH = 120
local CENTER_ICON_Y = center.header.bottom_y + 105 - CENTER_ICON_WIDTH / 2

center.icon = Widget.ScaledImage{
	x = CENTER_X_1 - CENTER_ICON_WIDTH / 2,
	y = CENTER_ICON_Y,
	width = CENTER_ICON_WIDTH,
	height = CENTER_ICON_WIDTH
}

local CENTER_X_2 = CONSTRUCTION_GLOBAL.CENTER_LEFT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH * 0.70
local INFO_Y = center.header.bottom_y + 70

center.current_temp = Widget.Text{
	x 			= CENTER_X_2,
	y 			= INFO_Y,
	x_align 	= 'center',
	font_size 	= 48,
	text_color 	= schema.blue
}

center.obs_time = Widget.Text{
	x 			= CENTER_X_2,
	y 			= INFO_Y + 42,
	x_align 	= 'center',
	font_size 	= 12,
}

center.place = Widget.Text{
	x 			= CENTER_X_2,
	y 			= INFO_Y + 66,
	x_align 	= 'center',
	font_size 	= 12,
}

local COLUMN_PADDING = 15
local CENTER_SPACING = SPACING + 7

center.label_column_1 = Widget.TextColumn{
	x 			= CONSTRUCTION_GLOBAL.CENTER_RIGHT_X,
	y 			= center.header.bottom_y,
	spacing 	= CENTER_SPACING,
	font_size 	= 14,
	'Feels Like',
	'Dewpoint',
	'Humidity',
	'Sky Coverage',
	'Visibility',
	'Ceiling',
	'Precipitation'
}

center.info_column_1 = Widget.TextColumn{
	x 			= CONSTRUCTION_GLOBAL.CENTER_RIGHT_X + (CONSTRUCTION_GLOBAL.SECTION_WIDTH - COLUMN_PADDING) / 2,
	y 			= center.header.bottom_y,
	x_align 	= 'right',
	text_color 	= schema.blue,
	spacing 	= CENTER_SPACING,
	font_size 	= 14,
	num_rows 	= 7
}

center.label_column_2 = Widget.TextColumn{
	x 		= CONSTRUCTION_GLOBAL.CENTER_RIGHT_X + (CONSTRUCTION_GLOBAL.SECTION_WIDTH + COLUMN_PADDING) / 2,
	y 		= center.header.bottom_y,
	spacing = CENTER_SPACING,
	font_size 	= 14,
	'WindSpd',
	'WindGust',
	'WindDir',
	'Pressure',
	'Sunrise',
	'Sunset',
	'Light Rate'
}

center.info_column_2 = Widget.TextColumn{
	x 		= CONSTRUCTION_GLOBAL.CENTER_RIGHT_X + CONSTRUCTION_GLOBAL.SECTION_WIDTH,
	y 		= center.header.bottom_y,
	x_align 	= 'right',
	text_color 	= schema.blue,
	spacing 	= CENTER_SPACING,
	font_size 	= 14,
	num_rows 	= 7
}

--RIGHT

local right = {
	header = Widget.Header{
		x = CONSTRUCTION_GLOBAL.RIGHT_X,
		y = CONSTRUCTION_GLOBAL.TOP_Y,
		width = CONSTRUCTION_GLOBAL.SECTION_WIDTH,
		header = '8 DAY FORECAST'
	},
	days = {}
}

__create_side_section(CONSTRUCTION_GLOBAL.RIGHT_X, right.header.bottom_y, right.days)

Widget = nil
schema = nil

SPACING = nil
HEADER_BOTTOM_Y = nil
SECTION_HEIGHT = nil
INFO_Y = nil
TEXT_1_PAD = nil
TEXT_1_X = nil
COLUMN_WIDTH = nil
LABEL_COLUMN_1_X = nil
CENTER_SPACING = nil

local __populate_section = function(current_section, cr, desc, period, icon_path, temp1, temp2, humidity, pop, wind)
	if desc then
		Text.set(current_section.desc, cr, Text.trim_to_length(desc, 20))
	else
		Text.set(current_section.desc, cr, NA)
	end
	
	Text.set(current_section.period, cr, period or NA)

	ScaledImage.set(current_section.icon, icon_path or NA_IMAGE_PATH)

	Text.set(current_section.temp1, cr, temp1 or NA)
	Text.set(current_section.temp2, cr, temp2 or NA)

	TextColumn.set(current_section.info_column, cr, 1, humidity or NA)
	TextColumn.set(current_section.info_column, cr, 2, pop or NA)
	TextColumn.set(current_section.info_column, cr, 3, wind or NA)
end

local __populate_center = function(center_section, cr, desc, icon_path, temp,
  obs_time, place, feels_like, dewpoint, humidity, coverage, visibility, ceiling,
  precip, wind_spd, wind_gust_spd, wind_dir, pressure, sunrise, sunset, light)
  
	if desc then
		Text.set(center_section.current_desc, cr, Text.trim_to_length(desc, 20))
	else
		Text.set(center_section.current_desc, cr, NA)
	end

	ScaledImage.set(center_section.icon, icon_path or NA_IMAGE_PATH)
	
	Text.set(center_section.current_temp, cr, temp or NA)
	Text.set(center_section.obs_time, cr, obs_time or NA)
	Text.set(center_section.place, cr, place or NA)

	local info_column_1 = center_section.info_column_1

	TextColumn.set(info_column_1, cr, 1, feels_like or NA)
	TextColumn.set(info_column_1, cr, 2, dewpoint or NA)
	TextColumn.set(info_column_1, cr, 3, humidity or NA)
	TextColumn.set(info_column_1, cr, 4, coverage or NA)
	TextColumn.set(info_column_1, cr, 5, visibility or NA)
	TextColumn.set(info_column_1, cr, 6, ceiling or NA)
	TextColumn.set(info_column_1, cr, 7, precip or NA)

	local info_column_2 = center_section.info_column_2

	TextColumn.set(info_column_2, cr, 1, wind_spd or NA)
	TextColumn.set(info_column_2, cr, 2, wind_gust_spd or NA)
	TextColumn.set(info_column_2, cr, 3, wind_dir or NA)
	TextColumn.set(info_column_2, cr, 4, pressure or NA)
	TextColumn.set(info_column_2, cr, 5, sunrise or NA)
	TextColumn.set(info_column_2, cr, 6, sunset or NA)
	TextColumn.set(info_column_2, cr, 7, light or NA)
end

local __update_interface = function(cr)
	local file = util.read_file(WEATHER_PATH)
	local data = (file ~= '') and json.decode(file)
	
	if data then
		data = data.response.responses

		if data[1].success == false then
			for i = 1, SECTIONS do	__populate_section(left.hours[i], cr) end

			__populate_center(center, cr, nil, nil, nil, nil, 'Invalid Location')

			for i = 1, SECTIONS do __populate_section(right.days[i], cr) end
		else
			--LEFT
			local hourly = data[2].response[1].periods

			for i = 1, SECTIONS do
				local hour_data = hourly[i]

				__populate_section(
					left.hours[i],
					cr,
					hour_data.weatherPrimary,
					hour_data.timestamp and util.convert_unix_time(hour_data.timestamp, TIME_FORMAT),
					hour_data.icon and ICON_PATH..hour_data.icon,
					hour_data.avgTempF and hour_data.avgTempF..'°F',
					hour_data.feelslikeF  and 'Feels like '..hour_data.feelslikeF..'°F',
					hour_data.humidity and hour_data.humidity..' %',
					hour_data.pop and hour_data.pop..' %',
					hour_data.windSpeedMPH and hour_data.windSpeedMPH..' mph'
				)
			end

			--CENTER
			local current_data = data[1].response
			local ob = current_data.ob

			local place
			if current_data.place then
				place = current_data.place.name
				if place then place = util.capitalize_each_word(_STRING_MATCH(place, '([%w%s]+)/?')) end

				local state = current_data.place.state
				if state == '' then state = nil end
				
				if place and state then
					place =  place..', '.._STRING_UPPER(state)
				elseif place then
					local country = current_data.place.country
					if country then place = place..', '.._STRING_UPPER(country) end
				end
			end
			
			__populate_center(
				center,
				cr,
				ob.weather,
				ob.icon and ICON_PATH..ob.icon,
				ob.tempF and ob.tempF..'°F',
				ob.timestamp and util.convert_unix_time(ob.timestamp, TIME_FORMAT),
				place,
				ob.feelslikeF and ob.feelslikeF..'°F',
				ob.dewpointF and ob.dewpointF..'°F',
				ob.humidity and ob.humidity..' %',
				ob.sky and ob.sky..' %',
				ob.visibilityMI and ob.visibilityMI..' mi',
				ob.ceilingFT and ob.ceilingFT..' ft',
				ob.precipIN and ob.precipIN..' in',
				ob.windSpeedMPH and ob.windSpeedMPH..' mph',
				ob.windGustMPH and ob.windGustMPH..' mph',
				ob.windDirDEG and ob.windDirDEG..' deg',
				ob.pressureMB and ob.pressureMB..' mbar',
				ob.sunrise and util.convert_unix_time(ob.sunrise, TIME_FORMAT),
				ob.sunset and util.convert_unix_time(ob.sunset, TIME_FORMAT),
				ob.light and ob.light..' %'
			)

			--RIGHT
			local daily = data[3].response[1].periods
			
			for i = 1, SECTIONS do
				local day_data = daily[i]

				__populate_section(
					right.days[i],
					cr,
					day_data.weatherPrimary,
					day_data.timestamp and _STRING_SUB(util.convert_unix_time(
					  day_data.timestamp, DATE_FORMAT), 1, 3),
					day_data.icon and ICON_PATH..day_data.icon,
					day_data.maxTempF and day_data.maxTempF..'°F',
					day_data.minTempF and 'Low of  '..day_data.minTempF..'°F',
					day_data.humidity and day_data.humidity..' %',
					day_data.pop and day_data.pop..' %',
					day_data.windSpeedMPH and day_data.windSpeedMPH..' mph'
				)
			end
		end
	else
		for i = 1, SECTIONS do	__populate_section(left.hours[i], cr) end

		__populate_center(center, cr)

		for i = 1, SECTIONS do __populate_section(right.days[i], cr) end
	end
end

local __draw_sections = function(section_group, cr)
	for i = 1, SECTIONS do
		local section = section_group[i]
		
		if i < SECTIONS then Line.draw(section.divider, cr) end
		
		Text.draw(section.desc, cr)
		Text.draw(section.period, cr)
		ScaledImage.draw(section.icon)
		Text.draw(section.temp1, cr)
		Text.draw(section.temp2, cr)
		TextColumn.draw(section.label_column, cr)
		TextColumn.draw(section.info_column, cr)
	end
end

__update_interface(_CR)

_CR = nil

_OS_EXECUTE('get_weather.sh')

local update_cycle = WEATHER_UPDATE_INTERVAL

local draw = function(cr, interface, trigger)
	if update_cycle == 0 then _OS_EXECUTE('get_weather.sh') end

	local recently_updated = util.read_file(RECENTLY_UPDATED_PATH, nil, '*n')

	if recently_updated == 1 then
		update_cycle = WEATHER_UPDATE_INTERVAL
		util.write_file(RECENTLY_UPDATED_PATH, 0)
	end

	if recently_updated == 1 or trigger == 0 then __update_interface(cr) end

	update_cycle = update_cycle - 1

	if interface == 1 then
		--LEFT
		Text.draw(left.header.text, cr)
		Line.draw(left.header.underline, cr)

		__draw_sections(left.hours, cr)

		--CENTER
		Text.draw(center.header.text, cr)
		Line.draw(center.header.underline, cr)

		Text.draw(center.current_desc, cr)
		ScaledImage.draw(center.icon)
		Text.draw(center.current_temp, cr)
		Text.draw(center.obs_time, cr)
		Text.draw(center.place, cr)

		TextColumn.draw(center.label_column_1, cr)
		TextColumn.draw(center.info_column_1, cr)
		TextColumn.draw(center.label_column_2, cr)
		TextColumn.draw(center.info_column_2, cr)

		--RIGHT
		Text.draw(right.header.text, cr)
		Line.draw(right.header.underline, cr)

		__draw_sections(right.days, cr)
	end
end

return draw
