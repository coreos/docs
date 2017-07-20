# CoreOS Container Linux startup process

The Container Linux startup process is built on the standard [Linux startup process][linux-startup]. Since this process is already well documented and generally well understood, this document will focus on aspects specific to booting Container Linux.

## Bootloader

[GRUB][grub] is the first program executed when a Container Linux system boots. The Container Linux [GRUB config][grub-config] has several roles.

First, the GRUB config [specifies which `usr` partition to use][gptprio.next] from the two `usr` partitions Container Linux uses to provide atomic upgrades and rollbacks.

Second, GRUB [checks for a file called `coreos/first_boot` in the EFI System Partition][check-file] to determine if this is the first time a machine has booted. If that file is found, GRUB sets the `coreos.first_boot=detected` Linux kernel command line parameter. This parameter is used in later stages of the boot process.

Finally, GRUB [searches for the initial disk GUID][search-guid] (00000000-0000-0000-0000-000000000001) built into Container Linux images. This GUID is randomized later in the boot process so that individual disks may be uniquely identified. If GRUB finds this GUID it sets another Linux kernel command line parameter, `coreos.randomize_guid=00000000-0000-0000-0000-000000000001`.

## Early user space

After GRUB, the Container Linux startup process moves into the initial RAM file system. The initramfs mount the root filesystem, randomize the disk GUID, and run Ignition.

If the `coreos.randomize_guid` kernel parameter is provided, the disk with the specified GUID is given a new, random GUID.

If the `coreos.first_boot` kernel parameter is provided and non-zero, Ignition and networkd are started. networkd will use DHCP to set up temporary IP addresses and routes so that Ignition can fetch its configuration from the network.

### Ignition

When Ignition runs on Container Linux, it reads the Linux command line, looking for `coreos.oem.id`. Ignition uses this identifier to determine where to read the user-provided configuration and which provider-specific configuration to combine with the user's. This provider-specific configuration performs basic machine setup, and may include enabling `coreos-metadata-sshkeys@.service` (covered in more detail below).

After Ignition runs successfully, if `coreos.first_boot` was set to the special value `detected`, Ignition mounts the EFI System Partition and deletes the `coreos/first_boot` file.

## User space

After all of the tasks in the initramfs complete, the machine pivots into user space. It is at this point that systemd begins starting units, including, if it was enabled, `coreos-metadata-sshkeys@core.service`.

### SSH keys

`coreos-metadata-sshkeys@core.service` is responsible for fetching SSH keys from the machine's environment. The keys are written to `~core/.ssh/authorized_keys.d/coreos-metadata` and `update-ssh-keys` is run to update `~core/.ssh/authorized_keys`. On cloud platforms, the keys are read from the provider's metadata service. This service is not supported on all platforms and is enabled by Ignition *only* on those which are supported.

[check-file]: https://github.com/coreos/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg#L68-L71
[gptprio.next]: https://github.com/coreos/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg#L132
[grub]: https://www.gnu.org/software/grub/
[grub-config]: https://github.com/coreos/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg
[linux-startup]: https://en.wikipedia.org/wiki/Linux_startup_process
[search-guid]: https://github.com/coreos/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg#L73-L78
