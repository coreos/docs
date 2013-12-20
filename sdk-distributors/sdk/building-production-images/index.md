---
layout: docs
title: Building Production Images
category: sdk_distributors
sub_category: sdk
weight: 5
---

# Building Production Images

In general the automated process should always be used but in a pinch
putting together a release manually may be necessary. All release
information is tracked in the [manifest][coreos-manifest] git
repository which is usually organized like so:

 * build-109.xml (previous release manifest)
 * build-115.xml (current release manifest)
 * master.xml    (master branch manifest)
 * version.txt   (current version information)
 * default.xml -> master.xml
 * release.xml -> build-115.xml

[coreos-manifest]: https://github.com/coreos/manifest

## Manual Builds

The first step of building a release is updating and tagging the release
in the manifest git repository. A typical release off of master involves
the following steps:

 1. Make sure you are on the master branch: `repo init -b master`
 2. Sync/checkout source, excluding local changes: `repo sync --detach`
 3. Switch to the somewhat hidden manifests checkout: `cd .repo/manifests`
 4. Update `version.txt` with the desired version number.
    * COREOS_BUILD is the major version number, and should be the number
      of days since July 1st, 2013. COREOS_BRANCH should start at 0 and
      is incremented for every normal release based on a particular
      COREOS_BUILD version. COREOS_PATCH is reserved for exceptional
      situations such as emergency manual releases and should normally
      be 0.
    * The complete version string is
      COREOS_BUILD.COREOS_BRANCH.COREOS_PATCH
    * COREOS_SDK_VERSION should be the complete version string of an
      existing build. The `cros_sdk` uses this to pick what SDK tarball
      to use when creating a fresh chroot and provides a fallback set of
      binary packages to use when the current release's packages are
      unavilable. Usually it will be one release behind COREOS_BUILD.
 5. Generate a release manifest: `repo manifest -r -o build-$BUILD.xml`
    where `$BUILD` is the crrent value of COREOS_BUILD in `version.txt`.
 6. Update `release.xml`: `ln -sf build-$BUILD.xml release.xml`
 7. Commit! `git add build-$BUILD.xml; git commit -a`
 8. Tag! `git tag v$BUILD.$BRANCH.$PATCH`
 9. Push! `git push origin HEAD:master HEAD:dev-channel
    HEAD:build-$BUILD v$BUILD.$BRANCH.$PATCH`

If a release branch needs to be updated after master has moved on the
procedure is similar but has a few key differences:

 1. Check out the release instead of master: `repo init -b build-$BUILD
    -m release.xml`
 2. Sync, cherry-pick, push, and whatever else is required to publish
    the desired changes in the repo-managed projects. If the desired
    changes are already published (such as if you are just updating to a
    later commit from a project's master branch) then this can be
    skipped.
 3. `cd .repo/manifests`
 4. Update `version.txt` as desired. Usually just increment
    COREOS_PATCH.
 5. Update `build-$BUILD.xml` as desired. The output of
    `repo manifest -r` shouldn't be used verbatim this time because it
    won't generate meaningful values for the `upstream` project
    attribute when starting from a release manifest instead of
    `master.xml` but it can be useful for looking up the git commit to
    update the `revision` attribute to. If the new git commit is on a
    branch other than master be sure to update the `upstream` attribute
    with the apropriate ref spec for that branch.
 6. If this is the first time this branch has been updated on its own
    update the `default.xml` link so checking out this manifest branch
    with repo init but without the `-m` argument works:
    `ln -sf build-$BUILD.xml default.xml`
 7. Commit! `git commit -a`
 8. Tag! `git tag v$BUILD.$BRANCH.$PATCH`
 9. Push! `git push origin HEAD:dev-channel
    HEAD:build-$BUILD v$BUILD.$BRANCH.$PATCH`

Now you can start building images!
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

## Automated Builds

Automated release builds are triggered by pushes to the `dev-channel`
branch in the manifest repository. When cutting releases off of master
you can skip the long process described above by using the `tag_release`
script:

 1. Make sure you are on the master branch: `repo init -b master`
 2. Sync/checkout source, excluding local changes: `repo sync --detach`
 3. In the scripts directory: `./tag_release --push`

That's it! Automated builds will now kick off to generate a new SDK
tarball and disk images for most of our supported platform types.
Unfortunately since tagging branched releases (not on master) requires a
bit more thought use the manual process described above. The automated
build will still kick off after updating the `dev-channel` branch.

Note: In the future builds will be triggered by pushing new tags instead
of using the `dev-channel` branch. Only using tags will mesh better with
our current plans for adding more release channels.

## Pushing updates to the dev-channel

### Manual Builds

To push an update to the dev channel track on api.core-os.net build a
production images as described above and then use the following tool:

```
COREOS_OFFICIAL=1 ./core_upload_update <required flags> --track dev-channel --image ../build/images/amd64-generic/latest/coreos_production_image.bin
```

### Automated builds

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

We've compiled a [list of tips and tricks](/docs/sdk-distributors/sdk/tips-and-tricks) that can make working with the SDK a bit easier.