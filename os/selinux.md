# Using SELinux on CoreOS

SELinux is a fine-grained access control mechanism integrated into
CoreOS and rkt. Each container runs in its own independent SELinux context,
increasing isolation between containers and providing another layer of
protection should a container be compromised.

CoreOS implements SELinux, but currently does not enforce SELinux protections
by default. This allows deployers to verify container operation before enabling
SELinux enforcement. This document covers the process of checking containers
for SELinux policy compatibility, and switching SELinux into `enforcing` mode.

## Checking a Container's Compatibility with SELinux Policy

To verify whether the current SELinux policy would inhibit your containers,
enable SELinux logging by running the following commands as root:

* `rm /etc/audit/rules.d/80-selinux.rules`
* `rm /etc/audit/rules.d/99-default.rules`
* `semodule -DB`
* `systemctl restart audit-rules`

Now run your container. Check the system logs for any messages containing
`avc: denied`. Such messages indicate that an `enforcing` SELinux would prevent
the container from performing the logged operation. Please open an issue at
[coreos/bugs](https://github.com/coreos/bugs/issues), including the full avc log
message.

## Enabling SELinux Enforcement

Once satisfied that your container workload is compatible with the SELinux
policy, you can temporarily enable enforcement by running the following command
as root:

* `$ setenforce 1`

A reboot will reset SELinux to `permissive` mode.

To enable SELinux enforcement across reboots, do the following:

* `$ cp --remove-destination $(readlink -f /etc/selinux/config) /etc/selinux/config`
* Edit `/etc/selinux/config` and replace "SELINUX=permissive" with "SELINUX=enforcing"

## Limitations

SELinux enforcement is currently incompatible with Btrfs volumes and volumes
that are shared between multiple containers.
