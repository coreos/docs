---
layout: docs
slug: sdk
title: Documentation
---

# CoreOS Developer SDK Guide

These are the instructions for building CoreOS itself. By the end of
the guide you will build a developer image that you can run under
KVM and have tools for making changes to the code.

CoreOS is an open source project. All of the source for CoreOS is
available on [github][github-coreos]. If you find issues with these docs
or the code please send a pull request.

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

[github-coreos]: https://github.com/coreos/
[irc]: irc://irc.freenode.org:6667/#coreos
[coreos-dev]: https://groups.google.com/forum/#!forum/coreos-dev

## Getting Started

Let's get set up with an SDK chroot and build a bootable image of CoreOS. The
SDK chroot has a full toolchain and isolates the build process from quirks and
differences between host OSes.

### Install depot_tools

`repo`, one of the `depot_tools`, helps to manage the collection of git
repositories that makes up CoreOS. Pull down the code and add it to your
path:

```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH":`pwd`/depot_tools
```

You may want to add this to your .bashrc or /etc/profile.d/ so that you don’t
need to reset your $PATH manually each time you open a new shell.

### Bootstrap the SDK chroot

Create a project directory. This will hold all of your git repos and the SDK
chroot. A few gigs of space will be necessary.

```
mkdir coreos; cd coreos
```

Initialize the .repo directory with the manifest that describes all of the git
repos required to get started.

```
repo init -u https://github.com/coreos/manifest.git -g minilayout --repo-url  https://git.chromium.org/git/external/repo.git
```

Synchronize all of the required git repos from the manifest.

```
repo sync
```

### Building an image

Download and enter the SDK chroot which contains all of the compilers and
tooling.

```
./chromite/bin/cros_sdk
```

**WARNING:** If you ever need to delete the SDK chroot use
`./chromite/bin/cros_sdk --delete`. Otherwise, you will delete `/dev`
entries that are bind mounted into the chroot.

Set up the "core" user's password.

```
./set_shared_user_password.sh
```

Target amd64-generic for this image:

```
echo amd64-generic > .default_board
```

Setup a board root filesystem in /build/${BOARD}:

```
./setup_board
```

Build all of the target binary packages:

```
./build_packages
```

Build an image based on the built binary packages along with the developer
overlay:

```
./build_image --noenable_rootfs_verification dev
```

After this finishes up commands for converting the raw bin into
a bootable vm will be printed. Run the `image_to_vm.sh` command.

### Booting

Once you build an image you can launch it with KVM (instructions will
print out after `image_to_vm.sh` runs).

To demo the general direction we are starting in now the OS starts two
small daemons that you can access over an HTTP interface. The first,
systemd-rest, allows you to stop and start units via HTTP. The other is a
small server that you can play with shutting off and on called
motd-http. You can try these daemons with:

```
curl http://127.0.0.1:8000
curl http://127.0.0.1:8080/units/motd-http.service/stop/replace
curl http://127.0.0.1:8000
curl http://127.0.0.1:8080/units/motd-http.service/start/replace
```

## Making Changes

### git and repo

CoreOS is managed by `repo`. It was built for the Android project and makes
managing a large number of git repos easier, from the announcement blog:

> The repo tool uses an XML-based manifest file describing where the upstream
> repositories are, and how to merge them into a single working checkout. repo
> will recurse across all the git subtrees and handle uploads, pulls, and other
> needed items. repo has built-in knowledge of topic branches and makes working
> with them an essential part of the workflow.
> -- via the [Google Open Source Blog][repo-blog]

[repo-blog]: http://google-opensource.blogspot.com/2008/11/gerrit-and-repo-android-source.html

You can find the full manual for repo by visiting [Version Control with Repo and Git][vc-repo-git].

[vc-repo-git]: http://source.android.com/source/version-control.html

### Updating repo manifests

The repo manifest for CoreOS lives in a git repository in
`.repo/manifests`. If you need to update the manifest edit `default.xml`
in this directory.

`repo` uses a branch called 'default' to track the upstream branch you
specify in `repo init`, this defaults to 'origin/master'. Keep this in
mind when making changes, the origin git repository should not have a
'default' branch.

## Development Workflows

### Updating Packages on an Image

Building a new VM image is time consuming process. On development images you
can use `gmerge` to build packages on your workstation and ship them to your
target VM.

1. On your workstation start the dev server inside the SDK chroot:

```
start_devserver --port 8080
```

NOTE: This port will need to be internet accessible.

2. Run /usr/local/bin/gmerge from your VM and ensure that the settings in
   `/etc/lsb-release` point to your workstation IP/hostname and port

```
/usr/local/bin/gmerge coreos-base/update_engine
```

### Updating an Image with Update Engine

If you want to test that an image you built can successfully upgrade a running
VM you can use the `--image` argument to the devserver. Here is an example:

```
start_devserver --image ../build/images/amd64-generic/latest/chromiumos_image.bin
```

From the target virtual machine you run:

```
update_engine_client -update -omaha_url http://$WORKSTATION_HOSTNAME:8080/update
```

