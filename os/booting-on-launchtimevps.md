# Running CoreOS on RimuHosting's LaunchtimeVPS service

RimuHosting's LaunchtimeVPS service provides hosted virtual machines.  RimuHosting provide CoreOS as one of their standard images.  Customers can launch these VMs via the web interface or via the RimuHosting server management API.

## About the RimuHosting CoreOS setup

RimuHosting automatically creates the systemd networking files (no need to put networking setup in the cloud init block).

The CoreOS image RimuHosting provide is from the stable channel (updating versions from time to time).

RimuHosting use the CoreOS PXE kernel and initrd (stored on your VM at `/boot`).  We boot up the VM via pv-grub (so the kernel used is provided by CoreOS, not the Xen-based VM host).

### Public SSH keys
The standard CoreOS image uses the core user (instead of root) and doesn't use a password for authentication. You'll need to add an SSH key(s) via the web interface or add keys/passwords via your cloud-config in order to log in.

Ensure you have set your [SSH public keys][rh-ssh-keys-page].  If you do not have a RimuHosting account, use the register link.

RimuHosting will inject these keys into your instance on setup (no need to modify your cloud-config).

RimuHosting will set the RimuHosting SSH key on the core and root user as well as adding your own SSH keys.  You can override this if you do not wish us to have access via the cloud init users ssh-authorized-keys setting or the write_files setting.

### Gotchas

The cloud init file is placed at `/var/lib/coreos-install/user_data`.  It runs on each server start.  If you do not wish the actions to be repeated at each server start, remove the file as part of the cloud init process.

### Cloud-Config

You provide raw cloud-config data to CoreOS as part of the RimuHosting web
interface install process or via the [RimuHosting API][rh-api-docs] command line install method.

The `$private_ipv4` and `$public_ipv4` substitution variables are fully
supported in cloud-config on RimuHosting. In order for `$private_ipv4` to be
populated, the VM must have private networking enabled.

## Launching VMs

### Via the web interface

1.  Ensure you have set your [SSH public keys][rh-ssh-keys-page].  If you do not have a RimuHosting account, use the register link.
2. Configure a [new VM][rh-variable-plan-page] (including memory, disk size and data center.  Start the order.
2. In the Software installs section select the CoreOS image (currently only the stable channel is provided).  Tab away from that field to reveal the cloud config input field.  Then provide your cloud config.<br/><br/>
<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12 co-m-screenshot">
    <a href="rimuhosting-coreos-image-select-cloud-config.png">
      <img src="img/rimuhosting-coreos-image-select-cloud-config.png" />
    </a>
    <div class="co-m-screenshot-caption">Choosing the CoreOS image and providing a cloud config.</div>
  </div>
</div>
4.  Start the install.  The server will be setup and you will be notified when that is complete.

A VM can be reinstalled (with a fresh/clean CoreOS image and different cloud-config) via the [reinstall interface][rh-reinstall-page].

### Via the API

Set your public [SSH keys][rh-ssh-keys-page].

Git clone the [Python driver for the RimuHosting API][rh-python-driver-api]
```sh
git clone git@github.com:pbkwee/RimuHostingAPI.git
```

Install the library:
```
python3 setup.py build install
```

If you do not already have a server with us, you will need to email RimuHosting and ask them to enable automated server setups on your account.

Get a [server management API key][rh-api-keys-page]

Set the API key as an environment variable:

```sh
export RIMUHOSTING_APIKEY=00000000123456789
```

Or set the key in a `.rimuhosting` config file:
```sh
echo "export RIMUHOSTING_APIKEY=00000000123456789" >> ~/.rimuhosting
```

Edit the server spec you wish to create at `sample-configs/unmodified/servers/server.json` e.g. 

```json
{
  "vps_parameters": {
    "disk_space_mb": "8192",
    "memory_mb": "4096"
  },
  "instantiation_options": {
    "distro": "coreos.64",
    "domain_name": "coreos-master.example.com"
  }
}
```


Edit the cloud config data you wish to use at `sample-configs/defaults/cloud-init/master.yaml`.

Create the CoreOS VM:

```sh
$ python3 mkvm.py --server_json sample-configs/unmodified/servers/server.json \
--cloud_config sample-configs/defaults/cloud-init/master.yaml
```

For more details, check out [RimuHosting's API documentation][rh-api-docs].

### Adding more machines
To add more instances to the cluster, just launch more with the same
cloud-config. New instances will join the cluster regardless of VM location.

## SSH to your VM
To connect to a VM after it's created (takes a couple of minutes), run:

```sh
ssh core@<ip address>
```

Optionally, you may want to [configure your ssh-agent]({{site.baseurl}}/docs/launching-containers/launching/fleet-using-the-client/#remote-fleet-access) to more easily run [fleet commands]({{site.baseurl}}/docs/launching-containers/launching/launching-containers-fleet/).

## Using CoreOS

Now that you have a cluster bootstrapped it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).

[rh-api-docs]: http://apidocs.rimuhosting.com/jaxrsdocs/index.html
[rh-ssh-keys-page]: https://launchtimevps.com/cp/sshkeys.jsp
[rh-variable-plan-page]: https://launchtimevps.com/#variable_plan
[rh-reinstall-page]: https://rimuhosting.com/cp/vps/disk/install.jsp
[rh-api-keys-page]: https://rimuhosting.com/cp/apikeys.jsp
[rh-python-driver-api]: https://github.com/pbkwee/RimuHostingAPI  
