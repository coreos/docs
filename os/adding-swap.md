# Adding swap in CoreOS Container Linux

Swap is the process of moving pages of memory to a designated part of the hard disk, freeing up space when needed. Swap can be used to alleviate problems with low-memory environments.

By default Container Linux does not include a partition for swap, however one can configure their system to have swap.

## Managing swap with systemd

A systemd-managed service can be used to create, enable, and disable a swapfile service on your system. Write, enable, and start the systemd unit file found in the next section to add swap to a Container Linux node.

### Creating the systemd unit file

The following systemd unit creates and enables a service to manage a 1GiB swapfile. It should be written to `/etc/systemd/system/swap.service`.

```
[Unit]
Description=Turn on swap

[Service]
Type=oneshot
Environment="SWAP_PATH=/var/vm" "SWAP_FILE=swapfile1"
ExecStartPre=-/usr/bin/rm -rf ${SWAP_PATH}
ExecStartPre=/usr/bin/mkdir -p ${SWAP_PATH}
ExecStartPre=/usr/bin/touch ${SWAP_PATH}/${SWAP_FILE}
ExecStartPre=/bin/bash -c "fallocate -l 1024m ${SWAP_PATH}/${SWAP_FILE}"
ExecStartPre=/usr/bin/chmod 600 ${SWAP_PATH}/${SWAP_FILE}
ExecStartPre=/usr/sbin/mkswap ${SWAP_PATH}/${SWAP_FILE}
ExecStartPre=/usr/sbin/sysctl vm.swappiness=10
ExecStart=/sbin/swapon ${SWAP_PATH}/${SWAP_FILE}
ExecStop=/sbin/swapoff ${SWAP_PATH}/${SWAP_FILE}
ExecStopPost=-/usr/bin/rm -rf ${SWAP_PATH}
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```

**Note** Ensure the block device containing your swapfile is configured to auto-mount on boot.

### Enable the unit and start using swap

The following command enables and starts the new `swap` service.

```
$ systemctl enable --now /etc/systemd/system/swap.service
```

Swap has been enabled and will be started automatically on subsequent reboots. We can verify that the swap is being used by running `free -hm`:

```
$ free -hm
             total       used       free     shared    buffers     cached
[...]
Swap:         1.0G         0B       1.0G
```

## Problems and Considerations

### Btrfs and xfs

Swapfiles should not be created on btrfs or xfs volumes. For systems using btrfs or xfs, it is recommended to create a dedicated ext4 partition to store swapfiles.

### Partition size

The swapfile cannot be larger than the partition on which it is stored.

### Checking if a system can use a swapfile

Use the `df(1)` command to verify that a partition has the right format and enough available space:

```
$ df -Th
Filesystem     Type      Size  Used Avail Use% Mounted on
[...]
/dev/sdXN      ext4      2.0G  3.0M  1.8G   1% /var
```

The block device mounted at `/var/`, `/dev/sdXN`, is the correct filesystem type and has enough space for a 1GiB swapfile.

## Adding swap with a Container Linux Config

The following config sets up a 1GiB swapfile located at `/var/vm/swapfile1`.

```yaml container-linux-config
systemd:
  units:
    - name: swap.service
      enable: true
      contents: |
        [Unit]
        Description=Turn on swap
        
        [Service]
        Type=oneshot
        Environment="SWAP_PATH=/var/vm"
        Environment="SWAP_FILE=swapfile1"
        ExecStartPre=-/usr/bin/rm -rf ${SWAP_PATH}
        ExecStartPre=/usr/bin/mkdir -p ${SWAP_PATH}
        ExecStartPre=/usr/bin/touch ${SWAP_PATH}/${SWAP_FILE}
        ExecStartPre=/bin/bash -c "fallocate -l 1024m ${SWAP_PATH}/${SWAP_FILE}"
        ExecStartPre=/usr/bin/chmod 600 ${SWAP_PATH}/${SWAP_FILE}
        ExecStartPre=/usr/sbin/mkswap ${SWAP_PATH}/${SWAP_FILE}
        ExecStartPre=/usr/sbin/sysctl vm.swappiness=10
        ExecStart=/sbin/swapon ${SWAP_PATH}/${SWAP_FILE}
        ExecStop=/sbin/swapoff ${SWAP_PATH}/${SWAP_FILE}
        ExecStopPost=-/usr/bin/rm -rf ${SWAP_PATH}
        RemainAfterExit=true
        
        [Install]
        WantedBy=multi-user.target
```
