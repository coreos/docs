# CoreOS Container Linux developer SDK guide

These are the instructions for building Container Linux itself. By the end of the guide you will build a developer image that you can run under KVM and have tools for making changes to the code.

Container Linux is an open source project. All of the source for Container Linux is available on [github][github-coreos]. If you find issues with these docs or the code please send a pull request.

Direct questions and suggestions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Getting started

Let's get set up with an SDK chroot and build a bootable image of Container Linux. The SDK chroot has a full toolchain and isolates the build process from quirks and differences between host OSes. The SDK must be run on an x86-64 Linux machine, the distro should not matter (Ubuntu, Fedora, etc).

### Prerequisites

System requirements to get started:

* curl
* git
* bzip2
* gpg
* sudo

You also need a proper git setup:

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

**NOTE**: Do the git configuration as a normal user and not with sudo.

### Using Cork

The `cork` utility, included in the CoreOS [mantle](https://github.com/coreos/mantle) project, is used to create and work with an SDK chroot.

First, download the cork utility:

```sh
curl -L -o cork https://github.com/coreos/mantle/releases/download/v0.12.0/cork-0.12.0-amd64
curl -L -o cork.sig https://github.com/coreos/mantle/releases/download/v0.12.0/cork-0.12.0-amd64.sig
```

Now, verify the download with the signature:  

```sh
gpg --keyserver keys.gnupg.net --recv-keys 9CEB8FE6B4F1E9E752F61C82CDDE268EBB729EC7
gpg --verify cork.sig cork
```

The `gpg --verify` command should output something like this:

```
gpg: Signature made Thu 19 Apr 2018 03:33:40 PM PDT
gpg:                using RSA key 9CEB8FE6B4F1E9E752F61C82CDDE268EBB729EC7
gpg: Good signature from "CoreOS Application Signing Key <security@coreos.com>" [unknown]
Primary key fingerprint: 18AD 5014 C99E F7E3 BA5F  6CE9 50BD D3E0 FC8A 365E
     Subkey fingerprint: 9CEB 8FE6 B4F1 E9E7 52F6  1C82 CDDE 268E BB72 9EC7
```

Then proceed with the installation of the cork binary to a location on your path:

```sh
chmod +x cork
mkdir -p ~/.local/bin
mv cork ~/.local/bin
export PATH=$PATH:$HOME/.local/bin
```

You may want to add the `PATH` export to your shell profile (e.g. `.bashrc`).


Next, use the cork utility to create a project directory. This will hold all of your git repos and the SDK chroot. A few gigabytes of space will be necessary.

```sh
mkdir coreos-sdk
cd coreos-sdk
cork create # This will request root permisions via sudo
cork enter  # This will request root permisions via sudo
```

Verify you are in the SDK chroot:

```
$ grep NAME /etc/os-release
NAME="Container Linux by CoreOS"
```
To leave the SDK chroot, simply run `exit`.

To use the SDK chroot in the future, run `cork enter` from the above directory.


### Building an image

#### Set up the chroot

After entering the chroot via `cork` for the first time, you should set user `core`'s password:

```sh
./set_shared_user_password.sh
```

This is the password you will use to log into the console of images built and launched with the SDK.

Then, to create a root filesystem for the `amd64-usr` build target beneath the directory `/build/amd64-usr/`:

```sh
./setup_board
```

#### Compile and link system binaries

Build all of the target binary packages:

```sh
./build_packages
```

#### Render the CoreOS Container Linux image

Build a production image based on the binary packages built above:

```sh
./build_image
```

After `build_image` completes, it prints commands for converting the raw bin into a bootable virtual machine. Run the `image_to_vm.sh` command.

### Booting

Once you build an image you can launch it with KVM (instructions will print out after `image_to_vm.sh` runs).

If you encounter errors with KVM, verify that virtualization is supported by your CPU by running `egrep '(vmx|svm)' /proc/cpuinfo`. The `/dev/kvm` directory will be in your host OS when virtualization is enabled in the BIOS.

The `./coreos_production_qemu.sh` file can be found in the `~/trunk/src/build/images/amd64-usr/latest` directory inside the SDK chroot.

#### Boot Options

After `image_to_vm.sh` completes, run `./coreos_production_qemu.sh -curses` to launch a graphical interface to log in to the Container Linux VM.

You could instead use the `-nographic` option, `./coreos_production_qemu.sh -nographic`, which gives you the ability to switch from the VM to the QEMU monitor console by pressing <kbd>CTRL</kbd>+<kbd>a</kbd> and then <kbd>c</kbd>. To close the Container Linux Guest OS VM, run `sudo systemctl poweroff` inside the VM. 

You could also log in via SSH by running `./coreos_production_qemu.sh` and then running `ssh core@127.0.0.1 -p 2222` to enter the guest OS. Running without the `-p 2222` option will arise a *ssh: connect to host 127.0.0.1 port 22: Connection refused* or *Permission denied (publickey,gssapi-keyex,gssapi-with-mic)* warning. Additionally, you can log in via SSH keys or with a different ssh port by running this example `./coreos_production_qemu.sh -a ~/.ssh/authorized_keys -p 2223 -- -curses`. Refer to the [Booting with QEMU](booting-with-qemu.md#SSH-keys) guide for more information on this usage.

The default login username is `core` and the [password is the one set in the `./set_shared_user_password`](sdk-modifying-coreos.md#Building-an-image) step of this guide. If you forget your password, you will need to rerun `./set_shared_user_password` and then `./build_image` again.

## Making changes

### git and repo

Container Linux is managed by `repo`, a tool built for the Android project that makes managing a large number of git repositories easier. From the repo announcement blog:

> The repo tool uses an XML-based manifest file describing where the upstream
> repositories are, and how to merge them into a single working checkout. repo
> will recurse across all the git subtrees and handle uploads, pulls, and other
> needed items. repo has built-in knowledge of topic branches and makes working
> with them an essential part of the workflow.

(from the [Google Open Source Blog][repo-blog])

You can find the full manual for repo by visiting [android.com - Developing][android-repo-git].

### Updating repo manifests

The repo manifest for Container Linux lives in a git repository in
`.repo/manifests`. If you need to update the manifest edit `default.xml`
in this directory.

`repo` uses a branch called 'default' to track the upstream branch you
specify in `repo init`, this defaults to 'origin/master'. Keep this in
mind when making changes, the origin git repository should not have a
'default' branch.

## Building release images

The [production images][prodimages] document is unmaintained and out of date, but contains useful pointers as to how official release images are built.

## Tips and tricks

We've compiled a [list of tips and tricks][sdktips] that can make working with the SDK a bit easier.

## Testing images

[Mantle][mantle] is a collection of utilities used in testing and launching SDK images.


[android-repo-git]: https://source.android.com/source/developing.html
[coreos-dev]: https://groups.google.com/forum/#!forum/coreos-dev
[github-coreos]: https://github.com/coreos/
[irc]: irc://irc.freenode.org:6667/#coreos
[mantle]: https://github.com/coreos/mantle
[prodimages]: sdk-building-production-images.md
[repo-blog]: http://google-opensource.blogspot.com/2008/11/gerrit-and-repo-android-source.html
[sdktips]: sdk-tips-and-tricks.md
