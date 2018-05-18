#!/bin/bash -x

export GPU_ERROR_DETECTED=0

notify() {
  local GPUS=$@
  local DATE=`date`
  local TXT=`echo -e "Date: $DATE\nGPU list: $GPUS"`
  local SUBJECT="Miner1 failures detected!"

  if [[ `whoami` == 'root' ]] ; then
    SUBJECT="Miner1 failures detected: reboot in 20 mins!"
  fi 

  echo "$TXT" | mail -s "$SUBJECT" john.yan1019@gmail.com

  if [[ `whoami` == 'root' ]] ; then
    sleep 1200 && reboot
  fi 
}

run_test() {
  if [[ $GPU_ERROR_DETECTED == "1" ]] ; then
    return
  fi

  DATE=`date`
  GPUS=`/bin/dmesg | /usr/bin/tail -n 70 | /bin/grep "NVRM: GPU at PCI" | awk '{print $NF}' | xargs echo`
  if [[ "$GPUS" != "" ]] ; then
    notify $GPUS
    export GPU_ERROR_DETECTED=1
  fi
}

UPTIME=`cat /proc/uptime | awk '{print $1}'`
WAIT=`python -c "uptime = int($UPTIME); print(1 if uptime > 90 else 90 - uptime);"`

echo "wait $WAIT secs"
sleep $WAIT
echo "start monitoring"

while true ;
do
  run_test
  sleep 30
done
