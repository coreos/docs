# CoreOS Container Linux hardening guide

This guide covers the basics of securing a Container Linux instance. Container Linux has a very slim network profile and the only service that listens by default on Container Linux is sshd on port 22 on all interfaces. There are also some defaults for local users and services that should be considered.

## Remote listening services

### Disabling sshd

To disable sshd from listening you can stop the socket:

```
systemctl mask sshd.socket --now
```

If you wish to make further customizations see our [customize sshd guide][sshd-guide].

## Remote non-listening services

### etcd and Locksmith

etcd and Locksmith should be secured and authenticated using TLS if you are using these services. Please see the relevant guides for details.

* [etcd security guide][etcd-sec-guide]

## Local services

### Local users

Container Linux has a single default user account called "core". Generally this user is the one that gets ssh keys added to it via a Container Linux Config for administrators to login. The core user, by default, has access to the wheel group which grants sudo access. You can change this by removing the core user from wheel by running this command: `gpasswd -d core wheel`.

### Docker daemon

The docker daemon is accessible via a unix domain socket at `/run/docker.sock`. Users in the "docker" group have access to this service and access to the docker socket grants similar capabilities to sudo. The core user, by default, has access to the docker group. You can change this by removing the core user from docker by running this command: `gpasswd -d core docker`.

### rkt fetch

Users in the "rkt" group have access to the rkt container image store. A user may download new images and place them in the store if they belong to this group. This could be used as an attack vector to insert images that are later executed as root by the rkt container runtime. The core user, by default, has access to the rkt group. You can change this by removing the core user from rkt by running this command: `gpasswd -d core rkt`.

## Additional hardening

### Disabling Simultaneous Multi-Threading

Recent Intel CPU vulnerabilities cannot be fully mitigated in software without disabling Simultaneous Multi-Threading. This can have a substantial performance impact and is only necessary for certain workloads, so for compatibility reasons, SMT is enabled by default.

The [SMT on Container Linux guide][smt-guide] provides guidance and instructions for disabling SMT.

### SELinux

SELinux is a fine-grained access control mechanism integrated into Container Linux. Each container runs in its own independent SELinux context, increasing isolation between containers and providing another layer of protection should a container be compromised.

Container Linux implements SELinux, but currently does not enforce SELinux protections by default. The [SELinux on Container Linux guide][selinux-guide] covers the process of checking containers for SELinux policy compatibility and switching SELinux into enforcing mode.


[smt-guide]: disabling-smt.md
[sshd-guide]: customizing-sshd.md
[etcd-sec-guide]: https://github.com/coreos/etcd/blob/v3.2.11/Documentation/op-guide/security.md
[selinux-guide]: selinux.md
