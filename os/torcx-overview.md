# What is Torcx?

[Torcx][gh-torcx] is a new boot-time addon manager designed specifically for Container Linux. At the most basic level, it is a tool for applying ephemeral changes to an immutable system during early boot. This includes providing third-party binary addons and installing systemd units, which can vary across environments and boots. On every boot, Torcx reads its configuration from local disk and propagates specific assets provided by addon packages (which must be available in local stores).

## Torcx overview

Torcx complements both the [Ignition][ignition] provisioning utility and [systemd][systemd]. Torcx allows customization of Container Linux systems without requiring the compilation of custom system images. This goal is achieved by following two main principles: customizations are ephemeral, and they are applied exactly once per boot. Torcx also has a very simple design, with the aim of providing a small low-level system utility which can be driven by more advanced and higher-level tools.

### Torcx execution model and systemd generators

Early in the boot process, execution starts in a minimal initramfs environment where systemd, Ignition, and other boot utilities run. Once up, execution continues by pivoting into the real root file system and by running all [systemd generators][systemd-generator], including the main torcx component, `torcx-generator`.
`torcx-generator` runs serially before any other service starts to guarantee it does not race with other startup processes. However, this restricts Torcx to using only local resources. Torcx cannot access configuration or addons from remote file systems or network locations.

### Profiles and addons

Torcx customizations are applied via local addon packages, which are referenced by profiles. Addons are simple tar-gzipped archives containing binary assets and a manifest. A user profile (upper profile) can be supplied by the administrator to be merged on top of hard-coded vendor and OEM profiles (lower profiles). Torcx will take care of computing and applying the resulting list of addons on the system.

### Boot-time customizations

Torcx guarantees that customizations are applied at most once per boot, before any other service has been considered for startup. This provides a mechanism to customize most aspects of a Container Linux system in a reliable way, and avoids runtime upgrading/downgrading issues. Changes applied by Torcx are not persisted to disk, and therefore last exactly for the lifetime of a single boot of an instance.

By the same token, this should be read as a warning against abusing Torcx in the role of a general purpose container, service, or package manager. Torcx's boot-transient model consumes memory with each addon, and, worse, would require system reboots for even simple upgrades.

## Further design details

For further details on design and goals, Torcx repository contains extensive [developer documentation][devdocs].

[gh-torcx]: https://github.com/coreos/torcx
[ignition]: https://coreos.com/ignition/docs/latest/
[systemd]: https://www.freedesktop.org/wiki/Software/systemd/
[systemd-generator]: http://www.freedesktop.org/software/systemd/man/systemd.generator.html
[devdocs]: https://github.com/coreos/torcx/blob/master/Documentation
