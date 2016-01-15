#!/bin/bash

HOSTNAME=$(hostname)
case "$HOSTNAME" in
fboss1)
  mynet="172.31.1.0/24"
  myip="172.31.1.1"
  mygw="172.31.1.2"
  remotenet="172.31.5.0/24"
  my6net="2001:db:3333:1::/64"
  my6ip="2001:db:3333:1::1"
  my6gw="2001:db:3333:1::2"
  remote6net="2001:db:3333:5::/64"
  ;;
fboss3)
  mynet="172.31.5.0/24"
  myip="172.31.5.3"
  mygw="172.31.5.2"
  remotenet="172.31.1.0/24"
  my6net="2001:db:3333:5::/64"
  my6ip="2001:db:3333:5::3"
  my6gw="2001:db:3333:5::2"
  remote6net="2001:db:3333:1::/64"
  ;;
esac

init() {
  fboss_route.py flush
}

run() {
  c="$1"
  echo "Running: $c"
  $c
}

demo1a_setup() {
  [ $HOSTNAME = 'fboss2' ] && return

  init
  run "fboss_route.py add $remotenet $mygw"
  run "fboss_route.py add $remote6net $my6gw"
}

demo1b_setup() {
  [ $HOSTNAME = 'fboss2' ] && return

  route_cleanup
  echo "==> Ensuring 1a is setup..."
  demo1a_setup

  echo "==> Adding 1b..."
  run "sudo ip route add $remotenet dev front0 src $myip"
  run "sudo ip route add $remote6net dev front0 src $my6ip"
}

route_cleanup() {
  out=$(sudo ip route show | egrep -v 'kernel|default')
  if [ -n "$out" ]; then
    sudo ip route del $out
  fi
  out=$(sudo ip -6 route show | egrep -v 'kernel|default')
  if [ -n "$out" ]; then
    sudo ip -6 route del $out
  fi
}

cleanup() {
  route_cleanup
  init
}

case "$1" in
1a)
  demo1a_setup
  ;;
1b)
  demo1b_setup
  ;;
c|clean|clear|cleanup)
  cleanup
  ;;
*)
  echo "$0 [1a|1b|clean]"
  ;;
esac
