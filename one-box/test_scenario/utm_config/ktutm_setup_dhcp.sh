#!/bin/sh

#FilePath for settings
SettingsFile='/var/efw/dhcp/settings'

#LineBuilder Function
lineBuilder () {
    if [ "$2" != "EMPTY" ] && [ "$2" != "empty" ]
    then
        echo "$1=$2" >> $SettingsFile
    else
        echo "$1=" >> $SettingsFile
    fi
}

#write lines
rm -f $SettingsFile

lineBuilder "DNS1_GREEN" $1
lineBuilder "DOMAIN_NAME_GREEN" $2
lineBuilder "ENABLE_GREEN" $3
lineBuilder "END_ADDR_GREEN" $4
lineBuilder "GATEWAY_GREEN" $5
lineBuilder "START_ADDR_GREEN" $6

#return result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
