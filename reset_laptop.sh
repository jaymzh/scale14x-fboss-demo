#!/bin/bash

[ $UID = 0 ] || { echo "This is meant to be run as root"; exit 1; }
[ -d configs -a -d scripts ] || { echo "Please run from usb mountpoint"; exit 1; }

echo "Restoring SSH keys"
PRIVKEY=/home/demo/.ssh/id_rsa
cp .ssh/id_rsa-fboss_demo $PRIVKEY
chown root:demo $PRIVKEY
chmod 640 $PRIVKEY

echo "Restoring hostnames"
cp laptop_configs/hosts /etc/hosts
