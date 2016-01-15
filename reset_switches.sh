#!/bin/bash

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
LOG=/tmp/reset_switches.log

[ $UID = 0 ] || { echo "This is meant to be run as root"; exit 1; }
[ -d configs -a -d scripts ] || { echo "Please run from usb mountpoint"; exit 1; }
echo "Starting switch reset at `date`" &>> $LOG
eval `ssh-agent -s` >/dev/null
ssh-add -l | grep fboss_root || ssh-add .ssh/id_rsa-fboss_root
for host in fboss1 fboss2 fboss3; do
  echo -n "Resetting $host: "
  echo -n "[configs] "
  scp $SSH_OPTS configs/$host/ocp-demo.json root@$host:/etc/fboss &>>$LOG
  echo -n "[scripts] "
  scp $SSH_OPTS scripts/* root@$host:/usr/local/bin/ &>>$LOG
  scp $SSH_OPTS init/* root@$host:/etc/init.d/ &>>$LOG
  echo "[services] "
  ssh $SSH_OPTS $host '/etc/init.d/fboss_wedge_agent stop; sleep 2; /etc/init.d/fboss_wedge_agent start' &>>$LOG
done
ssh-add -d .ssh/id_rsa-fboss_root
kill $SSH_AGENT_PID
kill -9 $SSH_AGENT_PID
echo >>$LOG
echo "It will take ~30 seconds for the FBOSS agent to startup"
echo "In case you need it, the output of our commands is in $LOG"
