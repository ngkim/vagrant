svc_start() {
  SVC_NAME=$1

  if [ ! -z $SVC_NAME ]; then
    service $SVC_NAME start
  fi
}

svc_restart() {
  SVC_NAME=$1

  if [ ! -z $SVC_NAME ]; then
    service $SVC_NAME restart
  fi
}

svc_stop() {
  SVC_NAME=$1

  if [ ! -z $SVC_NAME ]; then
    service $SVC_NAME stop
  fi
}

svc_status() {
  SVC_NAME=$1

  if [ ! -z $SVC_NAME ]; then
    service $SVC_NAME status
  fi
}
