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

SVN_SERVER=211.224.204.158
echo -e "SVN Username: \c"
read SVN_USER
echo -e "SVN Password: \c"
read SVN_PASS

INSTALL_ROOT=`pwd`

run_commands() {
  _green=$(tput setaf 2)
  normal=$(tput sgr0)

  commands=$*

  echo -e ${_green}${commands}${normal}
  eval $commands
  echo
}

svn_co() {
  REPO=$1

  cd $HOME
  echo "svn checkout svn://$SVN_SERVER/$REPO --username $SVN_USER --password $SVN_PASS"
  svn checkout svn://$SVN_SERVER/$REPO --username $SVN_USER --password $SVN_PASS
  cd -
}

run() {
  WORK_DIR=$1
  MAIN_PY=$2

  cd $HOME/$WORK_DIR

  echo "[$WORK_DIR] RUN $MAIN_PY"
  nohup python $MAIN_PY 1> /dev/null 2>&1 &
  sleep 1
  cd -
}

prerequisite() {
  sudo apt-get install -y subversion python-pip libpq-dev python-dev language-pack-en language-pack-ko

  sudo pip install pyconvert==0.4.alpha
  sudo pip install pyrestful==0.3.2.alpha
  sudo pip install paramiko 
  sudo pip install psycopg2==2.5.4
  sudo pip install apscheduler 
  sudo pip install pysnmp 
  sudo pip install websocket-client
}

cmd="prerequisite"
run_commands $cmd

# Need to change pyrestful/rest.py for pyrestful(0.3.2.alpha)
cmd="sudo cp $INSTALL_ROOT/pyrestful/rest.py /usr/local/lib/python2.7/dist-packages/pyrestful/"
run_commands $cmd

cmd="svn_co ZeroOfficeWeb"
run_commands $cmd

cmd="svn_co GOMS_AP"
run_commands $cmd

cmd="svn_co CloudManager"
run_commands $cmd
