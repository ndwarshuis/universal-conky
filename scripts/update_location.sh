#!/bin/bash

location=$(zenity --text "Enter current location in one of the following formats

lat,lon
city,state,[country]
city,country
zip
airport" --entry)

location=${location//" "/"+"}
retval=$?
case $retval in
	0)
		echo "$location" > $CONKY_LUA_HOME/scripts/location
		get_weather.sh;;
	1)
		echo "Cancel pressed.";;
esac
