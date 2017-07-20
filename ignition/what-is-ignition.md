# What is Ignition?

Ignition is a new provisioning utility designed specifically for Container Linux, which allows you to manipulate disks during early boot. This includes partitioning disks, formatting partitions, writing files (regular files, systemd units, networkd units, and more), and configuring users. On first boot, Ignition reads its configuration from a source-of-truth (remote URL, network metadata service, or hypervisor bridge, for example) and applies the configuration.

A [series of example configs][examples] are provided for reference.

## Ignition vs coreos-cloudinit

Ignition solves many of the same problems as [coreos-cloudinit][cloudinit] but in a simpler, more predictable, and more flexible manner. This is achieved with two major changes: Ignition only runs once and it does not handle variable substitution. Ignition has also fixed a number of pain points with regard to configuration.

Instead of YAML, Ignition uses JSON for its configuration format. JSON's typing immediately eliminates problems like "off" being rewritten as "false", the "#cloud-config" header being stripped because comments *shouldn't* have meaning, and confusion around whether those file permissions were written in octal or decimal. Ignition's configuration is also versioned, which allows future development without persistent backward compatibility.

### Ignition only runs once

Even though Ignition only runs once, it packs a powerful punch. Because Ignition runs so early in the boot process (in the initramfs, to be exact), it is able to repartition disks, format filesystems, create users, and write files, all before the userspace begins to boot.

Because Ignition runs so early in the boot process, the network config is available for networkd to read when it first starts, and systemd services are already written to disk when systemd starts. [Configuring the network][network config] is no longer an issue. This results in a simple startup, a faster startup, and the ability to accurately inspect the unit dependency graphs.

### No variable substitution

Because Ignition only runs once, there's no reason for it to incorporate dynamic data (like  floating IP addresses, or compute regions).

Instead, use Ignition to write static files and leverage systemd's environment variable expansion to insert dynamic data. The Ignition config should install a service which fetches the necessary runtime data, then any services which need this data (such as etcd or fleet) can rely on the installed service and source in their output. The result is that the data is only collected if and when it is needed. For supported platforms, Container Linux provides a small utility (`coreos-metadata.service`) to help fetch this data.

The lack of variable substitution in Ignition has an added benefit of leveling the playing field when it comes to compute providers. The user's experience is no longer crippled because the metadata for their platform isn't supported. It is possible to write a [custom metadata agent][custom agent] to fetch the necessary data.

### When is Ignition executed

On boot, GRUB checks the EFI System Partition for a file at `coreos/first_boot` and sets `coreos.first_boot=detected` if found. The `coreos.first_boot` parameter is processed by a [systemd-generator] in the [initramfs] and if the parameter value is non-zero, the Ignition units are set as dependencies of `initrd.target`, causing Ignition to run. If the parameter is set to the special value `detected`, the `coreos/first_boot` file is deleted after Ignition runs successfully.

Note that [PXE][supported platforms] deployments don't use GRUB to boot, so `coreos.first_boot=1` must be added to the boot arguments in order for Ignition to run. `detected` should not be specified so Ignition will not attempt to delete `coreos/first_boot`.

## Providing Ignition a config

Ignition can read its config from a number of different locations, but only from one at a time. When running Container Linux on the supported cloud providers, Ignition will read its config from the instance's userdata. This means that if Ignition is being used, it will not be possible to use other tools which also use this userdata (such as coreos-cloudinit). Bare metal installations and PXE boots can use the kernel boot parameters to point Ignition at the config.

## Where is Ignition supported?

The [full list of supported platforms][supported platforms] is provided and will be kept up-to-date as development progresses.

Ignition is under active development. Expect to see support for more images in the coming months.

[examples]: https://github.com/coreos/ignition/blob/master/doc/examples.md
[cloudinit]: https://github.com/coreos/coreos-cloudinit
[network config]: network-configuration.md
[custom agent]: https://github.com/coreos/ignition/blob/master/doc/examples.md#custom-metadata-agent
[supported platforms]: https://github.com/coreos/ignition/blob/master/doc/supported-platforms.md
[systemd-generator]: http://www.freedesktop.org/software/systemd/man/systemd.generator.html
[initramfs]: https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt
