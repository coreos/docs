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
differences between host OSes. The SDK must be run on an x86-64 Linux machine,
the distro should not matter (Ubuntu, Fedora, etc).

### Prerequisites

System requirements to get started:

- curl
- git
- python2

You also need a proper git setup:

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

**NOTE**: Do the git configuration as a normal user and not with sudo.

### Install repo

`repo` helps to manage the collection of git repositories that makes up CoreOS.
Pull down the code and add it to your path:

```sh
mkdir ~/bin
export PATH="$PATH:$HOME/bin"
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

You may want to add this to your .bashrc or /etc/profile.d/ so that you don’t
need to reset your $PATH manually each time you open a new shell.

### Bootstrap the SDK chroot

Create a project directory. This will hold all of your git repos and the SDK
chroot. A few gigs of space will be necessary.

```sh
mkdir coreos; cd coreos
```

Initialize the .repo directory with the manifest that describes all of the git
repos required to get started.

```sh
repo init -u https://github.com/coreos/manifest.git
```

Synchronize all of the required git repos from the manifest.

```sh
repo sync
```

### Registering QEMU for cross-compiled builds

Currently the tool that generates our initramfs, dracut, assumes it is
running on the target system. For cross-compiled builds this is not true
so QEMU's user mode emulation is used to fake it. If your dev system uses
systemd write the following to `/etc/binfmt.d/qemu-aarch64.conf`:

```
:qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-aarch64-static:
```

And run:

```sh
systemctl restart systemd-binfmt.service
```

The qemu binary, `/usr/bin/qemu-aarch64-static` is not expected to be on
your host system. It will be inside the `arm64-usr` build root that is
entered via chroot prior to running dracut.

### Building an image

Download and enter the SDK chroot which contains all of the compilers and
tooling.

```sh
./chromite/bin/cros_sdk
```

**WARNING:** If you ever need to delete the SDK chroot use
`./chromite/bin/cros_sdk --delete`. Otherwise, you will delete `/dev`
entries that are bind mounted into the chroot.

Set up the "core" user's password.

```sh
./set_shared_user_password.sh
```

Setup a board root filesystem for the amd64-usr target in /build/amd64-usr:

```sh
./setup_board --default --board=amd64-usr
```

Similarly, use `arm64-usr` for the cross-compiled ARM target. If you switch
between different targets in a single SDK you can add the `--board=` option
to `build_packages`, `build_image`, and so on to select either target.

Build all of the target binary packages:

```sh
./build_packages
```

An extra step is required before building `arm64-usr` images. We need to
build GRUB for `arm64` but this isn't handled automatically yet. Just write
the following to `/etc/portage/package.use/grub`:

```
sys-boot/grub grub_platforms_arm64
```

And run:

```sh
sudo emerge -v grub
```

Build an image based on the built binary packages, including development tools:

```sh
./build_image dev
```

After this finishes up commands for converting the raw bin into
a bootable vm will be printed. Run the `image_to_vm.sh` command.

### Booting

Once you build an image you can launch it with KVM (instructions will
print out after `image_to_vm.sh` runs).

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

You can find the full manual for repo by visiting [android.com - Developing][android-repo-git].

[android-repo-git]: https://source.android.com/source/developing.html

### Updating repo manifests

The repo manifest for CoreOS lives in a git repository in
`.repo/manifests`. If you need to update the manifest edit `default.xml`
in this directory.

`repo` uses a branch called 'default' to track the upstream branch you
specify in `repo init`, this defaults to 'origin/master'. Keep this in
mind when making changes, the origin git repository should not have a
'default' branch.

## Building Images

There are separate workflows for building [production images](/docs/sdk-distributors/sdk/building-production-images) and [development images](/docs/sdk-distributors/sdk/building-development-images).

## Tips and Tricks

We've compiled a [list of tips and tricks](/docs/sdk-distributors/sdk/tips-and-tricks) that can make working with the SDK a bit easier.

## Testing Images

[Mantle](/docs/sdk-distributors/sdk/mantle) is a collection of utilities
used in testing and launching SDK images.
