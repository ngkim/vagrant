#!/bin/bash

#LineBuilder Function
lineBuilder () {
    if [ "$2" != "EMPTY" ] && [ "$2" != "empty" ]
    then
        echo "$1=$2" >> $SettingsFile
    else
        echo "$1=" >> $SettingsFile
    fi
}

SettingsFile="/var/efw/zonefw/config"

#make a setting file for parameters
rm -f $SettingsFile

echo "on,,,,,ALLOW,,,,GREEN&BLUE&ORANGE,GREEN&BLUE&ORANGE" > $SettingsFile

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
