#!/bin/sh

#filepath for settings
SettingsFile='/var/efw/ethernet/settings'

#LineBuilder Function
lineBuilder () {
    if [ "$2" != "EMPTY" ] && [ "$2" != "empty" ]
    then
        echo "$1=$2" >> $SettingsFile
    else
        echo "$1=" >> $SettingsFile
    fi
}

#make a setting file for parameters
rm -f $SettingsFile

echo "BLUE_DEV=br2" >> $SettingsFile
echo "CONFIG_TYPE=3" >> $SettingsFile
lineBuilder "GREEN_ADDRESS" $1
lineBuilder "GREEN_BROADCAST" $2
lineBuilder "GREEN_IPS" $3
lineBuilder "GREEN_NETADDRESS" $4
lineBuilder "ORANGE_ADDRESS" $5
lineBuilder "ORANGE_BROADCAST" $6
lineBuilder "ORANGE_CIDR" $7
echo "ORANGE_DEV=br1" >> $SettingsFile
lineBuilder "ORANGE_IPS" $8
lineBuilder "ORANGE_NETADDRESS" $9
lineBuilder "ORANGE_NETMASK" ${10}

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
