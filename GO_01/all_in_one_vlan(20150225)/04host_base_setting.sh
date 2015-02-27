#!/bin/bash

echo '
--------------------------------------------------------------------------------
    서버 커널 환경(네트워크 포워딩&필터) 수정
--------------------------------------------------------------------------------'
function server_syscontrol_change() {

    echo '
    # ------------------------------------------------------------------------------
    ### kernel setting change(ip_forward, rp_filter) to /etc/sysctl.conf!!!
    # ------------------------------------------------------------------------------'
  
    echo "
    net.ipv4.ip_forward=1
    net.ipv4.conf.all.rp_filter=0
    net.ipv4.conf.default.rp_filter=0" | tee -a /etc/sysctl.conf
  
    echo "  -> sysctl -p"
    sysctl -p
  
    echo '>>> check result
    # ------------------------------------------------------------------------------'
    cat /etc/sysctl.conf
    echo '
    # ------------------------------------------------------------------------------'

}


function timezone_setting() {

    echo "
    # ------------------------------------------------------------------------------
    # 우분투 시간대를 한국시간대에 맞추기 !!!
    # ------------------------------------------------------------------------------"
    
    ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

}

function repository_setting() {
    
    echo "
    # ------------------------------------------------------------------------------
    # apt-get update & upgrade !!!
    # ------------------------------------------------------------------------------"
    
    echo "apt-get install -y python-software-properties"
    apt-get install -y python-software-properties
    
    # LJG : vagrant 서버 내부에 VM으로 설치된 apt-cache server 이용하는 경우
    echo "1. configure apt-get proxy"
    CACHE_SERVER="211.224.204.145:23142"

cat > /etc/apt/apt.conf.d/02proxy <<EOF
Acquire::http { Proxy "http://$CACHE_SERVER"; };
EOF
    
    # LJG: trusty(14.04) 버전은 아래 명령에서 에러 발생
    # echo "add-apt-repository cloud-archive:icehouse"
    # add-apt-repository -y cloud-archive:icehouse    
    
    apt-get update
    # apt-get upgrade -y
    
    echo "
    # ------------------------------------------------------------------------------
    # ubuntu desktop을 사용할 경우 아래 network-manager를 지워야 함.
    # ------------------------------------------------------------------------------"
    apt-get purge network-manager

}

function install_base_utils() {
    
    echo "
    # ------------------------------------------------------------------------------
    # install_base_utils !!!
    # ------------------------------------------------------------------------------"
    
    echo "apt-get -y install ntp ngrep iperf dhcpdump ipcalc dos2unix"
    apt-get -y install ntp ngrep iperf dhcpdump ipcalc dos2unix    

}
