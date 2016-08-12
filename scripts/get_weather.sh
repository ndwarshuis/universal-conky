#!/bin/bash

#read location
location_string=$(cat $CONKY_LUA_HOME/scripts/location)

#get weather
weather_url="http://api.aerisapi.com/batch/"

o_fields="fields=\
place.name,\
place.state,\
place.country,\
ob.timestamp,\
ob.tempF,\
ob.dewpointF,\
ob.sky,\
ob.humidity,\
ob.pressureMB,\
ob.windSpeedMPH,\
ob.windDirDEG,\
ob.weather,\
ob.feelslikeF,\
ob.icon,\
ob.sunrise,\
ob.sunset,\
ob.precipIN"

observations="/observations%3F$o_fields"

h_fields="fields=\
periods.timestamp,\
periods.avgTempF,\
periods.feelslikeF,\
periods.pop,\
periods.humidity,\
periods.windSpeedMPH,\
periods.icon,\
periods.weatherPrimary"

hourly="/forecasts%3Ffilter=4hr%26limit=6%26$h_fields"

d_fields="fields=\
periods.timestamp,\
periods.minTempF,\
periods.maxTempF,\
periods.pop,\
periods.humidity,\
periods.windDir,\
periods.icon,\
periods.windSpeedMPH,\
periods.weatherPrimary"

daily="/forecasts%3Ffrom=tomorrow%26limit=6%26$d_fields"

alerts="/alerts"

id="client_id=TdJ5M1pUXWUUebhfRKSs2"
secret="client_secret=DmI2NHCO6BQ5hSH4yAECVJlgA8gYZ1C4BvNaGEuM"

curl -s "$weather_url$location_string?requests=$observations,$hourly,$daily&$id&$secret" > /tmp/weather.json && \
echo 1 > /tmp/weather_recently_updated &
