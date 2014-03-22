---
layout: docs
title: Notes for Distributors
category: sdk_distributors
sub_category: distributors
weight: 5
---

# Notes for Distributors

This page outlines details required for implementing a CoreOS "OEM".
OEMs are runtime specific changes that are required to do things like bring up networking, set nameservers, and set credentials.
For example, the [vagrant oem][oem-vagrant] sets up authorized_keys file for the vagrant user, and copies it into place.
An Amazon [EC2 AMI oem][oem-ami] pings the instance-data on the host to find the key and place it accordingly (network is configured by DHCP).

[oem-vagrant]: https://github.com/coreos/coreos-overlay/blob/master/coreos-base/oem-vagrant/files/
[oem-ami]: https://github.com/coreos/coreos-overlay/tree/master/coreos-base/oem-ami/files/run

## Basics

The OEM is only responsible for:

* Set up networking, if DHCP is not available
* Place initial credentials (via SSH keys)

Upon every boot, CoreOS will look for `/usr/share/oem/run`, and if it exists, execute it. The directory `/usr/share/oem/` should be where all files related to the particular implementation reside.
This includes scripts, agents, or anything else required to bring the host up.

If DHCP is in place, networking and nameservers will be automatically configured.
However, no credentials will be on the host, so that will still need to be configured via an OEM.


## OEM in detail

CoreOS's partition table has many different partitions.
This is because of the active/passive nature of the update system.

`/usr/share/oem` is mounted from partition 6 on the block device that CoreOS is installed on to.
This area should be used for all dependencies required for getting the OEM working.

OEMs are _not_ automatically updated.
To update the OEM, you must update the partition.
For this reason, the OEM should be as simple as possible, and include only networking and credential setup.
Everything else should be pushed into the base OS.

### Mounting OEM partition from base image

* Fetch the [current raw image][coreos-dev-channel-raw]:


```
wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_image.bin.bz2
bunzip2 coreos_production_image.bin.bz2
losetup --show --find -P coreos_production_image.bin
mount /dev/loop0p6 /mnt/
```

This partition will be mounted at /usr/share/oem, so your `run` would need to be placed at `/mnt/oem.sh` in this example.

From there, you will need to implement a run

[coreos-dev-channel-raw]: http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_image.bin.bz2



## run in detail

`/usr/share/oem/` is /dev/disk6 (partition 6) mounted at `/usr/share/oem/`

### Simple example

The simplest way to handle setup is to create a `run` that does everything you need. For instance:

```
#!/bin/bash

systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
ip -4 address flush dev ens3
ip -4 address add xxx.xxx.xxx.xxx/xx dev ens3
ip -4 link set dev ens3 up
ip -4 route add default via xxx.xxx.xxx.xxx
echo nameserver 8.8.8.8 > /etc/resolv.conf

# This will add a new key labeled oem or replace the old
# key labeled oem
cat hard_coded_id_dsa.pub | update-ssh-keys -a oem
```

### Integrating with systemd

If your provider requires an agent, you'll need to have the agent managed by systemd.
To do this, your `run` will add the required systemd service files at boot, then start them.

```
#!/bin/bash
systemctl enable --runtime /usr/share/oem/system/*
systemctl start oem.target
```

In this case, systemd [service][service-docs] files are placed in `/usr/share/oem/system/`.
Using full services files allows you to run your own agents that are fully integrated with CoreOS.

All units will have to have the following section in their `.service` file, for the oem.target to work:

```
[Install]
WantedBy = oem.target
```

Create /usr/share/oem/system/oem.target. This target will allow you to start and stop all your OEM related services at once:

```
[Unit]
Description=CoreOS YourCompany OEM Target

[Install]
WantedBy=multi-user.target
```

### Example service file for an agent

This is a complex agent example, but shows how a systemd-nspawn can be used to create a container for an agent, then start it.
From there, the OEM would need to implement an additional service file that watches the changes the agent makes and incorporates them back into CoreOS.

```
[Service]
ExecStart=/usr/bin/systemd-nspawn -D /usr/share/oem/nova-agent/ /bin/sh -c "HOME=/root mount -t xenfs none /proc/xen; /usr/share/nova-agent/0.0.1.37/sbin/nova-agent -o - -n -l info /usr/share/nova-agent/nova-agent.py resetnetwork"

[Install]
WantedBy=oem.target
```

[service-docs]: http://www.freedesktop.org/software/systemd/man/systemd.unit.html

## Credentials

CoreOS only supports SSH key based authentication.

An SSH public key will need to be placed in `/home/core/.ssh/authorized_keys`.
The home directory is on the "stateful partition", which is sda9.

### Example placing a key manually

Based on the instruction above (note, partition 9):

```
losetup --show --find -P coreos_production_image.bin
mount /dev/loop0p9 /mnt/
mkdir -pm 0700 /mnt/home/core/.ssh
cp id_dsa.pub /mnt/home/core/.ssh/authorized_keys
chown -R 1000:1000 /mnt/home/core
```
