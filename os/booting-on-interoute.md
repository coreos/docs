# Running CoreOS Container Linux on Interoute VDC

[Interoute Virtual Data Centre](https://cloudstore.interoute.com/what_is_vdc) is an Infrastructure-as-a-Service platform, which is integrated into Interoute's [global fibre optic network](https://cloudstore.interoute.com/networking).

This document is a guide to deploying a single Container Linux virtual machine on Interoute VDC. The Container Linux default configuration of SSH keypair-based authentication will be used.

Note: commands beginning with '$' are to be typed into the command line, and commands beginning '>' are to be typed into Cloudmonkey.

## Prerequisites

The following are assumed:

* You have an Interoute VDC account. You can easily [sign up for a free trial](https://cloudstore.interoute.com/vdc-trial).
* You have an API key and a Secret key for your VDC account. See [how to generate API access keys for VDC](http://cloudstore.interoute.com/knowledge-centre/library/vdc-api-introduction-api) if you need to create these.
* You have the Cloudmonkey command line tool installed and configured for Interoute VDC on the computer that you are working on.

## Cloudmonkey setup

Instructions on how to install and configure Cloudmonkey so that it can communicate with the VDC API can be found in the [Introduction to the VDC API](http://cloudstore.interoute.com/knowledge-centre/library/vdc-api-introduction-api).

Open a new terminal or command prompt window and start Cloudmonkey by typing:

```sh
$ cloudmonkey
Apache CloudStack cloudmonkey 5.3.2. Type help or ? to list commands.

Using management server profile: local

(local) >
```

If you see the '>' prompt as above then Cloudmonkey has started successfully and it's ready to accept API calls. All of the VDC API commands that can be accepted by Cloudmonkey can be found in the [VDC API Command Reference](http://cloudstore.interoute.com/knowledge-centre/library/api-command-reference).

Type the three following commands to set the configuration as it is used in the rest of this demonstration:

```sh
(local) > set display table
(local) > set asyncblock true
(local) > sync
252 APIs discovered and cached
```

## Create a new SSH keypair and store it in VDC

The Container Linux virtual machine template does not allow any logins (root user or otherwise) using passwords. So you must have a SSH keypair ready for use before you deploy the virtual machine.

A new keypair is generated using the OpenSSH command line tool, 'ssh-keygen':

```sh
# for Linux
$ cd ~/.ssh && ssh-keygen -t rsa -f id_rsa_coreos
# for Windows
cd C:/ && ssh-keygen -t rsa -f id_rsa_coreos    
```

The keypair consists of two files, the private key which will be in a file named 'id_rsa_coreos', and the public key in the file 'id_rsa_coreos.pub'. The private key should always be held securely on your own computer.

The next step is to 'register' your keypair by uploading your public key to VDC, so that virtual machines can boot up with that information:

```sh
> registerSSHKeyPair name=Container-Linux-Key01 publickey="ssh-rsa AAAAB3NzaC1y...........fyskMb4oBw== demo.user@interoute.com"
keypair:
name = Container-Linux-Key01
fingerprint = 55:33:b4:d3:b6:52:fb:79:97:fc:e8:16:58:6e:42:ce
```

(The public key input has been abbreviated here; it must be entered as a single long sequence, be careful when copying the public key that you don't introduce any linebreaks.)

The keypair 'name' parameter is arbitrary and is used to identify this public key. Multiple keys can be stored in your VDC account.

For security reasons you can't extract the value of the public key from VDC, only its 'fingerprint' value which you can compare against the fingerprint generated from the keypair on your own computer.

## Choosing a CoreOS Container Linux virtual machine template

Interoute VDC has 'CoreOS Stable' and 'CoreOS Alpha' templates ready-to-use, look for the template names IRT-COREOS and IRT-COREOS-ALPHA, respectively.

This command shows the templates available in the 'Zurich' zone, which has a zoneid as shown:

```sh
> listTemplates templatefilter=executable zoneid=a5d3e015-0797-4283-b562-84feea6f66af filter=id,name
count = 109
template:
+--------------------------------------+----------------------------------------+
|                  id                  |                  name                  |
+--------------------------------------+----------------------------------------+
| 73bc5066-b536-4325-8e27-ec873cea6ce7 |               IRT-COREOS               |
| 38192dd8-a81f-4c75-9e5f-9bc935d37eae |            IRT-COREOS-ALPHA            |
+--------------------------------------+----------------------------------------+
```

There are 109 templates in the list, only the relevant COREOS ones are shown here. You can filter the output using grep:

```sh
> listTemplates templatefilter=executable zoneid=a5d3e015-0797-4283-b562-84feea6f66af filter=id,name | grep COREOS
```

## Deploy a CoreOS Container Linux virtual machine

The following API call is used to deploy a new virtual machine running Container Linux in VDC:

```sh
> deployVirtualMachine serviceofferingid=85228261-fc66-4092-8e54-917d1702979d zoneid=a5d3e015-0797-4283-b562-84feea6f66af templateid=73bc5066-b536-4325-8e27-ec873cea6ce7 networkids=c5841e7c-e69e-432b-878b-c108b07a160f keypair=Container-Linux-Key01 name=Container-Linux-VM-01
```

Six parameter values are required. 'keypair' and 'templateid' you have already seen above. 'name' can be any string of your choice.

VDC's zones correspond to physical data centres in different locations. Use 'listZones' to get a full list for the Europe region:

```sh
> listZones filter=id,name
count = 10
zone:
+-------------------+--------------------------------------+
|        name       |                  id                  |
+-------------------+--------------------------------------+
|    Paris (ESX)    | 374b937d-2051-4440-b02c-a314dd9cb27e |
|    Milan (ESX)    | 58848a37-db49-4518-946a-88911db0ee2b |
|    Berlin (ESX)   | fc129b38-d490-4cd9-acf8-838cf7eb168d |
| Amsterdam 2 (ESX) | 3c43b32b-fadf-4629-b8e9-61fb7a5b9bb8 |
|   London 2 (ESX)  | f6b0d029-8e53-413b-99f3-e0a2a543ee1d |
|    Slough (ESX)   | 5343ddc2-919f-4d1b-a8e6-59f91d901f8e |
|   Geneva 2 (ESX)  | 1ef96ec0-9e51-4502-9a81-045bc37ecc0a |
|    Madrid (ESX)   | ddf450f2-51b2-433d-8dea-c871be6de38d |
|  Frankfurt (ESX)  | 7144b207-e97e-4e4a-b15d-64a30711e0e7 |
|    Zurich (ESX)   | a5d3e015-0797-4283-b562-84feea6f66af |
+-------------------+--------------------------------------+
```

The 'serviceofferingid' represents the amount of RAM memory and number of CPUs that you want to allocate to the virtual machine. In this example, 2 CPUs and 4 GBytes of RAM have been chosen. The following command can be used to obtain the corresponding value for the id:

```sh
> listServiceOfferings name=4096-2 filter=id
+--------------------------------------+
|                  id                  |
+--------------------------------------+
| 85228261-fc66-4092-8e54-917d1702979d |
+--------------------------------------+
```

Finally, the 'networkids' parameter specifies the network(s) to which the virtual machine will be attached. You need to specify at least one network.

You can use the listNetworks command to get information about the available networks.

```sh
> listNetworks zoneid=a5d3e015-0797-4283-b562-84feea6f66af filter=id,name
count = 3
network:
+--------------------------------------+-----------------------------------------------------+
|                  id                  |                         name                        |
+--------------------------------------+-----------------------------------------------------+
| c5841e7c-e69e-432b-878b-c108b07a160f |          Network Local Interoute Demo 2             |
| 9a06d83e-5d50-4aec-8b93-96d4af4c6c3b | Network Private Direct Connect Interoute Demo 16    |
| 2c60fa40-2bcc-4b27-9602-7ba9a68ee59d | Network Private Direct Connect Interoute Demo 13    |
+--------------------------------------+-----------------------------------------------------+
```

This is the output for the demonstration VDC account. The networks in your account will be different. If there is no network present in the zone that you want to use then you will need to [create a network](https://cloudstore.interoute.com/knowledge-centre/library/vdc-api-how-create-network).

The appropriate choice here is the 'Local' network which has Internet access. The other networks are only used for private inter-connection between VDC zones.

When you run the deployVirtualMachine command you will get a long output such as following (which has been abbreviated):

```sh
cmd = org.apache.cloudstack.api.command.user.vm.DeployVMCmd
created = 2015-12-22T19:51:27+0000
jobid = 353896d4-3160-465e-a746-a417ab40eec4
jobprocstatus = 0
jobresult:
virtualmachine:
id = e08a3199-9d16-4244-aa89-23395d9627d7
name = Container-Linux-VM-01
account = Interoute Demo
affinitygroup:
cpunumber = 2
cpuspeed = 2000
created = 2015-12-22T19:51:26+0000
displayname = Container-Linux-VM-01
domain = Interoute Demo
haenable = True
hypervisor = VMware
isdynamicallyscalable = True
jobid = 353896d4-3160-465e-a746-a417ab40eec4
keypair = Container-Linux-Key01
memory = 4096
passwordenabled = False
serviceofferingid = 85228261-fc66-4092-8e54-917d1702979d
serviceofferingname = 4096-2
state = Running
templatedisplaytext = Container Linux (Must be deployed with CLI e.g. CloudMonkey)
templateid = 73bc5066-b536-4325-8e27-ec873cea6ce7
templatename = IRT-COREOS
zoneid = a5d3e015-0797-4283-b562-84feea6f66af
zonename = Zurich (ESX)
```

Note that no root password is output because password access is not enabled for this virtual machine. You can only access by presenting the private key which matches the public key that you uploaded.

## Connecting to the new CoreOS Container Linux virtual machine

To be able to make an SSH connection from the Internet to the virtual machine a port forwarding rule for the network must be created.

```sh
> createPortForwardingRule protocol=TCP publicport=22 ipaddressid=b2b68408-76a9-4dc7-9a2f-f3cf10616aca virtualmachineid=e08a3199-9d16-4244-aa89-23395d9627d7 privateport=22 openfirewall=true
```
The 'virtualmachineid' can be read from the deploy output above. 'ipaddressid' can be found with the API command listPublicIpAddresses, and (if there is more than one public IP address) you look for the 'associatednetworkid' matching the id of the network that the virtual machine is attached to:

```sh
> listPublicIpAddresses zoneid=a5d3e015-0797-4283-b562-84feea6f66af filter=id,ipaddress,associatednetworkid
count = 1
publicipaddress:
+-----------------+--------------------------------------+--------------------------------------+
|   ipaddress     |         associatednetworkid          |                  id                  |
+-----------------+--------------------------------------+--------------------------------------+
| 213.XXX.XXX.185 | c5841e7c-e69e-432b-878b-c108b07a160f | b2b68408-76a9-4dc7-9a2f-f3cf10616aca |
+-----------------+--------------------------------------+--------------------------------------+
```

(The full IP address has been Xed out for privacy reasons.)

The last configuration step is to create an egress firewall rule for the network so that the Container Linux virtual machine will be able to get outward access to the Internet. This is needed to allow Container Linux to access update servers to do automatic updating, and for Docker to access repositories for container images:

```sh
> createEgressFirewallRule networkid=c5841e7c-e69e-432b-878b-c108b07a160f protocol=all cidr=0.0.0.0/0
```

(Note that these network rules are simple and permissive, while rules for production virtual machines should always be more strictly defined.)

The virtual machine is now set up for connection, using the 'ipaddress' found above and specifying the private SSH key file to match the public key which was registered in VDC. Note that there is no root user in Container Linux, the default user is 'core':

```sh
$ ssh -i ~/.ssh/id_rsa_coreos core@213.XXX.XXX.185
```

For the first connection to the virtual machine you will be asked to check authenticity:

```sh
The authenticity of host '213.XXX.XXX.185 (213.XXX.XXX.185)' can't be established.
ED25519 key fingerprint is e8:6a:a9:02:09:93:4a:2c:20:97:e4:56:da:c1:b7:a0.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '213.XXX.XXX.185' (ED25519) to the list of known hosts.
CoreOS stable (835.9.0)
core@Container-Linux-VM-01 ~ $
```

Check that the Internet egress is working by trying to connect to a remote location, for example:

```sh
core@Container-Linux-VM-01 ~ $ ping 8.8.8.8

core@Container-Linux-VM-01 ~ $ wget www.coreos.com
```

## Using CoreOS Container Linux in VDC

See the [Interoute VDC documentation](https://cloudstore.interoute.com/knowledge-centre/library/vdc-v2).

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/booting-on-interoute.md?pixel)]() <!-- END ANALYTICS -->