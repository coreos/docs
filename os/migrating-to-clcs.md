# Migrating from Cloud-Config to Container Linux Config

Historically, the recommended way to provision a Container Linux machine was with a cloud-config. This was a YAML file specifying things like systemd units to run, users that should exist, and files that should be written. This file would be given to a Container Linux machine, and saved on disk. Then a utility called coreos-cloudinit running in a systemd unit would read this file, look at the system state, and make necessary changes on every boot.

Going forward, a new method of provisioning with Container Linux Configs is now recommended.

This document details how to convert an existing cloud-config into a Container Linux Config. Once a Container Linux Config has been written, it is given to the Config Transpiler to be converted into an Ignition Config. This Ignition Config can then be provided to a booting machine. For more information on this process, take a look at the [provisioning guide][provisioning].

The etcd and flannel examples shown in this document will use dynamic data in the Container Linux Config (anything looking like this: `{PRIVATE_IPV4}`). Not all types of dynamic data are supported on all cloud providers, and if the machine is not on a cloud provider this feature cannot be used. Please see [here][dynamic-data] for more information.

To see all supported options available in a Container Linux Config, please look at the [Container Linux Config schema][ct-config].

### etcd2

In a cloud-config, etcd version 2 can be enabled and configured by using the `coreos.etcd2.*` section. As an example of this:

```cloud-config
#cloud-config

coreos:
  etcd2:
    discovery:                   "https://discovery.etcd.io/<token>"
    advertise-client-urls:       "http://$public_ipv4:2379"
    initial-advertise-peer-urls: "http://$private_ipv4:2380"
    listen-client-urls:          "http://0.0.0.0:2379,http://0.0.0.0:4001"
    listen-peer-urls:            "http://$private_ipv4:2380,http://$private_ipv4:7001"
```

etcd can be configured in a more general way with a Container Linux Config. This CL Config will use the etcd-member.service systemd unit rather than the etcd2 service understood by cloud-config and coreos-cloudinit. The etcd-member service will download a version of etcd of the user's choosing and run it. This means that in a Container Linux Config both etcd v2 and v3 can be configured.

This is done under the etcd section:

```yaml container-linux-config
etcd:
    version: 3.1.6
```

Omitting the version specification declares that the unit file should use the version of etcd matching the running version of Container Linux.

Configuration options in this section can be provided the same way as they were in a cloud-config, with the exception of dashes (`-`) being replaced with underscores (`_`) in key names.

```yaml container-linux-config:gce
etcd:
  name:                        "{HOSTNAME}"
  advertise_client_urls:       "{PRIVATE_IPV4}:2379"
  initial_advertise_peer_urls: "{PRIVATE_IPV4}:2380"
  listen_client_urls:          "http://0.0.0.0:2379"
  listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
  initial_cluster:             "%m=http://{PRIVATE_IPV4}:2380"
```

### flannel

Flannel is easily configurable in a cloud-config the same way etcd is, by using the `coreos.flannel.*` section.

```cloud-config
#cloud-config

coreos:
  flannel:
      etcd_prefix: "/coreos.com/network2"
```

The flannel section in a Container Linux Config is used the same way, and a version can optionally be specified for flannel as well.

```yaml container-linux-config
flannel:
  version:     0.7.0
  etcd_prefix: "/coreos.com/network2"
```

### locksmith

The `coreos.locksmith.*` section in a cloud-config can be used to configure the locksmith daemon via environment variables.

```cloud-config
#cloud-config

coreos:
  locksmith:
      endpoint: "http://example.com:2379"
```

Locksmith can be configured in the same way under the locksmith section of a Container Linux Config, but some of the accepted options are slightly different. Also the reboot strategy is set in the locksmith section, instead of the update section. Check out the [Container Linux Config schema][ct-config] to see what options are available.

```yaml container-linux-config
locksmith:
  reboot_strategy: "reboot"
  etcd_endpoints:  "http://example.com:2379"
```

### update

The `coreos.update.*` section can be used to configure the reboot strategy, update group, and update server in a cloud-config.

```cloud-config
#cloud-config
coreos:
  update:
    reboot-strategy: "etcd-lock"
    group:           "stable"
    server:          "https://public.update.core-os.net/v1/update/"
```

In the update section in a Container Linux Config the group and server can be configured, but the reboot-strategy option has been moved under the locksmith section.

```yaml container-linux-config
update:
  group:  "stable"
  server: "https://public.update.core-os.net/v1/update/"
```

### units

The `coreos.units.*` section in a cloud-config can define arbitrary systemd units that should be started after booting.

```cloud-config
#cloud-config

coreos:
  units:
    - name: "docker-redis.service"
      command: "start"
      content: |
        [Unit]
        Description=Redis container
        Author=Me
        After=docker.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker start -a redis_server
        ExecStop=/usr/bin/docker stop -t 2 redis_server
```

This section could also be used to define systemd drop-in files for existing units.

