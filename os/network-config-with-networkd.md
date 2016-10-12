# Network configuration with networkd

CoreOS machines are preconfigured with [networking customized](notes-for-distributors.md) for each platform. You can write your own networkd units to replace or override the units created for each platform. This article covers a subset of networkd functionality. You can view the [full docs here](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

Drop a networkd unit in `/etc/systemd/network/` or inject a unit on boot via [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md#units) or [Ignition][ignition-network] to override an existing unit. Network units injected via the `coreos.units` node in the cloud-config will automatically trigger a networkd reload in order for changes to be applied. Files placed on the filesystem will need to reload networkd afterwards with `sudo systemctl restart systemd-networkd`. Network units injected via Ignition will be written to the system before networkd is started, so there are no work-arounds needed.

Let's take a look at two common situations: using a static IP and turning off DHCP.

## Static networking

To configure a static IP on `enp2s0`, create `static.network`:

```ini
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
```

Place the file in `/etc/systemd/network/`. To apply the configuration, run:

```sh
sudo systemctl restart systemd-networkd
```

### Cloud-config

Setting up static networking in your cloud-config can be done by writing out the network unit. Be sure to modify the `[Match]` section with the name of your desired interface, and replace the IPs:

```yaml
#cloud-config

coreos:
  units:
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=1.2.3.4
        Address=10.0.0.101/24
        Gateway=10.0.0.1
```

### Ignition Config

Setting up static networking in your Ignition config can also be done by writing out the network unit. Be sure to modify the `[Match]` section with the name of your desired interface, and replace the IPs:

```json
{
  "ignition": { "version": "2.0.0" },
  "networkd": {
    "units": [{
      "name": "00-eth0.network",
      "contents": "[Match]\nName=eth0\n\n[Network]\nDNS=1.2.3.4\nAddress=10.0.0.101/24\nGateway=10.0.0.1"
    }]
  }
}
```

### networkd and bond0 with cloud-init

By default, the kernel creates a `bond0` network device as soon as the `bonding` module is loaded by coreos-cloudinit. The device is created with default bonding options, such as "round-robin" mode. This leads to confusing behavior with `systemd-networkd` since networkd does not alter options of an existing network device.

You have three options:

* Use Ignition to [configure your network][ignition-network]
* Name your bond something other than `bond0`, or
* Prevent the kernel from automatically creating `bond0`.

To defer creating `bond0`, add to your cloud-config before any other network configuration:

```yaml
#cloud-config

write_files:
  - path: /etc/modprobe.d/bonding.conf
    content: |
      # Prevent kernel from automatically creating bond0 when the module is loaded.
      # This allows systemd-networkd to create and apply options to bond0.
      options bonding max_bonds=0
  - path: /etc/systemd/network/10-eth.network
    permissions: 0644
    owner: root
    content: |
      [Match]
      Name=eth*

      [Network]
      Bond=bond0
  - path: /etc/systemd/network/20-bond.netdev
    permissions: 0644
    owner: root
    content: |
      [NetDev]
      Name=bond0
      Kind=bond

      [Bond]
      Mode=0 # defaults to balance-rr
      MIIMonitorSec=1
  - path: /etc/systemd/network/30-bond-dhcp.network
    permissions: 0644
    owner: root
    content: |
      [Match]
      Name=bond0

      [Network]
      DHCP=ipv4
coreos:
  units:
    - name: down-interfaces.service
      command: start
      content: |
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/ip link set eth0 down
        ExecStart=/usr/bin/ip addr flush dev eth0
        ExecStart=/usr/bin/ip link set eth1 down
        ExecStart=/usr/bin/ip addr flush dev eth1
    - name: systemd-networkd.service
      command: restart
```

### networkd and DHCP behavior with cloud-init

By default, even if you've already set a static IP address and you have a working DHCP server in your network, systemd-networkd will nevertheless assign IP address using DHCP. If you would like to remove this address, you have to use the following cloud-config example:

```yaml
#cloud-config

coreos:
  units:
    - name: systemd-networkd.service
      command: stop
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=1.2.3.4
        Address=10.0.0.101/24
        Gateway=10.0.0.1
    - name: down-interfaces.service
      command: start
      content: |
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/ip link set eth0 down
        ExecStart=/usr/bin/ip addr flush dev eth0
    - name: systemd-networkd.service
      command: restart
```

Again, when using Ignition, nothing special needs to be done.

## Turn off DHCP on specific interface

If you'd like to use DHCP on all interfaces except `enp2s0`, create two files. They'll be checked in lexical order, as described in the [full network docs](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html). Any interfaces matching during earlier files will be ignored during later files.

#### 10-static.network

```ini
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
```

Put your settings-of-last-resort in `20-dhcp.network`. For example, any interfaces matching `en*` that weren't matched in `10-static.network` will be configured with DHCP:

#### 20-dhcp.network

```ini
[Match]
Name=en*

[Network]
DHCP=yes
```

To apply the configuration, run `sudo systemctl restart systemd-networkd`. Check the status with `systemctl status systemd-networkd` and read the full log with `journalctl -u systemd-networkd`.

## Turn off IPv6 on specific interfaces

While IPv6 can be disabled globally at boot by appending `ipv6.disable=1` to the kernel command line, networkd supports disabling IPv6 on a per-interface basis. When a network unit's `[Network]` section has either `LinkLocalAddressing=ipv4` or `LinkLocalAddressing=no`, networkd will not try to configure IPv6 on the matching interfaces.

Note however that even when using the above option, networkd will still be expecting to receive router advertisements if IPv6 is not disabled globally. If IPv6 traffic is not being received by the interface (e.g. due to `sysctl` or `ip6tables` settings), it will remain in the `configuring` state and potentially cause timeouts for services waiting for the network to be fully configured. To avoid this, the `IPv6AcceptRA=no` option should also be set in the `[Network]` section.

A network unit file's `[Network]` section should therefore contain the following to disable IPv6 on its matching interfaces.

```ini
[Network]
LinkLocalAddressing=no
IPv6AcceptRA=no
```

## Configure static routes

Specify static routes in a systemd network unit's `[Route]` section. In this example, we create a unit file, `10-static.network`, and define in it a static route to the `172.16.0.0/24` subnet:

#### 10-static.network

```ini
[Route]
Gateway=192.168.122.1
Destination=172.16.0.0/24
```

To specify the same route in a cloud-config, create the systemd network unit there instead:

```yaml
coreos:
  units:
    - name: 10-static.network
      content: |
        [Route]
        Gateway=192.168.122.1
        Destination=172.16.0.0/24
```

And via an Ignition config:

```json
{
  "ignition": { "version": "2.0.0" },
  "networkd": {
    "units": [{
      "name": "10-static.network",
      "contents": "[Route]\nGateway=192.168.122.1\nDestination=172.16.0.0/24"
    }]
  }
}
```

## Configure multiple IP addresses

To configure multiple IP addresses on one interface, we define multiple `Address` keys in the network unit. In the example below, we've also defined a different gateway for each IP address.

#### 20-multi_ip.network

```ini
[Match]
Name=eth0

[Network]
DNS=8.8.8.8
Address=10.0.0.101/24
Gateway=10.0.0.1
Address=10.0.1.101/24
Gateway=10.0.1.1
```

To do the same thing through the cloud-config mechanism:

```yaml
coreos:
  units:
    - name: 20-multi_ip.network
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=8.8.8.8
        Address=10.0.0.101/24
        Gateway=10.0.0.1
        Address=10.0.1.101/24
        Gateway=10.0.1.1
```

And via Ignition:

```json
{
  "ignition": { "version": "2.0.0" },
  "networkd": {
    "units": [{
      "name": "20-multi_ip.network",
      "contents": "[Match]\nName=eth0\n\n[Network]\nDNS=8.8.8.8\nAddress=10.0.0.101/24\nGateway=10.0.0.1\nAddress=10.0.1.101/24\nGateway=10.0.1.1"
    }]
  }
}
```

## Debugging networkd

If you've faced some problems with networkd you can enable debug mode following the instructions below.

### Enable debugging manually

```sh
mkdir -p /etc/systemd/system/systemd-networkd.service.d/
```

Create [Drop-In][drop-ins] `/etc/systemd/system/systemd-networkd.service.d/10-debug.conf` with following content:

```sh
[Service]
Environment=SYSTEMD_LOG_LEVEL=debug
```

And restart `systemd-networkd` service:

```sh
systemctl daemon-reload
systemctl restart systemd-networkd
journalctl -b -u systemd-networkd
```

### Enable debugging through cloud-config

Define a [Drop-In][drop-ins] in a [Cloud-Config][cloud-config]:

```yaml
#cloud-config
coreos:
  units:
    - name: systemd-networkd.service
      drop-ins:
        - name: 10-debug.conf
          content: |
            [Service]
            Environment=SYSTEMD_LOG_LEVEL=debug
      command: restart
```

And run `coreos-cloudinit` or reboot your CoreOS host to apply the changes.

[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md

### Enable debugging through Ignition

Define a [Drop-In][drop-ins] in an Ignition config:

```json
{
  "ignition": { "version": "2.0.0" },
  "systemd": {
    "units": [{
      "name": "systemd-networkd.service",
      "dropins": [{
        "name": "10-debug.conf",
        "contents": "[Service]\nEnvironment=SYSTEMD_LOG_LEVEL=debug"
      }]
    }]
  }
}
```

## Further reading

If you're interested in more general networkd features, check out the [full documentation](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

<a class="btn btn-default" href="getting-started-with-systemd.md">Getting Started with systemd</a>
<a class="btn btn-default" href="reading-the-system-log.md">Reading the System Log</a>

[drop-ins]: using-systemd-drop-in-units.md
[ignition-network]: ../ignition/network-configuration.md
