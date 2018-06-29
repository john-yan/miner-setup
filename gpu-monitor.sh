#!/bin/bash -x

export GPU_ERROR_DETECTED=0

notify() {
  local GPUS=$@
  local DATE=`date`
  local TXT=`echo -e "Date: $DATE\nGPU list: $GPUS"`
  local SUBJECT="Miner1 failures detected!"

  if [[ `whoami` == 'root' ]] ; then
    SUBJECT="Miner1 failures detected: reboot in 2 mins!"
  fi 

  echo "$TXT" | mail -s "$SUBJECT" john.yan1019@gmail.com

  if [[ `whoami` == 'root' ]] ; then
    TIMESTAMP=$(date +%F_%H-%M-%S)
    DMESG="/home/miner/failures/dmesg-$TIMESTAMP"
    echo "Save dmesg to $DMESG"
    dmesg > $DMESG
    sleep 120 && reboot
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

echo "I am $(whoami)"
UPTIME=`cat /proc/uptime | awk '{print $1}'`
WAIT=`python -c "uptime = int($UPTIME); print(1 if uptime > 90 else 90 - uptime);"`

echo "wait $WAIT secs"
sleep $WAIT
echo "start monitoring"

NGPUS=`python -c "print($(cat /oc/uuid.txt | wc -l) - 1)"`
cat /oc/uuid.txt | mail -s "Miner1 startup with ($NGPUS GPUs)" john.yan1019@gmail.com

while true ;
do
  run_test
  sleep 30
done
