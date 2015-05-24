---
layout: docs
title: Disk Layout
category: sdk_distributors
sub_category: sdk
weight: 9
---

# CoreOS Disk Layout

CoreOS is designed to be reliably updated via a [continuous stream of updates]({{site.url}}/using-coreos/updates). The operating system has 9 different disk partitions, utilizing a subset of those to make each update safe and enable a roll-back to a previous version if anything goes wrong.

## Partition Table

| Number | Label | Description | Partition Type |
|:------:|-------|-------------|----------------|
| 1      | EFI-SYSTEM     | Contains the bootloader. | VFAT           |
| 2      | BIOS-BOOT      | This partition is reserved for future use. | (none) |
| 3      | USR-A          | One of two active/passive partitions holding CoreOS. | EXT4           |
| 4      | USR-B          | One of two active/passive partitions holding CoreOS. | (empty on first boot) |
| 5      | ROOT-C         | This partition is reserved for future use. | (none) |
| 6      | OEM            | Stores configuration data specific to an [OEM platform][OEM docs] | EXT4 |
| 7      | OEM-CONFIG     | Optional storage for an OEM. | (defined by OEM) |
| 8      | (unused)       | This partition is reserved for future use. | (none) |
| 9      | ROOT           | Stateful partition for storing persistent data. | EXT4 or BTRFS |

For more information, [read more about the disk layout][chromium disk format] used by Chromium and ChromeOS, which inspired the layout used by CoreOS.

[OEM docs]: {{site.url}}/docs/sdk-distributors/distributors/notes-for-distributors
[chromium disk format]: http://www.chromium.org/chromium-os/chromiumos-design-docs/disk-format

## Mounted Filesystems

CoreOS is divided into two main filesystems, a read-only `/usr` and a stateful read/write `/`.

### Read-Only /usr

The `USR-A` or `USR-B` partitions are interchangeable and one of the two is mounted as a read-only filesystem at `/usr`. After an update, CoreOS will re-configure the GPT priority attribute, instructing the bootloader to boot from the passive (newly updated) partition. Here's an example of the priority flags set on an Amazon EC2 machine:

```
$ sudo cgpt show /dev/xvda
       start        size    part  contents
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=1 tries=0 successful=1
```

CoreOS images ship with the `USR-B` partition empty to reduce the image filesize. The first CoreOS update will populate it and start the normal active/passive scheme.

The OEM partition is also mounted as read-only at `/usr/share/oem`.

### Stateful Root

All stateful data, including container images, is stored within the read/write filesystem mounted at `/`. On first boot, the ROOT partition and filesystem will expand to fill any remaining free space at the end of the drive.

The data stored on the root partition isn't manipulated by the update process. In return, we do our best to prevent you from modifying the data in /usr.

Due to the unique disk layout of CoreOS, an `rm -rf /` is an un-supported but valid operation to do a "factory reset". The machine should boot and operate normally afterwards.