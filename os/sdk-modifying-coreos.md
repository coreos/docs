# CoreOS Developer SDK Guide

These are the instructions for building CoreOS itself. By the end of the guide you will build a developer image that you can run under KVM and have tools for making changes to the code.

CoreOS is an open source project. All of the source for CoreOS is available on [github][github-coreos]. If you find issues with these docs or the code please send a pull request.

Direct questions and suggestions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Getting started

Let's get set up with an SDK chroot and build a bootable image of CoreOS. The SDK chroot has a full toolchain and isolates the build process from quirks and differences between host OSes. The SDK must be run on an x86-64 Linux machine, the distro should not matter (Ubuntu, Fedora, etc).

### Prerequisites

System requirements to get started:

* curl
* git
* python2

You also need a proper git setup:

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

**NOTE**: Do the git configuration as a normal user and not with sudo.

### Install repo

The `repo` utility helps to manage the collection of git repositories that makes up CoreOS. Download repo and add it to `$PATH`:

```sh
mkdir ~/bin
export PATH="$PATH:$HOME/bin"
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

You may want to add this to `.bashrc` or `/etc/profile.d/` so that you don’t need to reset `$PATH` in every new shell.

### Bootstrap the SDK chroot

Create a project directory. This will hold all of your git repos and the SDK chroot. A few gigabytes of space will be necessary.

```sh
mkdir coreos; cd coreos
```

Initialize the .repo directory with the manifest that describes all of the git repos required to get started.

```sh
repo init -u https://github.com/coreos/manifest.git
```

Synchronize all of the required git repos from the manifest.

```sh
repo sync
```

### Using QEMU for cross-compiling

The CoreOS initramfs is generated with the `dracut` tool. `Dracut` assumes it is running on the target system, and produces output only for that CPU architecture. In order to create initramfs files for other architectures, `dracut` is executed under QEMU's user mode emulation of the target CPU.

#### Configuring QEMU for 64 bit ARM binaries

On systemd systems, a configuration file controls how binaries for a given architecture are handled. To register QEMU as the runtime for 64 bit ARM binaries, write the following to `/etc/binfmt.d/qemu-aarch64.conf`:

```
:qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-aarch64-static:
```

Then run:

```sh
systemctl restart systemd-binfmt.service
```

The qemu binary, `/usr/bin/qemu-aarch64-static` is not expected to be on the host workstation. It will be inside the `arm64-usr` build chroot entered before running `dracut`.

Note that "64 bit ARM" is known by two short forms: `aarch64` (as seen in the configuration file for QEMU), and `arm64` (as seen in how CoreOS and many other distributions refer to the architecture).

### Building an image

Download and enter the SDK chroot which contains all of the compilers and tooling.

```sh
./chromite/bin/cros_sdk
```

**WARNING:** To delete the SDK chroot, use `./chromite/bin/cros_sdk --delete`. Otherwise, you will delete `/dev` entries that are `bind`-mounted into the chroot.

Set up user `core`'s password:

```sh
./set_shared_user_password.sh
```

#### Selecting the architecture to build

##### 64 bit AMD: The `amd64-usr` target

The `--board` option can be set to one of a few known target architectures, or system "boards", to build for a given CPU.

To create a root filesystem for the `amd64-usr` target beneath the directory `/build/amd64-usr/`:

```sh
./setup_board --default --board=amd64-usr
```

##### 64 bit ARM: The `arm64-usr` target

Similarly, use `arm64-usr` for the cross-compiled ARM target. If switching between different targets in a single SDK, you can add the `--board=` option to the subsequent `build_packages`, `build_image`, and other similar commands to select the given target architecture and path.

```sh
./setup_board --default --board=arm64-usr
```

#### Compile and link system binaries

Build all of the target binary packages:

```sh
./build_packages
```

#### Building GRUB for `arm64`

For the 64 bit ARM architecture, an extra step is required before building `arm64-usr` images. We need to build GRUB for `arm64` but this isn't handled automatically yet. Write the following to `/etc/portage/package.use/grub`:

```
sys-boot/grub grub_platforms_arm64
```

Then run:

```sh
sudo emerge -v grub
```

#### Render the CoreOS image

Build an image based on the binary packages built above, including development tools:

```sh
./build_image dev
```

After `build_image` completes, it prints commands for converting the raw bin into a bootable virtual machine. Run the `image_to_vm.sh` command.

### Booting

Once you build an image you can launch it with KVM (instructions will print out after `image_to_vm.sh` runs).

## Making changes

### git and repo

CoreOS is managed by `repo`, a tool built for the Android project that makes managing a large number of git repositories easier. From the repo announcement blog:

> The repo tool uses an XML-based manifest file describing where the upstream
> repositories are, and how to merge them into a single working checkout. repo
> will recurse across all the git subtrees and handle uploads, pulls, and other
> needed items. repo has built-in knowledge of topic branches and makes working
> with them an essential part of the workflow.

(from the [Google Open Source Blog][repo-blog])

You can find the full manual for repo by visiting [android.com - Developing][android-repo-git].

### Updating repo manifests

The repo manifest for CoreOS lives in a git repository in
`.repo/manifests`. If you need to update the manifest edit `default.xml`
in this directory.

`repo` uses a branch called 'default' to track the upstream branch you
specify in `repo init`, this defaults to 'origin/master'. Keep this in
mind when making changes, the origin git repository should not have a
'default' branch.

## Building images

There are separate workflows for building [production images][prodimages] and [development images][devimages].

## Tips and tricks

We've compiled a [list of tips and tricks][sdktips] that can make working with the SDK a bit easier.

## Testing images

[Mantle][mantle] is a collection of utilities used in testing and launching SDK images.


[android-repo-git]: https://source.android.com/source/developing.html
[coreos-dev]: https://groups.google.com/forum/#!forum/coreos-dev
[devimages]: /docs/sdk-distributors/sdk/building-development-images
[github-coreos]: https://github.com/coreos/
[irc]: irc://irc.freenode.org:6667/#coreos
[mantle]: /docs/sdk-distributors/sdk/mantle
[prodimages]: /docs/sdk-distributors/sdk/building-production-images
[repo-blog]: http://google-opensource.blogspot.com/2008/11/gerrit-and-repo-android-source.html
[sdktips]: /docs/sdk-distributors/sdk/tips-and-tricks
