#!/bin/bash

## JH: v1.0 - Weather Underground to pwsweather.com script test
FILE=$(mktemp --suffix=.json)

# Wunderground API key
# Register for a free Stratus plan here: https://www.wunderground.com/weather/api
WUAPI=$1

# Wunderground PWS to pull weather from
# Navigate to your preferred weather station on Weather Underground and pull the pws:XXXXXXXXXX from the URL
# ex. https://www.wunderground.com/cgi-bin/findweather/getForecast?query=pws:KFLLAKEW61&MR=1
# ex. WUPWS would be the query value - "pws:KFLLAKEW61"
#WUPWS="pws:KFLLAKEW53"
WUPWS="$2"

#PWS station ID - sign up and create a station at pwsweather.com
PWSID=$2

#PWS password - password for pwsweather.com
PWSPASS=$3

#============================================================
#=
#=      NOT NECESSARY TO CHANGE ANY LINES BELOW
#=
#============================================================

# Construct & Execute Weather Underground API call
WUJSON="https://api.weather.com/v2/pws/observations/current?stationId=$WUPWS&format=json&units=e&apiKey=$WUAPI"
echo "Grabbing JSON using the following URL: $WUJSON"
echo ""
wget -O $FILE $WUJSON

# ALL json extractions below REQUIRE the jq cmd line tool - on Ubuntu 'apt-get install jq'
#
# extract observation time and convert to UTC
# jq .observations[].observation_epoch wu.json |tr -d '"'
# TZ=UTC date -d @1459187921 +'%Y-%m-%d+%H:%M:%S'|sed 's/:/%3A/g'
PWSDATEUTC=$(TZ=UTC date -d $(jq .observations[].obsTimeUtc $FILE |tr -d '"') +'%Y-%m-%d %H:%M:%S'|sed 's/:/%3A/g'|sed 's/ /%20/g')
echo "PWSDATEUTC=$PWSDATEUTC"

# extract winddir
PWSWINDDIR=$(jq .observations[].winddir $FILE |tr -d '"')
echo "PWSWINDDIR=$PWSWINDDIR"
if [[ $PWSWINDDIR != "null" ]]
then
  PWSWINDDIR="&winddir=$PWSWINDDIR"
else
  PWSWINDDIR=""
fi

# extract windspeed
PWSWINDSPEEDMPH=$(jq .observations[].imperial.windSpeed $FILE |tr -d '"')
echo "PWSWINDSPEEDMPH=$PWSWINDSPEEDMPH"
if [[ $PWSWINDSPEEDMPH != "null" ]]
then
  PWSWINDSPEEDMPH="&windspeedmph=$PWSWINDSPEEDMPH"
else
  PWSWINDSPEEDMPH=""
fi

# extract windgustmph
PWSWINDGUSTMPH=$(jq .observations[].imperial.windGust $FILE |tr -d '"')
echo "PWSWINDGUSTMPH=$PWSWINDGUSTMPH"
if [[ $PWSWINDGUSTMPH != "null" ]]
then
  PWSWINDGUSTMPH="&windgustmph=$PWSWINDGUSTMPH"
else
  PWSWINDGUSTMPH=""
fi

# extract tempf
PWSTEMPF=$(jq .observations[].imperial.temp $FILE |tr -d '"')
echo "PWSTEMPF=$PWSTEMPF"

# extract hourly rainin - Hourly rain in inches
PWSRAININ=$(jq .observations[].imperial.precipRate $FILE |tr -d '"')
echo "PWSRAININ=$PWSRAININ"


# extract daily rainin - Daily rain in inches
PWSDAILYRAININ=$(jq .observations[].imperial.precipTotal $FILE |tr -d '"')
echo "PWSDAILYRAININ=$PWSDAILYRAININ"

# extract baromin - Barometric pressure in inches
PWSBAROMIN=$(jq .observations[].imperial.pressure $FILE |tr -d '"')
echo "PWSBAROMIN=$PWSBAROMIN"

# extract dewptf - Dew point in degrees f
PWSDEWPTF=$(jq .observations[].imperial.dewpt $FILE |tr -d '"')
echo "PWSDEWPTF=$PWSDEWPTF"

# extract humidity - in percent
PWSHUMIDITY=$(jq .observations[].humidity $FILE |tr -d '"' |tr -d '%')
echo "PWSHUMIDITY=$PWSHUMIDITY"

# extract solarradiation
PWSSOLARRADIATION=$(jq .observations[].solarRadiation $FILE |tr -d '"'|tr -d '-')
echo "PWSSOLARRADIATION=$PWSSOLARRADIATION"
if [[ $PWSSOLARRADIATION != "null" ]]
then
  PWSSOLARRADIATION="&solarradiation=$PWSSOLARRADIATION"
else
  PWSSOLARRADIATION=""
fi

# extract UV
PWSUV=$(jq .observations[].uv $FILE |tr -d '"')
echo "PWSUV=$PWSUV"
if [[ $PWSUV != "null" ]]
then
  PWSUV="&uv=$PWSUV"
else
  PWSUV=""
fi

# construct PWS weather POST data string

PWSPOST="ID=$PWSID&PASSWORD=$PWSPASS&dateutc=${PWSDATEUTC}${PWSWINDDIR}${PWSWINDSPEEDMPH}${PWSWINDGUSTMPH}&tempf=$PWSTEMPF&rainin=$PWSRAININ&dailyrainin=$PWSDAILYRAININ&baromin=$PWSBAROMIN&dewptf=$PWSDEWPTF&humidity=${PWSHUMIDITY}${PWSSOLARRADIATION}${PWSUV}&action=updateraw"
#echo $PWSPOST

RESULT=$(wget -O /dev/null --post-data=$PWSPOST https://www.pwsweather.com/pwsupdate/pwsupdate.php)
echo wget -O /dev/null --post-data=$PWSPOST https://www.pwsweather.com/pwsupdate/pwsupdate.php

rm $FILE
