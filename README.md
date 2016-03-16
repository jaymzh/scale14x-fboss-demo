# FBOSS Demo

This is everything used to produce the FBOSS demo at SCALE 14X.

## Setup

### Keypairs

You will need to sets of SSH keys - one for root and one for "demo" access. Create them as id_rsa-fboss_demo (and `id_rsa-fboss_demo.pub`) and `id_rsa-fboss_root` (and `id_rsa-fboss_root`). There should be no passphrase on the `demo` key, but a passphrase on the `root` key.

### Setting up the USB key

We setup a USB key to hold the important bits to build reset the demo in case of a problem.

* Copy this all to a USB key
* Copy the SSH keys into `.ssh/` on the USB key.

### Settting up the laptop

First make sure that the `demo` user is setup and has a ~/.ssh directory.

Mount the usb key as root on the laptop, cd to the mount point as (again, as root) run `reset_laptop.sh`. This will do the following:

* Copy the relevant keys to ~demo/.ssh/
* Not provide write-access to said keys
* Update /etc/hosts with IP addresses we'll later use for the switches to be `fboss1`, `fboss2`, and `fboss3`.
* Copy over a fluxbox config - see below

What window manager you setup is up to you... if you use fluxbox the provided configs will:
* set a default resolution - you probably want to change it
* Auto-setup 4 windows on login, where 3 of them SSH to the the relevant switches
* Setup keybindings:
** alt+1 - Virtual terminal 1 (where the shells will be)
** alt+2 - Virtual terminal 2 (where the web browser will be)
** alt+t - Open a new virtual terminal
** alt+w - Open a web browser

### Setting up the switches

Follow the ONL guides to setup the latest version of FBOSS on three switches. Once they're basically functional (`fboss_route.py list_routes` works).

Now setup the netowrking so that ma1 will come up with the right address:

* Update `/mnt/flash/boot-config` to set `NETAUTO` to `static`.
* Update `/etc/network/interfaces` to add the following block:

```
auto ma1
iface ma1 inet static
  address 10.1.1.1
  netmask 255.255.255.0
  broadcast 10.1.1.255
```

Changing `ipaddress` to update the last octet to match the switch number (10.1.1.1 for fboss1, 10.1.1.2 for fboss2, 10.1.1.3 for fboss3).

We set our laptop to be `10.1.1.250`.

Once everything has the right IP, mount the USB key as root and run `./reset_switch.sh`.

This will:
* Copy over FBOSS configs
* Update the init script for FBOSS (won't be necessary after https://github.com/opennetworklinux/fboss-package/pull/3 is merged(
* Copy over the `scaledemo.sh` script
* Restart the FBOSS agent

And that should set them up for success.

### BMC Considerations

In order for the Hardware Stats demo to work, you need to configure the `usb0` interface between the microserver and the BMC. This is done by adding this to the `interfaces` file on the microserver:

```
auto usb0
iface usb0 inet static
  address 192.168.0.2
  broadcast 192.168.0.255
  netmask 255.255.255.0
```

And this to the `interfaces` file on the BMC:

```
auto usb0
iface usb0 inet static
  address 192.168.0.1
  broadcast 192.168.0.255
  netmask 255.255.255.0
```

Now, doing so means that one can SSH between the two so you'll want to change the default root password on the BMC.

#### Persisting BMC Configs

By default none of these things will persist on a BMC reboot. To make these persistent you need to copy the relevant files to the persistent flash:

```
cd /mnt/data
mkdir -p etc/network
cp /etc/network/interfaces etc/network/
cp /etc/{passwd,shadow} etc
```

And then create a rc.early hook to change the real files to symlinks to your new files. Make `/mnt/data/etc/rc.early`

```
#!/bin/bash

files="network/interfaces passwd shadow"
for file in $files; do
  echo "Restoring /etc/$file"
  rm -f /etc/$file
  ln -s /mnt/data/etc/$file /etc/$file
done
```

Now you can run that `rc.early` script to move everything around and now things should be persistent. (`/etc/init.d/rc.early` calls `/mnt/data/etc/rc.early`).

## Running the Demo

Put the html somewhere on local disk and open up a web-browser to point to it. Then open 3 windows and ssh to each switch.