```cloud-config
#cloud-config

coreos:
  units:
    - name: "docker.service"
      drop-ins:
        - name: "50-insecure-registry.conf"
          content: |
            [Service]
            Environment=DOCKER_OPTS='--insecure-registry="10.0.1.0/24"'
```

And existing units could also be started without any further configuration.

```cloud-config
#cloud-config

coreos:
  units:
    - name: "etcd2.service"
      command: "start"
```

One big difference in Container Linux Config compared to cloud-configs is that the configuration is applied via [Ignition][ignition] before the machine has fully booted, as opposed to coreos-cloudinit that runs after the machine has fully booted. As a result units cannot be directly started in a Container Linux Config, the unit is instead enabled so that systemd will begin the unit once systemd starts.

_Note: in this example an `[Install]` section has been added so that the unit can be enabled._

```yaml container-linux-config
systemd:
  units:
    - name: "docker-redis.service"
      enable: true
      contents: |
        [Unit]
        Description=Redis container
        Author=Me
        After=docker.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker start -a redis_server
        ExecStop=/usr/bin/docker stop -t 2 redis_server

        [Install]
        WantedBy=multi-user.target
```

Drop-in files can be provided for units in a Container Linux Config just like in a cloud-config.

```yaml container-linux-config
systemd:
  units:
    - name: "docker.service"
      dropins:
        - name: "50-insecure-registry.conf"
          contents: |
            [Service]
            Environment=DOCKER_OPTS='--insecure-registry="10.0.1.0/24"'
```

Existing units can also be enabled without configuration.

```yaml container-linux-config
systemd:
  units:
    - name: "etcd-member.service"
      enable: true
```

### ssh_authorized_keys

In a cloud-config the `ssh_authorized_keys` section can be used to add ssh public keys to the `core` user.

```cloud-config
#cloud-config

ssh_authorized_keys:
  - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
```

In a Container Linux Config there is no analogous section to `ssh_authorized_keys`, but ssh keys for the core user can be set just as easily using the `passwd.users.*` section:

```yaml container-linux-config
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
```

### hostname

In a cloud-config the `hostname` section can be used to set a machine's hostname.

```cloud-config
#cloud-config

hostname: "coreos1"
```

The Container Linux Config is intentionally more generalized than a cloud-config, and there is no equivalent hostname section understood in a CL Config. Instead, set the hostname by writing it to `/etc/hostname` in a CL Config `storage.files.*` section.

```yaml container-linux-config
storage:
  files:
    - filesystem: "root"
      path:       "/etc/hostname"
      mode:       0644
      contents:
        inline: coreos1
```

### users

The `users` section in a cloud-config can be used to add users and specify many properties about them, from groups the user should be in to what the user's shell should be.

```cloud-config
#cloud-config

users:
  - name: "elroy"
    passwd: "$6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm..."
    groups:
      - "sudo"
      - "docker"
    ssh-authorized-keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
```

This same information can be added to the Container Linux Config in the `passwd.users.*` section.

```yaml container-linux-config
passwd:
  users:
    - name:          "elroy"
      password_hash: "$6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm..."
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
      groups:
        - "sudo"
        - "docker"
```

### write_files

The `write_files` section in a cloud-config can be used to specify files and their contents that should be written to disk on the machine.

```cloud-config
#cloud-config
write_files:
  - path:        "/etc/resolv.conf"
    permissions: "0644"
    owner:       "root"
    content: |
      nameserver 8.8.8.8
```

This can be done in a Container Linux Config with the `storage.files.*` section.

```yaml container-linux-config
storage:
  files:
    - filesystem: "root"
      path:       "/etc/resolv.conf"
      mode:       0644
      contents:
        inline: |
          nameserver 8.8.8.8
```

File specifications in this section of a CL Config must define the target filesystem and the file's path relative to the root of that filesystem. This allows files to be written to filesystems other than the root filesystem.

Under the `contents` section, the file contents are under a sub-section called `inline`. This is because a file's contents can be remote by replacing the `inline` section with a `remote` section. To see what options are available under the `remote` section, look at the [Container Linux Config schema][ct-config].

### manage_etc_hosts

The `manage_etcd_hosts` section in a cloud-config can be used to configure the contents of the `/etc/hosts` file. Currently only one value is supported, `"localhost"`, which will cause your system's hostname to resolve to `127.0.0.1`.

```cloud-config
#cloud-config

manage_etc_hosts: "localhost"
```

There is no analogous section in a Container Linux Config, however the `/etc/hosts` file can be written in the `storage.files.*` section.

```yaml container-linux-config
storage:
  files:
    - filesystem: "root"
      path:       "/etc/hosts"
      mode:       0644
      contents:
        inline: |
          127.0.0.1	localhost
          ::1		localhost
          127.0.0.1 example.com
```

[provisioning]: provisioning.md
[dynamic-data]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/dynamic-data.md
[ct-config]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/configuration.md
[ignition]: https://coreos.com/ignition
