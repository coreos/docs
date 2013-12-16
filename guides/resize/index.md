---
layout: docs
slug: guides/resize
title: Adding Disk Space
---

# Adding Disk Space to Your CoreOS Machine

Most writable paths such as `/home`, `/var`, and `/usr/local` are stored
in a special STATE partition mounted at `/media/state`. The default size
of this partition depends on the platform but it is usually
between 3GB and 16GB. If more space is required simply extend the
virtual machine's disk image and CoreOS will fix the partition table and
resize the STATE partition to fill the disk on the next boot.

## Amazon EC2

Amazon doesn't support directly resizing volumes, you must take a
snapshot and create a new volume based on that snapshot. Refer to
the AWS EC2 documentation on [expanding EBS volumes][ebs-expand-volume]
for detailed instructions.

[ebs-expand-volume]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-expand-volume.html

## QEMU (qemu-img)

Even if you are not using Qemu itself the qemu-img tool is the easiest
to use. It will work on raw, qcow2, vmdk, and most other formats. The
command accepts either an absolute size or a relative size by
by adding `+` prefix. Unit suffixes such as `G` or `M` are also supported.

```
# Increase the disk size by 5GB
qemu-img resize coreos_production_qemu_image.img +5G
```

## VMware

The interface available for resizing disks in VMware varies depending on
the product. See this [Knowledge Base article][vmkb1004047] for details.
Most products include a tool called `vmware-vdiskmanager`. The size must
be the absolute disk size, relative sizes are not supported so be
careful to only increase the size, not shrink it. The unit
suffixes `Gb` and `Mb` are supported.

```
# Set the disk size to 20GB
vmware-vdiskmanager -x 20Gb coreos_developer_vmware_insecure.vmx
```

[vmkb1004047]: http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1004047

## VirtualBox

Use qemu-img or vmware-vdiskmanager as described above. VirtualBox does
not support resizing VMDK disk images, only VDI and VHD disks. Meanwhile
VirtualBox only supports using VMDK disk images with the OVF config file
format used for importing/exporting virtual machines.

If you have have no other options you can try converting the VMDK disk
image to a VDI image and configuring a new virtual machine with it:

```
VBoxManage clonehd old.vmdk new.vdi --format VDI
VBoxManage modifyhd new.vdi --resize 20480
```