If the update fails you can check the logs of the update engine by running:

```
journalctl -u update-engine -o cat
```

If you want to download another update you may need to clear the reboot
pending status:

```
update_engine_client -reset_status
```

### Updating portage-stable ebuilds from Gentoo

There is a utility script called `update_ebuilds` that can pull from Gentoo's
CVS tree directly into your local portage-stable tree. Here is an example usage
bumping go to the latest version:

```
./update_ebuilds --commit dev-lang/go
```

To create a Pull Request after the bump run:

```
cd ~/trunk/src/third_party/portage-stable
git checkout -b 'bump-go'
git push <your remote> bump-go
```

## Production Workflows

### Building a Production Image

This will build an image that can be ran under KVM and uses near production
values.

Note: Add `COREOS_OFFICIAL=1` here if you are making a real release. That will
change the version and enable uploads by default.

```
./build_image prod
```

The generated production image is bootable as-is by qemu but for a
larger STATE partition or VMware images use `image_to_vm.sh` as
described in the final output of `build_image1`.

### Pushing updates to the dev-channel

#### Manual Builds

To push an update to the dev channel track on api.core-os.net build a
production images as described above and then use the following tool:

```
COREOS_OFFICIAL=1 ./core_upload_update <required flags> --track dev-channel --image ../build/images/amd64-generic/latest/coreos_production_image.bin
```

#### Automated builds

The automated build host does not have access to production signing keys
so the final signing and push to api.core-os.net must be done elsewhere.
The `au-generator.zip` archive provides the tools required to do this so
a full SDK setup is not required. This does require gsutil to be
installed and configured.

```
URL=gs://storage.core-os.net/coreos/amd64-generic/0000.0.0
cd $(mktemp -d)
gsutil cp $URL/au-generator.zip $URL/coreos_production_image.bin.bz2 ./
unzip au-generator.zip
bunzip2 coreos_production_image.bin.bz2
COREOS_OFFICIAL=1 ./core_upload_update <required flags> --track dev-channel --image coreos_production_image.bin
```

## Tips and Tricks

### Finding all open pull requests and issues

- [CoreOS Issues][issues]
- [CoreOS Pull Requests][pullrequests]

[issues]: https://github.com/organizations/coreos/dashboard/issues/
[pullrequests]: https://github.com/organizations/coreos/dashboard/pulls/

### Searching all repo code

Using `repo forall` you can search across all of the git repos at once:

```
repo forall -c  git grep 'CONFIG_EXTRA_FIRMWARE_DIR'
```

### Caching git https passwords

Note: You need git 1.7.10 or newer to use the credential helper

Turn on the credential helper and git will save your password in memory
for some time:

```
git config --global credential.helper cache
```

Why doesn't CoreOS use SSH in the git remotes? Because, we can't do
anonymous clones from github with a ssh URL. In the future we will fix
this.

### Base system dependency graph

Get a view into what the base system will contain and why it will contain those
things with the emerge tree view:

```
emerge-amd64-generic  --emptytree  -p -v --tree  coreos-base/coreos-dev
```

### SSH Config

You will be booting lots of VMs with on the fly ssh key generation. Add
this in your `$HOME/.ssh/config` to stop the annoying fingerprint warnings.

```
Host 127.0.0.1
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  User core
  LogLevel QUIET
```

### Hide loop devices from desktop environments

By default desktop environments will diligently display any mounted devices
including loop devices used to contruct CoreOS disk images. If the daemon
responsible for this happens to be ``udisks`` then you can disable this
behavior with the following udev rule:

```
echo 'SUBSYSTEM=="block", KERNEL=="ram*|loop*", ENV{UDISKS_PRESENTATION_HIDE}="1", ENV{UDISKS_PRESENTATION_NOPOLICY}="1"' > /etc/udev/rules.d/85-hide-loop.rules
udevadm control --reload
```

### Leaving developer mode

Some daemons act differently in "dev mode". For example update_engine refuses
to auto-update or connect to HTTPS URLs. If you need to test something out of
dev_mode on a vm you can do the following:

```
mv /root/.dev_mode{,.old}
```

If you want to permanently leave you can run the following:

```
crossystem disable_dev_request=1; reboot
```

## Known Issues

### build\_packages fails on coreos-base

Sometimes coreos-dev or coreos builds will fail in `build_packages` with a
backtrace pointing to `epoll`. This hasn't been tracked down but running
`build_packages` again should fix it. The error looks something like this:

```
Packages failed:
coreos-base/coreos-dev-0.1.0-r63
coreos-base/coreos-0.0.1-r187
```

## Constants and IDs

### CoreOS App ID

This UUID is used to identify CoreOS to the update service and elsewhere.

```
e96281a6-d1af-4bde-9a0a-97b76e56dc57
```

### GPT UUID Types

- CoreOS Root: 5dfbf5f4-2848-4bac-aa5e-0d9a20b745a6
- CoreOS Reserved: c95dc21a-df0e-4340-8d7b-26cbfa9a03e0
