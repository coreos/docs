# Adding swap in CoreOS Container Linux

Swap is the process of moving pages of memory to a designated part of the hard disk, freeing up space when needed. Swap can be used to alleviate problems with low-memory environments.

By default Container Linux does not include a partition for swap, however one can configure their system to have swap, either by including a dedicated partition for it or creating a swapfile.

## Managing swap with systemd

systemd provides a specialized `.swap` unit file type which may be used to activate swap. The below example shows how to add a swapfile and activate it using systemd.

### Creating a swapfile

The following commands, run as root, will make a 1GiB file suitable for use as swap.

```sh
mkdir -p /var/vm
fallocate -l 1024m /var/vm/swapfile1
chmod 600 /var/vm/swapfile1
mkswap /var/vm/swapfile1
```

### Creating the systemd unit file

The following systemd unit activates the swapfile we created. It should be written to `/etc/systemd/system/var-vm-swapfile1.swap`.

```ini
[Unit]
Description=Turn on swap

[Swap]
What=/var/vm/swapfile1

[Install]
WantedBy=multi-user.target
```

### Enable the unit and start using swap

Use `systemctl` to enable the unit once created. The `swappiness` value may be modified if desired.

```sh
$ systemctl enable --now var-vm-swapfile1.swap
# Optionally
$ echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/80-swappiness.conf
$ systemctl restart systemd-sysctl
```

Swap has been enabled and will be started automatically on subsequent reboots. We can verify that the swap is activated by running `swapon`:

```
$ swapon
NAME              TYPE       SIZE USED PRIO
/var/vm/swapfile1 file      1024M   0B   -1
```

## Problems and Considerations

### Btrfs and xfs

Swapfiles should not be created on btrfs or xfs volumes. For systems using btrfs or xfs, it is recommended to create a dedicated swap partition.

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
storage:
  files:
  - path: /etc/sysctl.d/80-swappiness.conf
    filesystem: root
    contents:
      inline: "vm.swappiness=10"

systemd:
  units:
    - name: var-vm-swapfile1.swap
      contents: |
        [Unit]
        Description=Turn on swap
        Requires=create-swapfile.service
        After=create-swapfile.service

        [Swap]
        What=/var/vm/swapfile1

        [Install]
        WantedBy=multi-user.target
    - name: create-swapfile.service
      contents: |
        [Unit]
        Description=Create a swapfile
        RequiresMountsFor=/var
        ConditionPathExists=!/var/vm/swapfile1
        
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/mkdir -p /var/vm
        ExecStart=/usr/bin/fallocate -l 1024m /var/vm/swapfile1
        ExecStart=/usr/bin/chmod 600 /var/vm/swapfile1
        ExecStart=/usr/sbin/mkswap /var/vm/swapfile1
        RemainAfterExit=true
```
