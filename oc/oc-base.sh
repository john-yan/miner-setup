#!/bin/bash

find_index_by_uuid() {
  local uuid=$1
  local id=$(/bin/grep $uuid /gpu/uuid.txt | awk '{print $2}')
  if [[ $id == "" ]] ; then
    echo "id-not-found"
  else
    echo $id
  fi
}

oc() {
  local uuid=$1
  local GPU_OFFSET=$2
  local MEMORY_OFFSET=$3
  local id=$(find_index_by_uuid $uuid)
  if [[ "$id" == "id-not-found" ]] ; then
    echo "$uuid profile is not found!!"
    return 1
  fi
  echo "setting $uuid GPU_OFFSET=$GPU_OFFSET"
  echo "setting $uuid MEMORY_OFFSET=$MEMORY_OFFSET"
  # sudo DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:$id]/GPUPowerMizerDefaultMode=1;
  sudo DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:$id]/GPUGraphicsClockOffset[3]=$GPU_OFFSET;
  sudo DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:$id]/GPUMemoryTransferRateOffset[3]=$MEMORY_OFFSET;
}

setpw() {
  local uuid=$1
  local pw=$2
  echo "setting $uuid PowerLimit=$pw"
  sudo nvidia-smi -i $uuid -pl $pw
}

setfan() {
  local uuid=$1
  local fan_speed=$2
  local id=$(find_index_by_uuid $uuid)
  if [[ "$id" == "id-not-found" ]] ; then
    echo "$uuid profile is not found!!"
    return 1
  fi
  if [[ $fan_speed == "-1" ]] ; then
    echo "Using default fan speed for $uuid"
    return 0
  fi

  echo "setting $uuid fan_speed=$fan_speed"
  sudo DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:$id]/GPUFanControlState=1;
  sudo DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [fan:$id]/GPUTargetFanSpeed=$fan_speed;
}

setup_all_gpus() {
  local config_txt=$1
  local pw=
  local gr_offset=
  local mem_offset=

  # enable persistent mode
  nvidia-smi -pm 1
  if [[ $? -ne 0 ]] ; then
    return 1
  fi

  for gpu in $(nvidia-smi --format=csv --query-gpu=uuid | sed 1d) ; do
    if [[ $(/bin/grep $gpu $config_txt) == "" ]] ; then
      echo "GPU $gpu is not found in the config file"
    else
      pw=$(/bin/grep $gpu $config_txt | awk '{print $2}')
      gr_offset=$(/bin/grep $gpu $config_txt | awk '{print $3}')
      mem_offset=$(/bin/grep $gpu $config_txt | awk '{print $4}')
      fan_speed=$(/bin/grep $gpu $config_txt | awk '{print $5}')
      setpw $gpu $pw
      oc $gpu $gr_offset $mem_offset
      setfan $gpu $fan_speed
    fi
  done
}

