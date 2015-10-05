#!/bin/sh

#filepath for settings
SettingsFile='/var/efw/ethernet/settings'
GreenSettingsFile='/var/efw/ethernet/br0'
OrangeSettingsFile='/var/efw/ethernet/br1'
BlueSettingsFile='/var/efw/ethernet/br2'

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

echo "CONFIG_TYPE=5" >> $SettingsFile
lineBuilder "GREEN_ADDRESS" $1
lineBuilder "GREEN_BROADCAST" $2
lineBuilder "GREEN_IPS" $3
lineBuilder "GREEN_NETADDRESS" $4
echo "ORANGE_DEV=br1" >> $SettingsFile
lineBuilder "ORANGE_ADDRESS" $5
lineBuilder "ORANGE_BROADCAST" $6
lineBuilder "ORANGE_CIDR" $7
lineBuilder "ORANGE_IPS" $8
lineBuilder "ORANGE_NETADDRESS" $9
lineBuilder "ORANGE_NETMASK" ${10}
echo "BLUE_DEV=br2" >> $SettingsFile
lineBuilder "BLUE_ADDRESS" ${11}
lineBuilder "BLUE_BROADCAST" ${12}
lineBuilder "BLUE_CIDR" ${13}
lineBuilder "BLUE_IPS" ${14}
lineBuilder "BLUE_NETADDRESS" ${15}
lineBuilder "BLUE_NETMASK" ${16}


echo "eth2" > $GreenSettingsFile
echo "eth3" > $OrangeSettingsFile
echo "eth4" > $BlueSettingsFile

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
