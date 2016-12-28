# CoreOS Container Linux startup process

The Container Linux startup process is built on the standard [Linux startup process][linux startup]. Since this process is already well documented and generally well understood, this document will focus on aspects specific to booting Container Linux.

## Bootloader

[GRUB][grub] is the first program executed when a Container Linux system boots.

The Container Linux [GRUB config][grub config] has several roles. First, the GRUB config [specifies which `usr` partition to use][gptprio.next] from the two `usr` partitions Container Linux uses to provide atomic upgrades and rollbacks.

Additionally, GRUB determines if this is the first time a machine has booted. This is accomplished by [searching for the initial disk GUID][search] (00000000-0000-0000-0000-000000000001). Container Linux is built with this well-known disk GUID in order to detect the first boot. This GUID is randomized later in the boot process so that individual disks may be uniquely identified. If GRUB detects that this is in fact a first boot, it sets two Linux kernel command line parameters: `coreos.randomize_guid=00000000-0000-0000-0000-000000000001` and `coreos.first_boot=1`. These parameters are used by various programs in later stages of the boot process.

## Early user space

The next major milestone in the Container Linux startup process is the jump into the initial RAM file system. In addition to its standard responsibility of mounting the root filesystem, the initramfs is also where the disk GUID is randomized and where Ignition runs.

If the `coreos.randomize_guid` kernel parameter is provided, the disk with the specified GUID is given a new, random GUID.

If the `coreos.first_boot` kernel parameter is provided, Ignition and networkd are started. networkd will use DHCP to set up temporary IP addresses and routes so that Ignition can potentially fetch its configuration from the network.

### Ignition

When Ignition runs on Container Linux, it reads the Linux command line, looking for `coreos.oem.id`. Ignition uses this identifier to determine where to read the user-provided configuration and which provider-specific configuration to be combined with the user's. This provider-specific configuration performs basic machine setup, potentially including enabling `coreos-metadata-sshkeys@.service` (this service will be covered in more detail below).

## User space

After all of the tasks in the initramfs complete, the machine pivots into user space. It is at this point that systemd begins starting units, including, if it was enabled, `coreos-metadata-sshkeys@core.service`.

### SSH keys

`coreos-metadata-sshkeys@core.service` is responsible for fetching SSH keys from the machine's environment. The keys are written to `~core/.ssh/authorized_keys.d/coreos-metadata` and `update-ssh-keys` is run to update `~core/.ssh/authorized_keys`. On cloud platforms, the keys are read from the provider's metadata service. This service is not supported on all platforms and is only enabled by Ignition on those which are supported.

[gptprio.next]: https://github.com/coreos/scripts/blob/069ae5644ff03d6f78d2268c5f3eae5012b35bc1/build_library/grub.cfg#L111
[grub]: https://www.gnu.org/software/grub/
[grub config]: https://github.com/coreos/scripts/blob/069ae5644ff03d6f78d2268c5f3eae5012b35bc1/build_library/grub.cfg
[linux startup]: https://en.wikipedia.org/wiki/Linux_startup_process
[search]: https://github.com/coreos/scripts/blob/069ae5644ff03d6f78d2268c5f3eae5012b35bc1/build_library/grub.cfg#L68
