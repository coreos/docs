# Network configuration with networkd

CoreOS machines are preconfigured with [networking customized](notes-for-distributors.md) for each platform. You can write your own networkd units to replace or override the units created for each platform. This article covers a subset of networkd functionality. You can view the [full docs here](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

Drop a networkd unit in `/etc/systemd/network/` or inject a unit on boot via [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md#units) to override an existing unit. Network units injected via the `coreos.units` node in the cloud-config will automatically trigger a networkd reload in order for changes to be applied. Files placed on the filesystem will need to reload networkd afterwards with `sudo systemctl restart systemd-networkd`.

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
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
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

### networkd and bond0

By default, the kernel creates a `bond0` network device as soon as the `bonding` module is loaded. The device is created with default bonding options, such as "round-robin" mode. This leads to confusing behavior with `systemd-networkd` since networkd does not alter options of an existing network device.

You have two options:

* Name your bond something other than `bond0`, or
* Prevent the kernel from automatically creating `bond0`.

To defer creating `bond0`, add to your cloud-config
before any other network configuration:

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
      MIIMonitorSec=100
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

### networkd and DHCP behavior

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

[drop-ins]: using-systemd-drop-in-units.md
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md

## Further reading

If you're interested in more general networkd features, check out the [full documentation](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

<a class="btn btn-default" href="getting-started-with-systemd.md">Getting Started with systemd</a>
<a class="btn btn-default" href="reading-the-system-log.md">Reading the System Log</a>
