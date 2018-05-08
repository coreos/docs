# Constants and IDs

This document contains well-known constants and IDs used by Container Linux.

## Omaha application ID

This UUID is used to identify Container Linux to the update service, i.e. as an `appid` over the [Omaha protocol](../coreupdate/update-protocol.md).

| Label            | Value                                  | Notes |
|------------------|----------------------------------------|-------|
| Container Linux  | `e96281a6-d1af-4bde-9a0a-97b76e56dc57` | -     |

## GPT partition types

These GUIDs are dedicated [GPT partition types](https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs) for specific Container Linux usages.

| Label              | Value                                  | Notes |
|--------------------|----------------------------------------|-------|
| `coreos-usr`       | `5dfbf5f4-2848-4bac-aa5e-0d9a20b745a6` | Alias for historical `coreos-rootfs`, currently used for `/usr` only |
| `coreos-resize`    | `3884dd41-8582-4404-b9a8-e9b84f2df50e` | Support for auto-resizing via `extend-filesystems`, current default type for `/` |
| `coreos-reserved`  | `c95dc21a-df0e-4340-8d7b-26cbfa9a03e0` | Reserved for OEM usage, support for customizations via `OEM-CONFIG` partition |
| `coreos-root-raid` | `be9067b9-ea49-4f15-b4f6-f36f8c9e1818` | RAID partition containing a rootfs, see [notes](../os/root-filesystem-placement.md) for details and limitations |

For more information on the partitioning scheme used by Container Linux, read the [disk layout](../os/sdk-disk-partitions.md) documentation.
