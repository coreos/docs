# Performing manual CoreOS Container Linux rollbacks

As much as we all love flawless, automatic updates, there may be occasions when an update must be rolled back. This is fairly straightforward on Container Linux, once you know the right commands.

tl;dr: The following command will set the currently passive partition to be active on the next boot:

```
cgpt prioritize "$(cgpt find -t coreos-usr | grep --invert-match "$(findmnt --noheadings --raw --output=source --target=/usr)")"
```

## How do updates work?

The system's GPT tables are used to encode which partition is currently active and which is passive. This can be seen using the `cgpt` command.

```
$ cgpt show /dev/sda
       start        size    part  contents
           0           1          Hybrid MBR
           1           1          Pri GPT header
           2          32          Pri GPT table
        4096      262144       1  Label: "EFI-SYSTEM"
                                  Type: EFI System Partition
                                  UUID: 596FF08E-5617-4497-B10B-27A23F658B73
                                  Attr: Legacy BIOS Bootable
      266240        4096       2  Label: "BIOS-BOOT"
                                  Type: BIOS Boot Partition
                                  UUID: EACCC3D5-E7E9-461D-A6E2-1DCDAE4671EC
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=2 tries=0 successful=1
     2367488     2097152       4  Label: "USR-B"
                                  Type: Alias for coreos-rootfs
                                  UUID: E03DD35C-7C2D-4A47-B3FE-27F15780A57C
                                  Attr: priority=1 tries=0 successful=0
     4464640      262144       6  Label: "OEM"
                                  Type: Alias for linux-data
                                  UUID: 726E33FA-DFE9-45B2-B215-FB35CD9C2388
     4726784      131072       7  Label: "OEM-CONFIG"
                                  Type: CoreOS reserved
                                  UUID: 8F39CE8B-1FB3-4E7E-A784-0C53C8F40442
     4857856    37085151       9  Label: "ROOT"
                                  Type: CoreOS auto-resize
                                  UUID: D9A972BB-8084-4AB5-BA55-F8A3AFFAD70D
    41943007          32          Sec GPT table
    41943039           1          Sec GPT header
```

Looking specifically at "USR-A" and "USR-B", we see that "USR-A" is the active USR partition (this is what's actually mounted at /usr). Its priority is higher than that of "USR-B". When the system boots, GRUB (the bootloader) looks at the priorities, tries, and successful flags to determine which partition to use.

```
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=2 tries=0 successful=1
     2367488     2097152       4  Label: "USR-B"
                                  Type: Alias for coreos-rootfs
                                  UUID: E03DD35C-7C2D-4A47-B3FE-27F15780A57C
                                  Attr: priority=1 tries=0 successful=0
```

You'll notice that on this machine, "USR-B" hasn't actually successfully booted. Not to worry! This is a fresh machine that hasn't been through an update cycle yet. When the machine downloads an update, the partition table is updated to allow the newer image to boot.


```
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=1 tries=0 successful=1
     2367488     2097152       4  Label: "USR-B"
                                  Type: Alias for coreos-rootfs
                                  UUID: E03DD35C-7C2D-4A47-B3FE-27F15780A57C
                                  Attr: priority=2 tries=1 successful=0
```

In this case, we see that "USR-B" now has a higher priority and it has one try to successfully boot. Once the machine reboots, the partition table will again be updated.

```
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=1 tries=0 successful=1
     2367488     2097152       4  Label: "USR-B"
                                  Type: Alias for coreos-rootfs
                                  UUID: E03DD35C-7C2D-4A47-B3FE-27F15780A57C
                                  Attr: priority=2 tries=0 successful=0
```

Now we see that the number of tries for "USR-B" has been decremented to zero. The successful flag still hasn't been updated though. Once update-engine has had a chance to run, it marks the boot as being successful.

```
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=1 tries=0 successful=1
     2367488     2097152       4  Label: "USR-B"
                                  Type: Alias for coreos-rootfs
                                  UUID: E03DD35C-7C2D-4A47-B3FE-27F15780A57C
                                  Attr: priority=2 tries=0 successful=1
```


## Performing a manual rollback

So, now that we understand what happens when the machine updates, we can tweak the process so that it boots an older image (assuming it's still intact on the passive partition). The first command we'll use is `cgpt find -t coreos-usr`. This will give us a list of all of the USR partitions available on the disk.

```
$ cgpt find -t coreos-usr
/dev/sda3
/dev/sda4
```

To figure out which partition is currently active, we can use `findmnt`.

```
$ findmnt --noheadings --raw --output=source --target=/usr
/dev/sda4
```

So now we know that `/dev/sda3` is the passive partition on our system. We can compose the previous two commands to dynamically figure out the passive partition.

```
$ cgpt find -t coreos-usr | grep --invert-match "$(findmnt --noheadings --raw --output=source --target=/usr)"
/dev/sda3
```

In order to rollback, we need to mark that partition as active using `cgpt prioritize`.


```
$ cgpt prioritize /dev/sda3
```

If we take another look at the GPT tables, we'll see that the priorities have been updated.

```
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=2 tries=0 successful=1
     2367488     2097152       4  Label: "USR-B"
                                  Type: Alias for coreos-rootfs
                                  UUID: E03DD35C-7C2D-4A47-B3FE-27F15780A57C
                                  Attr: priority=1 tries=0 successful=1

```

Again, composing the previous two commands we get this handy one-liner to revert to the previous image.

```
$ cgpt prioritize "$(cgpt find -t coreos-usr | grep --invert-match "$(findmnt --noheadings --raw --output=source --target=/usr)")"

```

## Forcing a Channel Downgrade

The procedure above restores the last known good Container Linux version from immediately before an upgrade reboot. The system remains on the same [Container Linux channel][relchans] after rebooting with the previous USR partition. It is also possible, though not recommended, to switch a Container Linux installation to an older release channel, for example to make a system running an Alpha release downgrade to the Stable channel. Root privileges are required for this procedure, noted by `sudo` in the commands below.

First, edit `/etc/coreos/update.conf` to set `GROUP` to the name of the target channel, one of `stable` or `beta`:

```ini
GROUP=stable
```

Next, clear the current version number from the `release` file so that the target channel will be certain to have a higher version number, triggering the "upgrade," in this case a downgrade to the lower channel. Since `release` is on a read-only file system, it is convenient to temporarily override it with a bind mount. To do this, copy the original to a writable location, then bind the copy over the system `release` file:

```sh
$ cp /usr/share/coreos/release /tmp
$ sudo mount -o bind /tmp/release /usr/share/coreos/release
```

The file is now writable, but the bind mount will not survive the reboot, so that the default read-only system `release` file will be restored after this procedure is complete. Edit `/usr/share/coreos/release` to replace the value of `COREOS_RELEASE_VERSION` with `0.0.0`:

```ini
COREOS_RELEASE_VERSION=0.0.0
```

Restart the update service so that it rescans the edited configuration, then initiate an update. The system will reboot into the selected lower channel after downloading the release:

```sh
$ sudo systemctl restart update-engine
$ update_engine_client -update
```


[relchans]: switching-channels.md

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/manual-rollbacks.md?pixel)]() <!-- END ANALYTICS -->