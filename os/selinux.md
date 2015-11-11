# Using SELinux on CoreOS

SELinux is a fine-grained access control mechanism that is integrated into
CoreOS and rkt. Each container is run in its own independent SELinux
context, increasing isolation between containers even in the event of a
container being compromised. CoreOS implements SELinux, but currently does
not enforce SELinux protections by default.

## Determining whether containers are compatible with SELinux policy

To verify whether the current SELinux policy would inhibit your containers,
enable SELinux logging by running the following commands as root:

* `rm /etc/audit/rules.d/80-selinux.rules`
* `rm /etc/audit/rules.d/99-default.rules`
* `semodule -DB`
* `systemctl restart audit-rules`

and then run your container. Check the system logs for any messages
containing "avc: denied". If any appear, SELinux would prevent your
container from performing that operation once enforcement is enabled. Please
open an issue against coreos including the full avc message.

## Enabling SELinux enforcement

Once you're happy that your workload is compatible with the SELinux policy,
you can temporarily enable enforcement by running the following command as
root:

* `setenforce 1`

To enable it across reboots, do the following:

* `cp --remove-destination $(realpath /etc/selinux/config) /etc/selinux/config`
* Edit `/etc/selinux/config` and replace "SELINUX=permissive" with "SELINUX=enforcing"

## Limitations

SELinux enforcement is currently incompatible with Btrfs volumes and volumes
that are shared between multiple containers.
