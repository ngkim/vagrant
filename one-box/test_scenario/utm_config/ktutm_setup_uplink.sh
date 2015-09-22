#!/bin/sh

#filepath
SettingsFile='/var/efw/uplinks/main/settings'

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

echo "AUTOSTART=on" >> $SettingsFile
echo "BACKUPPROFILE=" >> $SettingsFile
echo "CHECKHOSTS=" >> $SettingsFile
lineBuilder "DEFAULT_GATEWAY" $1
lineBuilder "DNS1" $2
lineBuilder "DNS2" $3
echo "ENABLED=on" >> $SettingsFile
echo "MAC=" >> $SettingsFile
echo "MANAGED=" >> $SettingsFile
echo "MTU=" >> $SettingsFile
echo "ONBOOT=on" >> $SettingsFile
lineBuilder "RED_ADDRESS" $4
lineBuilder "RED_BROADCAST" $5
lineBuilder "RED_CIDR" $6
echo "RED_DEV=eth1" >> $SettingsFile
lineBuilder "RED_IPS" $7
lineBuilder "RED_NETADDRESS" $8
lineBuilder "RED_NETMASK" $9
echo "RED_TYPE=STATIC" >> $SettingsFile

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
