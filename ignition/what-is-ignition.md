# What is Ignition?

Ignition is a new provisioning utility designed specifically for Container Linux. At the the most basic level, it is a tool for manipulating disks during early boot. This includes partitioning disks, formatting partitions, writing files (regular files, systemd units, networkd units, etc.), and configuring users. On first boot, Ignition reads its configuration from a source-of-truth (remote URL, network metadata service, hypervisor bridge, etc.) and applies the configuration.

A [series of example configs][examples] are provided for reference.

## Ignition vs coreos-cloudinit

Ignition solves many of the same problems as [coreos-cloudinit][cloudinit] but in a simpler, more predictable, and more flexible manner. This is achieved with two major changes: Ignition only runs once and Ignition does not handle variable substitution. Ignition has also fixed a number of the pain points with regard to configuration.

Instead of YAML, Ignition uses JSON for its configuration format. JSON's typing immediately eliminates problems like "off" being rewritten as "false", the "#cloud-config" header being stripped because comments *shouldn't* have meaning, and confusion around whether those file permissions were written in octal or decimal. Ignition's configuration is also versioned which allows it to be improved in the future without having to worry as much about maintaining backward compatibility.

### Ignition only runs once

Even though Ignition only runs once, it packs a powerful punch. Because Ignition runs so early in the boot process (in the initramfs, to be exact), it is able to repartition disks, format filesystems, create users, and write files all before the userspace has begun booting.

A result of Ignition running so early is that the issue of [configuring the network][network config] falls away; the network config is written early enough for networkd to read when it first starts. It also means systemd services are already written to disk by the time systemd starts. This results in a simple startup, a faster startup, and the ability to accurately inspect the unit dependency graphs.

### No variable substitution

Given that Ignition only runs once, it wouldn't make much sense for it to incorporate dynamic data (e.g. floating IP addresses, compute region, etc.). This is partly why there is no support for variable substition.

Instead of dynamic data, the proper approach is to use Ignition to write static files and leverage systemd's environment variable expansion to insert dynamic data. The Ignition config should install a service which fetches the necessary runtime data and then any services which need this data (e.g. etcd, fleet) can depend on that aforementioned service and source in its output. The result is that the data is only collected if and when it is needed. For supported platforms, Container Linux provides a small utility (`coreos-metadata.service`) to help fetch this data.

The lack of variable substitution in Ignition has an added benifit of leveling the playing field when it comes to compute providers. No longer is the user's experince crippled because the metadata for their platform isn't supported. It is possible to write a [custom metadata agent][custom agent] to fetch the necessary data.

### When is Ignition executed

On boot, GRUB checks the disks for the dummy disk UUID (`00000000-0000-0000-0000-000000000001`) and sets `coreos.first_boot=1` if it is found. This parameter is then processed by a [systemd-generator] in the [initramfs] and if the parameter is set to non-zero, `ignition.target` is set as a dependency of `initrd.target`, causing Ignition to run.

Note that [PXE][supported platforms] deployments don't using GRUB to boot, so the `coreos.first_boot=1` parameter will need to be added to the boot arguments in order for Ignition to run.

## Providing Ignition a config

Ignition can read its config from a number of different locations, although, only one can be used at a time. When running Container Linux on the supported cloud providers, Ignition will read its config from the instance's userdata. This means that if Ignition is being used, it will not be possible to use other tools which also use this userdata (e.g. coreos-cloudinit). Bare metal installations and PXE boots can use the kernel boot parameters to point Ignition at the config.

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

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/ignition/what-is-ignition.md?pixel)]() <!-- END ANALYTICS -->