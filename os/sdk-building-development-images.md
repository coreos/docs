# Building development images

## Updating packages on an image

Building a new VM image is a time consuming process. On development images you can use `gmerge` to build packages on your workstation and ship them to your target VM.

On your workstation start the dev server inside the SDK chroot:

```sh
start_devserver --port 8080
```

NOTE: This port will need to be Internet accessible if your VM is remote.

Run `gmerge` from your VM and ensure that the `DEVSERVER` setting in `/etc/coreos/update.conf` points to your workstation IP/hostname and port.

```sh
gmerge coreos-base/update_engine
```

### Updating an image with update engine

If you want to test that an image you built can successfully upgrade a running VM you can use devserver. To specify the version to upgrade to you can use the `--image` argument. This should be a newer build than the VM is currently running, otherwise devserver will answer "no update" to any requests. Here is an example using the default value:

```sh
start_devserver --image ../build/images/amd64-usr/latest/coreos_developer_image.bin
```

On the target VM ensure that the `SERVER` setting in `/etc/coreos/update.conf` points to your workstation, for example:

```sh
GROUP=developer
SERVER=http://you.example.com:8080/update
DEVSERVER=http://you.example.com:8080
```

If you modify this file restart update engine: `systemctl restart update-engine`

On the VM force an immediate update check:

```sh
update_engine_client -update
```

If the update fails you can check the logs of the update engine by running:

```sh
journalctl -u update-engine -o cat
```

If you want to download another update you may need to clear the reboot pending status:

```sh
update_engine_client -reset_status
```

## Updating portage-stable ebuilds from Gentoo

There is a utility script called `update_ebuilds` that can pull from Gentoo's git tree directly into your local portage-stable tree. Here is an example usage bumping go to the latest version:

```sh
./update_ebuilds --commit dev-lang/go
```

To create a Pull Request after the bump run:

```sh
cd ~/trunk/src/third_party/portage-stable
git checkout -b 'bump-go'
git push <your remote> bump-go
```

## Tips and Tricks

We've compiled a [list of tips and tricks](sdk-tips-and-tricks.md) that can make working with the SDK a bit easier.

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/sdk-building-development-images.md?pixel)]() <!-- END ANALYTICS -->