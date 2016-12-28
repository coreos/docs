# Running CoreOS Container Linux on Ikoula Cloud

[Ikoula](https://www.ikoula.com) is a French cloud hosting company. Its CloudStack 4.5 based cloud is deployed on its own datacenters worldwide on several Basic and Advanced networking zones. Currently zones are available on France, Germany, Netherlands, USA East, Singapore.

### Networking zones on Ikoula Cloud

On Basic networking zones, you have the support of security groups and a directly assigned public IP address as in many other cloud providers.

On Advanced networking zones, you have a virtual router deployed which protects your own private VLAN network. Instances deployed on this private VLAN receive a private IP address from a range you can choose, and they have external access through the virtual router. On Advanced networking zones, you have access to VPC which can be connected to your own office network by means of using site-to-site VPNs.

### CoreOS Container Linux images on Ikoula Cloud

You can deploy and boot officially-built Container Linux images on Ikoula Cloud!

You will need:

- a valid account
- a valid cloud public subscription

Please note that images deployed on Ikoula Cloud update themselves automatically. The reboot strategy is "best effort", which means that if the deployed Container Linux is standalone then it will reboot automatically. You can, however, [disable this behaviour][reboot-after-update]. We also provide a FAQ on how to [achieve][coreos-update-manually] this.

[reboot-after-update]: update-strategies.md
[coreos-update-manually]: https://ikoula.wiki/help/Mettre_a_jour_CoreOS_manuellement/fr

### Creating your account and subscribing to Ikoula Cloud

Go make them both at [Public Cloud Ikoula](https://express.ikoula.com/en/public-cloud). Choose any type of virtual machine and then proceed to create your account and subscription.

You will soon receive access to your own [Extranet](https://extranet.ikoula.com).

### Deploying instances using Extranet portal a.k.a "one click deployment" on basic zones

Open your browser and point it to [https://extranet.Ikoula.com](https://extranet.ikoula.com). If needed, change the language by using flag icons on the right near "Choose your language".

Click on "Click here" to connect.

To login fill in your credentials (email address and password of your account):
<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12">
    <br/>
    <img src="img/ikoula-login.png" class="screenshot" />
    <div align="center" class="caption">Login to Extranet Ikoula Portal</div>
    <br/>
    <br/>
  </div>
</div>

Then click on public cloud:

<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12">
    <br/>
    <img src="img/ikoula-public-cloud.png" class="screenshot" />
    <div align="center" class="caption">Link to public cloud subscriptions on Extranet Ikoula Portal</div>
    <br/>
    <br/>
  </div>
</div>

Your public cloud subscription appear:

<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12">
    <br/>
    <img src="img/ikoula-subscriptions.png" class="screenshot" />
    <div align="center" class="caption">Cloud subscriptions on Extranet Ikoula portal</div>
    <br/>
    <br/>
  </div>
</div>

If you click on it, you'll have access to a menu that quickly permits you to deploy and configure an instance of Container Linux on a Basic networking zone of your choice:

<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12">
    <br/>
    <img src="img/ikoula-deploy-instance-menu.png" class="screenshot" />
    <div align="center" class="caption">The "One Click deployment" on Extranet Ikoula portal</div>
    <br/>
    <br/>
  </div>
</div>

To create your instance:

1. Fill The VM Name.
2. Choose "CoreOS Stable 64bits SSH KEYPAIR with core user" on Template section.
3. Choose your service offering, that will represent the power of your instance, the resources that it will get.
4. Choose the incoming firewall rules that will be accepted (we recommend to open at least SSH, by default all ports are closed).
5. Choose the authentication type. On Container Linux this is a sshkeypair, choose to create on, or use an already existent one.
6. Choose the Basic zone in which you will want your instance to be deployed.

Click on CREATE MY INSTANCE, then, thanks to SSD-backed Ikoula Cloud hosts, you will rapidly get information about your instance:

<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12">
    <br/>
    <img src="img/ikoula-instance-deployed.png" class="screenshot" />
    <div align="center" class="caption">Instance Container Linux deployed on Extranet Ikoula portal</div>
    <br/>
    <br/>
  </div>
</div>

Finally with the IP address the sshkey, and the firewall rule, you will be able to connect to your instance.

### Deploying instances using CloudMonkey on either basic or advanced networking zones

The Ikoula Cloud offers a template "CoreOS Stable" which is available on every all of the different geographic zones (France, USA East, Singapore, Germany, Netherlands).

Consistent with the normal use of Container Linux, the SSH connection to an instance deployed with this template is only possible with the user “core” and through SSH key authentication. You can then rely on official FAQs Container Linux without encountering unexpected behavior.

In the following procedure, we will use the tool Apache CloudMonkey to deploy a Container Linux instance. To be able to use CloudMonkey, you must have valid API and secret keys. You have received them both on subscription to Ikoula Cloud service. If you don't have them, please follow this [FAQ](https://ikoula.wiki/help/Utiliser_le_moteur_API_du_cloud_public_ikoula)
to generate them.

## Prepare CloudMonkey environment

Install CloudMonkey by issuing (Debian based Linux only) these commands:

```sh
sudo apt-get install python-pip
pip install cloudmonkey
```

Configure CloudMonkey by issuing these commands, replacing API and secret keys with your own:

```sh
$ cloudmonkey
Apache CloudStack CloudMonkey 5.0.0. Type help or ? to list commands.

> set host cloudStack.ikoula.com
> set path /client/api
> set protocol https
> set port 443
> set apikey <API KEY>
> set secretkey <SECRET KEY>
```
## Generate your keys

Create your CloudStack SSH key pair:

```sh
$ cloudmonkey
Apache CloudStack CloudMonkey 5.0.0. Type help or ? to list commands.

> create sshkeypair name=MySSHkey
keypair:
name = MySSHkey
fingerprint = 15:51:8a:8e:04:d3:78:5e:dd:5c:7f:50:f8:e8:81:89
privatekey = -----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC+aaZOBbsJxSfrUrgIB29gncJeZ5leAH+b4d1+ARRPZgiYM50K
b0X6FUBk+qDKTjsqQHZuYiyXbpt/JXq1WUukaY6Xv0L13ydLcOUpxekXxHeELNg/
QXyP+gKzr6rGgGZwFSwJoZGmi3U9QM661/pKzfie6cOxyZ7zHNhdMZqW5QIDAQAB
AoGBAI8/vDWGaif3gwiuunSP42K0TL3pAqCNj3MegRuChF0XTe/zJHntLJ/vzPoq
8zw/jpNC29Y/VXy3YZROBfrYquY/KjnfbaQWEBXNNYjBXJcL00MCVOhQTqHxQoJo
HVsA+1zriXpAA1a7hBw/GzTbhB/tC7w2V2eYTfIF4exdL10hAkEA+bjspo7KAzwF
ysVoRZfGWdGl4cDC4zR290URXplVJJ3t2MZKD0zW04ajNOLMG5ve5fwGbTYfhJ3/
CICQ41WTewJBAMMzCnWrOOyjJEQo3QFZX9QEtMSCJGeiGW04u/lB8XiT5AXIdGEk
QIAsSYdgQrDw02nQ7rWGUBnGdJ7PlSXKwR8CQQCwpISRlLOE8jJOqrEFeUTPSCME
u6uft/7nDi4pMmEt06DpE+pTRFE5syVDRaKHbQyQtmN9YSmOT4yVYQwcIu5[...]
-----END RSA PRIVATE KEY-----
```

Paste this SSH key pair in a restricted file (MySSHkey in our example) with permissions to owner read only (400):

```sh
$ cat MySSHkey
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC+aaZOBbsJxSfrUrgIB29gncJeZ5leAH+b4d1+ARRPZgiYM50K
b0X6FUBk+qDKTjsqQHZuYiyXbpt/JXq1WUukaY6Xv0L13ydLcOUpxekXxHeELNg/
QXyP+gKzr6rGgGZwFSwJoZGmi3U9QM661/pKzfie6cOxyZ7zHNhdMZqW5QIDAQAB
AoGBAI8/vDWGaif3gwiuunSP42K0TL3pAqCNj3MegRuChF0XTe/zJHntLJ/vzPoq
8zw/jpNC29Y/VXy3YZROBfrYquY/KjnfbaQWEBXNNYjBXJcL00MCVOhQTqHxQoJo
HVsA+1zriXpAA1a7hBw/GzTbhB/tC7w2V2eYTfIF4exdL10hAkEA+bjspo7KAzwF
ysVoRZfGWdGl4cDC4zR290URXplVJJ3t2MZKD0zW04ajNOLMG5ve5fwGbTYfhJ3/
CICQ41WTewJBAMMzCnWrOOyjJEQo3QFZX9QEtMSCJGeiGW04u/lB8XiT5AXIdGEk
QIAsSYdgQrDw02nQ7rWGUBnGdJ7PlSXKwR8CQQCwpISRlLOE8jJOqrEFeUTPSCME
u6uft/7nDi4pMmEt06DpE+pTRFE5syVDRaKHbQyQtmN9YSmOT4yVYQwcIu [...]
-----END RSA PRIVATE KEY-----

$ chmod 400 MySSHkey
```

## Deploy CoreOS Container Linux on an advanced zone

### Deploy your CoreOS Container Linux instance with your SSH key pair

This example is made in Advanced networking zone, so we assume that you have already created your VPC or network:

```sh
$ cloudmonkey
Apache CloudStack CloudMonkey 5.0.0. Type help or ? to list commands.

> deploy virtualmachine zoneid=<Zone ID> networkids=<Network ID> serviceofferingid=<Serviceoffering ID> templateid=<Template ID> name=<Instance Name> displayname=<Instance Name to display> keypair=MySSHkey
```

You need to adapt the "<>" fields. Hint: To get correct IDs, either use tab completion when issuing the command or use API commands to get them.

### Configure a NAT rule (we consider that you have already created a firewall rule that allows you to connect to the SSH TCP/22 port)

```sh
$ cloudmonkey
Apache CloudStack CloudMonkey 5.0.0. Type help or ? to list commands.

> create portforwardingrule virtualmachineid=<ID of the deployed Container Linux instance above> networkid=<Network ID> ipaddressid=<Public address IP of your network> privateport=22 publicport=<port publique> protocol=tcp
```

You need to adapt the "<>" fields. After launching this command, you will receive the IP address information.

### Connect to your CoreOS Container Linux instance through SSH

```sh
$ ssh -i MySSHkey core@178.170.X.X
CoreOS stable (723.3.0)
core@coreos557x64 ~ $"
```

## Deploy CoreOS Container Linux on a basic zone

Deploying on a Basic networking zone is somewhat similar, but you don't need to create NAT rule, just configure correctly the security group.

```sh
$ CloudMonkey
Apache CloudStack CloudMonkey 5.0.0. Type help or ? to list commands.

> deploy virtualmachine zoneid=<Zone ID> templateid=<Container Linux Template ID of this zone> serviceofferingid=<Serviceoffering ID> securitygroupids=<ID of your security group> keypair=MySSHkey name=<Instance Name>
```

# Going further with CoreOS Container Linux on Ikoula Cloud

Now that you have successfully deployed a Container Linux instance, you should consult the [quickstart on Container Linux][quickstart] and [plan a cluster][cluster-configure]!

[quickstart]: quickstart.md
[cluster-configure]: cluster-discovery.md
