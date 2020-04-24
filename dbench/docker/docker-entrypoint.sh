#!/usr/bin/env sh
set -e

if [ -z $DBENCH_MOUNTPOINT ]; then
    DBENCH_MOUNTPOINT=/tmp
fi

if [ -z $FIO_SIZE ]; then
    FIO_SIZE=2G
fi

if [ -z $FIO_OFFSET_INCREMENT ]; then
    FIO_OFFSET_INCREMENT=500M
fi

if [ -z $FIO_DIRECT ]; then
    FIO_DIRECT=1
fi

if [ -z $RUN_TIME ]; then
    RUN_TIME=60
fi
echo Working dir: $DBENCH_MOUNTPOINT
echo
starttime=0
if [ "$1" = 'fio' ]; then
  echo Waiting for Synchronized Start Time
  if [ -f /tmp/sync/starttime ] ;
  then
    echo "waiting for start time"
    starttime=`cat /tmp/sync/starttime`
    now=`date +%s`
    if [ $now -le $starttime ];
    then
      sleep `expr $starttime - $now`
    else
      echo "missed starttime, exiting"
      exit 0
    fi
  else
    echo "setting start time for 60 seconds from now"
    now=`date +%s`
    starttime=`expr $now + 60`
    mkdir -p /tmp/sync
    touch /tmp/sync/starttime
    echo $starttime > /tmp/sync/starttime
    sleep `expr $starttime - $now`
  fi

  echo Testing Read Sequential Speed...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  READ_SEQ=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=read_seq --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4k --iodepth=16 --size=$FIO_SIZE --readwrite=read --time_based --ramp_time=2s --runtime=${RUN_TIME}s --thread --numjobs=4 --offset_increment=$FIO_OFFSET_INCREMENT --group_reporting)
  echo "$READ_SEQ"
  READ_SEQ_VAL=$(echo "$READ_SEQ"|grep -E 'READ:'|grep -Eoi '(aggrb|bw)=[0-9GMKiBs/.]+'|cut -d'=' -f2)
  echo

  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Read Latency...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  READ_LATENCY=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --name=read_latency --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=4 --size=$FIO_SIZE --readwrite=randread --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$READ_LATENCY"
  READ_LATENCY_VAL=$(echo "$READ_LATENCY"|grep ' lat.*avg'|grep -Eoi 'avg=[0-9.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Read IOPS...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  READ_IOPS=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=read_iops --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=64 --size=$FIO_SIZE --readwrite=randread --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$READ_IOPS"
  READ_IOPS_VAL=$(echo "$READ_IOPS"|grep -E 'read ?:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Read Bandwidth...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  READ_BW=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=read_bw --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=64 --size=$FIO_SIZE --readwrite=randread --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$READ_BW"
  READ_BW_VAL=$(echo "$READ_BW"|grep -E 'read ?:'|grep -Eoi 'BW=[0-9GMKiBs/.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Write IOPS...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  WRITE_IOPS=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=write_iops --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=64 --size=$FIO_SIZE --readwrite=randwrite --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$WRITE_IOPS"
  WRITE_IOPS_VAL=$(echo "$WRITE_IOPS"|grep -E 'write:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Write Bandwidth...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  WRITE_BW=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=write_bw --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=64 --size=$FIO_SIZE --readwrite=randwrite --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$WRITE_BW"
  WRITE_BW_VAL=$(echo "$WRITE_BW"|grep -E 'write:'|grep -Eoi 'BW=[0-9GMKiBs/.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`

  echo Testing Write Latency...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  WRITE_LATENCY=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --name=write_latency --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4K --iodepth=4 --size=$FIO_SIZE --readwrite=randwrite --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$WRITE_LATENCY"
  WRITE_LATENCY_VAL=$(echo "$WRITE_LATENCY"|grep ' lat.*avg'|grep -Eoi 'avg=[0-9.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Write Sequential Speed...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  WRITE_SEQ=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=write_seq --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4k --iodepth=16 --size=$FIO_SIZE --readwrite=write --time_based --ramp_time=2s --runtime=${RUN_TIME}s --thread --numjobs=4 --offset_increment=$FIO_OFFSET_INCREMENT --group_reporting)
  echo "$WRITE_SEQ"
  WRITE_SEQ_VAL=$(echo "$WRITE_SEQ"|grep -E 'WRITE:'|grep -Eoi '(aggrb|bw)=[0-9GMKiBs/.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo Testing Read/Write Mixed...
  echo drop caches
  echo 3  >/proc/sys/vm/drop_caches
  RW_MIX=$(fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=$FIO_DIRECT --gtod_reduce=1 --name=rw_mix --filename=$DBENCH_MOUNTPOINT/fiotest --bs=4k --iodepth=64 --size=$FIO_SIZE --readwrite=randrw --rwmixread=75 --time_based --ramp_time=2s --runtime=${RUN_TIME}s)
  echo "$RW_MIX"
  RW_MIX_R_IOPS=$(echo "$RW_MIX"|grep -E 'read ?:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
  RW_MIX_W_IOPS=$(echo "$RW_MIX"|grep -E 'write:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
  echo
  echo
  echo waiting to sync next fio run
  now=`date +%s`
  starttime=`expr $starttime + $RUN_TIME + 60`
  sleep `expr $starttime - $now`
  echo All tests complete.
  echo
  echo ==================
  echo = Dbench Summary =
  echo ==================
  echo "Random Read/Write IOPS: $READ_IOPS_VAL/$WRITE_IOPS_VAL. BW: $READ_BW_VAL / $WRITE_BW_VAL"

  rm $DBENCH_MOUNTPOINT/fiotest
  exit 0
fi

exec "$@"
