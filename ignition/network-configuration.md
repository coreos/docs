# Network configuration

Configuring networkd with Ignition is a very straightforward task. Because Ignition runs before networkd starts, configuration is just a matter of writing the desired config to disk. The Ignition config has a specific section dedicated to this.

Each of these examples is written in version 2.0.0 of the config. Ensure that any configuration matches the version that Ignition expects.

## Static networking

In this example, the network interface with the name "eth0" will be given the IP address 10.0.1.7. A typical interface will need more configuration and may use all of the options of a [network unit][network].

```json ignition-config
{
  "ignition": { "version": "2.0.0" },
  "networkd": {
    "units": [{
      "name": "00-eth0.network",
      "contents": "[Match]\nName=eth0\n\n[Network]\nAddress=10.0.1.7"
    }]
  }
}
```

This configuration will instruct Ignition to create a single network unit named "00-eth0.network" with the contents:

```ini
[Match]
Name=eth0

[Network]
Address=10.0.1.7
```

When the system boots, networkd will read this config and assign the IP address to eth0.

### Using static IP addresses with Ignition

Because Ignition writes network configuration to disk for networkd to use later, statically-configured interfaces will be brought online only after Ignition has run. If static IP configuration is required to download remote configs before Ignition has run, use one of the following two forms of supported kernel command-line arguments.

This format can configure a static IP address on the named interface, or on all interfaces when unspecified.

* `ip=` to specify the IP address, for example `ip=10.0.2.42`
* `netmask=` to specify the netmask, for example `netmask=255.255.255.0`
* `gateway=` to specify the gateway address, for example `gateway=10.0.2.2`
* `ksdevice=` (optional) to limit configuration to the named interface, for example `ksdevice=eth0`

This format can be specified multiple times to apply unique static configuration to different interfaces. Omitting the `<iface>` parameter will apply the configuration to all interfaces that have not yet been configured.

* `ip=<ip>::<gateway>:<netmask>:<hostname>:<iface>:none[:<dns1>[:<dns2>]]`, for example `ip=10.0.2.42::10.0.2.2:255.255.255.0::eth0:none:8.8.8.8:8.8.4.4`

## Bonded NICs

In this example, all of the network interfaces whose names begin with "eth" will be bonded together to form "bond0". This new interface will then be configured to use DHCP.

```json ignition-config
{
  "ignition": { "version": "2.0.0" },
  "networkd": {
    "units": [
      {
        "name": "00-eth.network",
        "contents": "[Match]\nName=eth*\n\n[Network]\nBond=bond0"
      },
      {
        "name": "10-bond0.netdev",
        "contents": "[NetDev]\nName=bond0\nKind=bond"
      },
      {
        "name": "20-bond0.network",
        "contents": "[Match]\nName=bond0\n\n[Network]\nDHCP=true"
      }
    ]
  }
}
```

[network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html
