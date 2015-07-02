check_ping_mgmt_batch() {
  CNT_ERR=0
  CNT_OK=0
  CNT_TOTAL=0
  for TEST_ID in `seq $START $END`; do
    ./36_ping_mgmt.sh $TEST_ID $QDHCP
  done
  
  echo "TOTAL= $CNT_TOTAL OK= $CNT_OK ERROR= $CNT_ERR"  
}

check_ping_gw_batch() {
  CNT_ERR=0
  CNT_OK=0
  CNT_TOTAL=0
  for TEST_ID in `seq $START $END`; do
    ./31_client_ping_gw.sh $TEST_ID
  done
  
  echo "TOTAL= $CNT_TOTAL OK= $CNT_OK ERROR= $CNT_ERR"  
}

check_ping_red_batch() {
  CNT_ERR=0
  CNT_OK=0
  CNT_TOTAL=0
  for TEST_ID in `seq $START $END`; do
    ./36_client_ping_red.sh $TEST_ID
  done
  
  echo "TOTAL= $CNT_TOTAL OK= $CNT_OK ERROR= $CNT_ERR"  
}

update_stat() {
   if [ "$?" = 0 ]; then
     echo -e DST= $(get_vm_name) OK!!!
     CNT_OK=$((CNT_OK + 1))
   else
     echo -e ${red}DST= $(get_vm_name) ERROR!!!${normal}
     CNT_ERR=$((CNT_ERR + 1))
   fi
   CNT_TOTAL=$((CNT_TOTAL + 1))
}

run_ping() {
   DST_IP=$1

   cmd="ping -c 3 $DST_IP"
   run_commands $cmd

   update_stat
}

run_ping_ns() {
   DST_IP=$1
   NS_NAME=$2
  
   cmd="ip netns exec $NS_NAME ping -c 3 $DST_IP"
   run_commands $cmd

   update_stat
}
