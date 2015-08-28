# Network Configuration #

Configuring networkd with Ignition is a very straightforward task. Because
Ignition runs before networkd starts, configuration is just a matter of writing
the desired config to disk. The Ignition config has a specific section
dedicated to this.

## Static Networking ##

In this example, the network interface with the name "eth0" will be given the
IP address 10.0.1.7. A typical interface will need more configuration and can
use all of the options of a [network unit][network].

```json
{
	"networkd": {
		"units": [
			{
				"name": "00-eth0.network",
				"contents": "[Match]\nName=eth0\n\n[Network]\nAddress=10.0.1.7"
			}
		]
	}
}
```

This configuration will instruct Ignition to create a single network unit named
"00-eth0.network" with the contents:

```
[Match]
Name=eth0

[Network]
Address=10.0.1.7
```

When the system boots, networkd will read this config and assign the IP address
to eth0.

[network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html

## Bonded NICs ##

In this example, all of the network interfaces whose names begin with "eth"
will be bonded together to form "bond0". This new interface will then be
configured to use DHCP.

```json
{
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
			},
		]
	}
}
```
