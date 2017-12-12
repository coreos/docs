# Configuring Root Filesystem Placement
Container Linux supports composite disk devices such as RAID arrays. If the root filesystem is placed on a composite device, special care must be taken to ensure Container Linux can find and mount the filesystem early in the boot process. GPT partition entries have a [partition type GUID](https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs) that specifies what type of partition it is (e.g. Linux filesystem); Container Linux uses special type GUIDs to indicate that a partition is a component of a composite device containing the root filesystem.

## Root on RAID
RAID enables multiple disks to be combined into a single logical disk to increase reliability and performance. To create a software RAID array when provisioning a Container Linux system, use the `storage.raid` section of a [Container Linux Config](https://coreos.com/os/docs/latest/provisioning.html). RAID components containing the root filesystem must have the type GUID `be9067b9-ea49-4f15-b4f6-f36f8c9e1818`. All other RAID arrays must not have that GUID; the Linux RAID partition GUID `a19d880f-05fc-4d3b-a006-743f0f84911e` is recommended instead. See the [Ignition documentation](https://coreos.com/ignition/docs/latest/examples.html#create-a-raid-enabled-data-volume) for more information on setting up RAID for data volumes.

### Overview
To place the root filesystem on a RAID array:

 * Create the component partitions used in the RAID array with the type GUID `be9067b9-ea49-4f15-b4f6-f36f8c9e1818`.
 * Create a RAID array from the component partitions.
 * Create a filesystem labeled `ROOT` on the RAID array.
 * Remove the `ROOT` label from the original root filesystem.

### Example Container Linux Config
This Container Linux Config creates partitions on `/dev/vdb` and `/dev/vdc` that fill each disk, creates a RAID array named `root_array` from those partitions, and finally creates the root filesystem on the array. To prevent inadvertent booting from the [original root filesystem](https://coreos.com/os/docs/latest/sdk-disk-partitions.html#partition-table), `/dev/vda9` is reformatted with a blank ext4 filesystem labeled `unused`.

**Warning: This will erase both `/dev/vdb` and `/dev/vdc`.**
```yaml container-linux-config
storage:
  disks:
    - device: /dev/vdb
      wipe_table: true
      partitions:
       - label: root1
         type_guid: be9067b9-ea49-4f15-b4f6-f36f8c9e1818
    - device: /dev/vdc
      wipe_table: true
      partitions:
       - label: root2
         type_guid: be9067b9-ea49-4f15-b4f6-f36f8c9e1818
  raid:
    - name: "root_array"
      level: "raid1"
      devices:
        - "/dev/vdb1"
        - "/dev/vdc1"
  filesystems:
    - name: "ROOT"
      mount:
        device: "/dev/md/root_array"
        format: "ext4"
        label: "ROOT"
    - name: "unused"
      mount:
        device: "/dev/vda9"
        format: "ext4"
        wipe_filesystem: true
        label: "unused"
```

### Limitations

 * Other system partitions, such as `USR-A`, `USR-B`, `OEM`, and `EFI-SYSTEM`, cannot be placed on a software RAID array.
 * RAID components containing the root filesystem must be partitions on a GPT-partitioned device, not whole-disk devices or partitions on an MBR-partitioned disk.
 * `/etc/mdadm.conf` cannot be used to configure a RAID array containing the root filesystem.
 * Since Ignition cannot modify the type GUID of existing partitions, the default `ROOT` partition cannot be reused as a component of a RAID array. A future version of Ignition will support resizing the `ROOT` partition and changing its type GUID, allowing it to be used as part of a RAID array.

