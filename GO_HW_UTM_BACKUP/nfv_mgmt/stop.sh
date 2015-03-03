#!/bin/bash

_stop() {
  MAIN_PY=$1
  PID_FILE=".${MAIN_PY}.pid"

  if [ -f $PID_FILE ]; then
    _PID=`cat $PID_FILE`
  fi

  if [ ! -z $_PID ]; then
    echo "* KILL $MAIN_PY"
    kill $_PID
    rm $PID_FILE
  fi
}

_stop startmain.py
_stop startprovision.py

_stop UTMConfigService.py
_stop nestatusmonitoring.py
