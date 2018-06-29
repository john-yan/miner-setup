#!/bin/bash -x
#
# I am supposed to be invoked by rc.local
#

sleep 10

if [[ `whoami` != "root" ]] ; then
  echo "I need root access to run!"
  exit 0
fi

# oc
source /oc/oc-base.sh
setup_all_gpus /oc/oc-config.txt

# reboot after 24 hrs
# bash -c "sleep 86400 && reboot" &

#export CUDA_VISIBLE_DEVICES=0,1,2,4,5,6,7,8,9,10,11

# start miner
MINER_NAME=miner
MINER_HOME=/home/$MINER_NAME

#su miner1 -c "screen -dmS mine /home/miner1/zec-miner/start2.sh"
su $MINER_NAME -c "screen -dmS mine $MINER_HOME/claymore-11.6/start.bash"
su $MINER_NAME -c "screen -S mine -X screen sudo bash $MINER_HOME/miner-setup/gpu-monitor.sh"
#su $MINER_NAME -c "screen -S mine -X screen sudo $MINER_HOME/OhGodAnETHlargementPill-r2"

exit 0
