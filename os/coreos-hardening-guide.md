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

Container Linux has a single default user account called "core". Generally this user is the one that gets ssh keys added to it via a Container Linux Config for administrators to login. The core users, by default, has access to the wheel group which grants sudo access. You can change this by removing the core user from wheel by running this command: `gpasswd -d core wheel`.

### Docker daemon

The docker daemon is accessible via a unix domain socket at /run/docker.sock. Users in the "docker" group have access to this service and access to the docker socket grants similar capabilities to sudo. The core user, by default, has access to the docker group. You can change this by removing the core user from docker by running this command: `gpasswd -d core docker`.

### rkt fetch

Users in the "rkt" group have access to the rkt container image store. A user may download new images and place them in the store if they belong to this group. This could be used as an attack vector to insert images that are later executed as root by the rkt container runtime. The core user, by default, has access to the rkt group. You can change this by removing the core user from rkt by running this command: `gpasswd -d core rkt`.

### fleet API socket

The fleet API allows management of the state of the cluster using JSON over HTTP. By default, Container Linux ships a socket unit for fleet (fleet.socket) which binds to a Unix domain socket, /var/run/fleet.sock. This socket is currently globally writable but will be restricted in a future release. Users with access to this socket and fleet configured have sudo equivalent access via systemd. To disable fleet completely run:

```
systemctl mask fleet.socket --now
```

To restrict access to fleet.socket to root only run:

```
mkdir -p /etc/systemd/system/fleet.socket.d
cat  << EOM > /etc/systemd/system/fleet.socket.d/10-root-only.conf
[Socket]
SocketMode=0600
SocketUser=root
SocketGroup=root
EOM
systemctl daemon-reload
```

[sshd-guide]: customizing-sshd.md
[etcd-sec-guide]: https://github.com/coreos/etcd/blob/v3.1.5/Documentation/op-guide/security.md
