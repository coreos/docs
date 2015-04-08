---
layout: docs
title: Interoute VDC
category: running_coreos
sub_category: cloud_provider
weight: 11
---

# Running CoreOS on Interoute VDC

Interoute Communications Limited is the owner operator of Europe's largest cloud services platform, which encompasses over 67,000 km of lit fiber, 12 data centres, 13 Virtual Data Centres and 31 colocation centres, with connections to 195 additional third-party data centres across Europe. 

To run a single CoreOS node on Interoute VDC the following is assumed:

* You have an Interoute VDC account. You can easily [sign up for a free trial](http://cloudstore.interoute.com/main/TryInterouteVDCFREE) (no credit card required).
* You have the  Cloudmonkey command line tool installed and configured on the computer that you are working on. Instructions on how to install and configure Cloudmonkey so that it can communicate with the VDC API can be found in the [Introduction to the VDC API](http://cloudstore.interoute.com/main/knowledge-centre/library/vdc-api-introduction-api).
* You have installed OpenSSH client software. This is usually already installed in Linux and Mac OS. For Windows it can be downloaded at the [OpenSSH website](http://www.openssh.com/).

Note: In the following steps, commands beginning with '$' are to be typed into the command line, and commands beginning '>' are to be typed into Cloudmonkey. 

## Cloudmonkey Setup

First you should open a new terminal or command prompt window and start Cloudmonkey by typing:

```cloudmonkey
$ cloudmonkey set display table && cloudmonkey sync && cloudmonkey
252 APIs discovered and cached
Apache CloudStack cloudmonkey 5.3.0. Type help or ? to list commands.

Using management server profile: local 

(local) >
```
After running this, you should see that Cloudmonkey has started successfully and that it's ready to accept API calls.All of the VDC API commands that can be accepted by Cloudmonkey can be found in the [API Command Reference](http://cloudstore.interoute.com/main/knowledge-centre/library/api-command-reference).

## Deploy a CoreOS node

The following API call from Cloudmonkey is used to deploy a new virtual machine in VDC running CoreOS:

```cloudmonkey
deployVirtualMachine serviceofferingid=85228261-fc66-4092-8e54-917d1702979d zoneid=f6b0d029-8e53-413b-99f3-e0a2a543ee1d templateid=73bc5066-b536-4325-8e27-ec873cea6ce7 networkids=e9e1220b-76c8-47cd-a6c2-885ffee49972 keypair=CoreOS-Key01 name=DockerTutorialVM01
```
As you can see above 6 parameter values were provided above. 

### Service Offering

The first parameter is the 'service offering id' which represents the amount of memory and number of CPUs that you want to allocate to the VM.I have decided to use the service offering with 4 Gigabytes of RAM and 2 CPU cores.

```cloudmonkey
> listServiceOfferings name=4096-2 filter=id
```
The name parameter above denotes how much RAM (in Mbytes) and CPU cores you want to have. You should see an output like the following:

```cloudmonkey
+--------------------------------------+
|                  id                  |
+--------------------------------------+
| 85228261-fc66-4092-8e54-917d1702979d |
+--------------------------------------+
```

### Zone

The "zoneid" parameter specifies the zone (data centre of VDC) of the VM to be deployed. I can view the list of the available zones by typing:

```cloudmonkey
> listZones filter=id,name
```
You should get the following result, if you are working in the Europe region of VDC.Note that the UUID values required for most of the input parameters will be different from the ones shown here.): 

```cloudmonkey
+--------------------------------------+-------------------+
|                  id                  |        name       |
+--------------------------------------+-------------------+
| 374b937d-2051-4440-b02c-a314dd9cb27e |    Paris (ESX)    |
| 58848a37-db49-4518-946a-88911db0ee2b |    Milan (ESX)    |
| fc129b38-d490-4cd9-acf8-838cf7eb168d |    Berlin (ESX)   |
| 3c43b32b-fadf-4629-b8e9-61fb7a5b9bb8 | Amsterdam 2 (ESX) |
| f6b0d029-8e53-413b-99f3-e0a2a543ee1d |   London 2 (ESX)  |
| 5343ddc2-919f-4d1b-a8e6-59f91d901f8e |    Slough (ESX)   |
| 1ef96ec0-9e51-4502-9a81-045bc37ecc0a |   Geneva 2 (ESX)  |
| ddf450f2-51b2-433d-8dea-c871be6de38d |    Madrid (ESX)   |
| 7144b207-e97e-4e4a-b15d-64a30711e0e7 |  Frankfurt (ESX)  |
+--------------------------------------+-------------------+
```

### Template

The "templateid" parameter specifies the operating system that I want the VM to run. I am going to choose the templateid of CoreOS, which is named 'IRT-COREOS' in VDC. Here is how to find out the required UUID:

```cloudmonkey
> listTemplates templatefilter=featured zoneid=f6b0d029-8e53-413b-99f3-e0a2a543ee1d name=IRT-COREOS filter=id,name
```  

Note this is the 'CoreOS stable' version, there is another template for 'CoreOS alpha'.

### Network

The "networkids" parameter specifies the network or networks that the deployed VM will be using.As I chose the VM to be located in London then the chosen network(s) should also be located in London. Type the following to show your networks in the London zone:

```cloudmonkey
> listNetworks zoneid=f6b0d029-8e53-413b-99f3-e0a2a543ee1d filter=id,name
``` 

This is the output for my VDC account:

```cloudmonkey
+--------------------------------------+--------------------+
|                  id                  |        name        |
+--------------------------------------+--------------------+
| e9e1220b-76c8-47cd-a6c2-885ffee49972 |   PrvWithGW Lon2   |
| 182e8be5-6f73-4a31-a9f9-b6f445a46b53 |    IPVPN_LON02     |
+--------------------------------------+--------------------+
```

As you can see above, I have two networks in the London zone. I want my deployed VM to be connected to only one network, so I choose networkids to be 'e9e1220b-76c8-47cd-a6c2-885ffee49972'. (If I wanted two or more networks, I would make a list using commas to separate, such as: 'networkids=e9e1220b-76c8-47cd-a6c2-885ffee49972,182e8be5-6f73-4a31-a9f9-b6f445a46b53'.)

### SSH Keys

The "keypair" parameter specifies the SSH keypair used to login to the CoreOS as the CoreOS template does not allow for any logins (root user or otherwise) using passwords.

First of all, I am going to create a new keypair on my own machine using the OpenSSH command line tool, ssh-keygen:

```cmd
$ cd ~/.ssh && ssh-keygen -t rsa -f id_rsa_coreos          #(for Linux)
cd C:/ && ssh-keygen -t rsa -f id_rsa_coreos 		   #(for Windows)
``` 
The next step is to 'register' your keypair, which means storing your public key in VDC, so that VMs can boot with that information:


```cloudmonkey
> registerSSHKeyPair name=CoreOS-Key01 publickey="ssh-rsa AAAAB3NzaC1y...........fyskMb4oBw== PapanCostas@interoute.com"
keypair:
name = CoreOS-Key01
fingerprint = 55:33:b4:d3:b6:52:fb:79:97:fc:e8:16:58:6e:42:ce
```

The "name" parameter is arbitrary and is used for your reference only.

### Name

The final "name" parameter is the name of the VM. You can choose any name that is unique and is not used by any existing VM on your VDC account. I will choose the name 'DockerTutorialVM01'.

I am going to make sure that Cloudmonkey is set to the mode of waiting for deployment to complete (known as 'asynchronous blocking'), otherwise the VM information will not be output to the terminal:

```cloudmonkey
> set asyncblock true
```

## Connecting to CoreOS

To be able to SSH to the VM a port forwarding rule is required to allow connection on port 22:

```cloudmonkey
> createPortForwardingRule protocol=TCP publicport=22 ipaddressid=value1 virtualmachineid=value2 privateport=22 openfirewall=true
```
The last configuration step is to set an egress firewall rule for the network so that the CoreOS VM will be able to get outward access to the internet. This is needed for Docker to access repositories for container images, and to allow CoreOS to access internet update servers to do automatic updating:


```cloudmonkey
> createEgressFirewallRule networkid=e9e1220b-76c8-47cd-a6c2-885ffee49972 protocol=all cidr=0.0.0.0/0
```

Note that allowing traffic from any iP is not a good practice.

So finally my VM is set up for me to connect to it, using the 'ipaddress' found from the listPublicIpAddresses command and specifying the private SSH key file to match the public key which I registered in VDC. Type this ssh command into a terminal:


```cmd
$ ssh -i ~/.ssh/id_rsa_coreos core@IPADDRESS
```

Upon the first connection to the VM I am asked to check authenticity of the VM:

```cmd  
The authenticity of host '[IPADDRESS]:22 ([IPADDRESS]:22)' can't be established.
ED25519 key fingerprint is 4a:f4:85:c0:1d:e0:fa:26:94:89:7c:39:1b:57:42:d2.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[IPADDRESS]:22' (ED25519) to the list of known hosts.
CoreOS (stable)
core@DockerTutorialVM01 ~ $
```
## Using CoreOS

Check out the [CoreOS and Docker in Interoute VDC](http://cloudstore.interoute.com/main/knowledge-centre/blog/coreos-docker-vdc-part2) turorial for using Docker.

