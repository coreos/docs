---
layout: docs
title: Modifying CoreOS
category: sdk_distributors
sub_category: sdk
weight: 3
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
differences between host OSes. The SDK must be run on an x86-64 Linux machine,
the distro should not matter (Ubuntu, Fedora, etc).

### Prerequisites

System requirements to get started:

- curl
- git

You also need a proper git setup:

```
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

**NOTE**: Do the git configuration as a normal user and not with sudo.

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
repo init -u https://github.com/coreos/manifest.git -g minilayout --repo-url https://chromium.googlesource.com/external/repo.git
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

## Building Images

There are separate workflows for [building production](/docs/sdk-distributors/sdk/building-production-images) images and [development images](/docs/sdk-distributors/sdk/building-development-images).

## Tips and Tricks

We've compiled a [list of tips and tricks](/docs/sdk-distributors/sdk/tips-and-tricks) that can make working with the SDK a bit easier.
