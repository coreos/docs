# DNS Configuration

By default, DNS resolution on Container Linux is handled through `/etc/resolv.conf`, which is a symlink to `/run/systemd/resolve/resolv.conf`. This file is managed by [systemd-resolved][systemd-resolved]. Normally, `systemd-resolved` gets DNS IP addresses from [systemd-networkd][systemd-networkd], either via DHCP or static configuration. DNS IP addresses can also be set via `systemd-resolved`'s [resolved.conf][resolved.conf]. See [Network configuration with networkd](network-config-with-networkd.md) for more information on `systemd-networkd`.

## Using a local DNS cache

`systemd-resolved` includes a caching DNS resolver. To use it for DNS resolution and caching, you must enable it via [nsswitch.conf][nsswitch.conf] by adding `resolve` to the `hosts` section.

Here is an example cloud-config snippet to do that:

```yaml
#cloud-config
write_files:
  - path: /etc/nsswitch.conf
    permissions: 0644
    owner: root
    content: |
      # /etc/nsswitch.conf:

      passwd:      files usrfiles
      shadow:      files usrfiles
      group:       files usrfiles

      hosts:       files usrfiles resolve dns
      networks:    files usrfiles dns

      services:    files usrfiles
      protocols:   files usrfiles
      rpc:         files usrfiles

      ethers:      files
      netmasks:    files
      netgroup:    files
      bootparams:  files
      automount:   files
      aliases:     files
```

Here is an example Ignition config to perform the same:

```json
{
  "ignition": { "version": "2.0.0" },
  "storage": {
    "files": [{
      "filesystem": "root",
      "path": "/etc/nsswitch.conf",
      "mode": 420,
      "contents": { "source": "data:,#%20/etc/nsswitch.conf:%0A%0Apasswd:%20%20%20%20%20%20files%20usrfiles%0Ashadow:%20%20%20%20%20%20files%20usrfiles%0Agroup:%20%20%20%20%20%20%20files%20usrfiles%0A%0Ahosts:%20%20%20%20%20%20%20files%20usrfiles%20resolve%20dns%0Anetworks:%20%20%20%20files%20usrfiles%20dns%0A%0Aservices:%20%20%20%20files%20usrfiles%0Aprotocols:%20%20%20files%20usrfiles%0Arpc:%20%20%20%20%20%20%20%20%20files%20usrfiles%0A%0Aethers:%20%20%20%20%20%20files%0Anetmasks:%20%20%20%20files%0Anetgroup:%20%20%20%20files%0Abootparams:%20%20files%0Aautomount:%20%20%20files%0Aaliases:%20%20%20%20%20files%0A" }
    }]
  }
}
```

Only nss-aware applications can take advantage of the `systemd-resolved` cache. Notably, this means that statically linked Go programs and programs running within Docker/rkt will use `/etc/resolv.conf` only, and will not use the `systemd-resolve` cache.

[systemd-resolved]: http://www.freedesktop.org/software/systemd/man/systemd-resolved.service.html
[systemd-networkd]: http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html
[resolved.conf]: http://www.freedesktop.org/software/systemd/man/resolved.conf.html
[nsswitch.conf]: http://man7.org/linux/man-pages/man5/nsswitch.conf.5.html

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/configuring-dns.md?pixel)]() <!-- END ANALYTICS -->