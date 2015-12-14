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

SettingsFile="/var/efw/xtaccess/config"

#make a setting file for parameters
rm -f $SettingsFile

SBNET_LIST=$1
HOST_LIST=$2
PORT_LIST=$3

echo "tcp,${SBNET_LIST}&${HOST_LIST},${PORT_LIST},on,,ANY,,INPUTFW,ACCEPT,,"
echo "tcp,${SBNET_LIST}&${HOST_LIST},${PORT_LIST},on,,ANY,,INPUTFW,ACCEPT,," > $SettingsFile

#retrun result
if [ -e $SettingsFile ]
then
    echo "0:OK"
    exit 0
else
    echo "1:Failure"
    exit 1
fi
