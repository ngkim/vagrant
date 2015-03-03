#!/bin/bash

###########################################################################
# Author: Namgon Kim
# Date: 2015. 03. 02
#
# NFV 제어 SW를 설치하고 구동함
# 1) 필요 SW를 apt-get과 pip을 통해 설치
# 2) NFV 제어 SW를 svn repository로부터 다운로드
# 3) NFV 제어 SW를 구동 
#    - ZeroOfficeWeb/startmain.py                   :  9999번 포트 사용
#    - GOMS_AP/startprovision.py                    :  8080번 포트 사용
#    - CloudManager/service/UTMConfigService.py 
#    - CloudManager/schedule/nestatusmonitoring.py
#
###########################################################################

run() {
  WORK_DIR=$1
  MAIN_PY=$2
  PID_FILE=".${MAIN_PY}.pid"

  cd $HOME/$WORK_DIR

  echo "[$WORK_DIR] RUN $MAIN_PY"
  nohup python $MAIN_PY 1> /dev/null 2>&1 &
  echo $?
  cd - 1> /dev/null 2>&1
  sleep 1

  # record PID for running python process
  echo $! > $PID_FILE
  _PID=`cat $PID_FILE`
}

run ZeroOfficeWeb startmain.py
run GOMS_AP startprovision.py

run "CloudManager/service" UTMConfigService.py
run "CloudManager/scheduler" nestatusmonitoring.py
