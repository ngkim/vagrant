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

SettingsFile="/var/efw/dnat/config"

#make a setting file for parameters
rm -f $SettingsFile

RED_IP=${1}
WAF_IP=${2}

RED_PORT1=9999
WAF_PORT1=80

RED_PORT2=5001
WAF_PORT2=5001

echo "on,tcp&udp,,any,${RED_IP}:UPLINK:main,,${RED_PORT1},${WAF_IP},${WAF_PORT1},DNAT,,,ALLOW" > $SettingsFile
echo "on,tcp&udp,,any,${RED_IP}:UPLINK:main,,${RED_PORT2},${WAF_IP},${WAF_PORT2},DNAT,,,ALLOW" > $SettingsFile

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
