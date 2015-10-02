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

SettingsFile="/var/efw/snat/config"
SettingsFile1="/var/efw/outgoing/config"

#make a setting file for parameters
rm -f $SettingsFile

RED_IP=${1}
GRN_SBNET=${2}
ORG_SBNET=${3}

echo "on,,${GRN_SBNET}&${ORG_SBNET},,,UPLINK:main,SNAT,,,${RED_IP}" > $SettingsFile
echo "on,,,,,ACCEPT,,,,GREEN,UPLINK:main," > $SettingsFile1

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
