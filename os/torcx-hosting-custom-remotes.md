# Hosting custom Torcx remotes

## Remotes Overview

A Torcx [remote][torcx-remotes-design] is a collection of addon images for torcx, served from a remote source, which can be fetched by a host and used by [torcx-generator][torcx-overview].
A remote can be served via any traditional web server and content integrity and authenticity is digitally verified via OpenPGP signatures.

## Content of a remote

A Torcx remote is a collection of static files, providing Torcx addon images over HTTP(S) to Container Linux nodes.

Main elements of a Torcx remote are:

 * base URL: base URL for the remote. Supported protocols are `http` and `https`.
 * content manifest: a list of images provided by this remote. It is a JSON document with a fixed [schema][schema-remote-contents], wrapped in an OpenPGP cleartext signature.
 * images: tarballs or [squashfs][squashfs] images containing Torcx addons

## Creating a Torcx remote

Torcx remotes are meant to be self-contained below their base URL.

Clients will first look for the content manifest named `torcx_remote_contents.json.asc` to discover the addon images available on a Torcx remote.

A sample remote, hosting a single `my-addon:1` image as a squashfs, will have a manifest like the following:

```json
{
  "kind": "torcx-remote-contents-v1",
  "value": {
    "images": [
      {
        "name": "my-addon",
        "versions": [
          {
            "version": "1",
            "format": "squashfs",
            "hash": "sha512-68f06d394fbdeb3b214bae0761f9f10badf94d6e1bc7360864df8310dce31eb0a9e10829c29fdecbad0ae13145cffa21afd7e8dd062a36cc84453cbe4b0cf29e",
            "location": "images/my-addon:1.torcx.squashfs"
          }
        ]
      }
    ]
  }
}
```

In order to be properly used as a contents manifest, such JSON snippet has to be clearsigned with `gpg` as follows:

```
$ gpg2 --output torcx_remote_contents.json.asc --clear-sign sample-manifest.json
```

## Hosting a Torcx remote

Contents for a remote Torcx like the one described above can be hosted anywhere on a web server, as long as they rooted under the appropriate base url.

Assuming the hosting site is `https://torcx-remotes.example.com/my-remote/` and the remote it targeted at an `amd64` Container Linux node at version 1855.4.0, remote layout would look as follows:

```
 - https://torcx-remotes.example.com/my-remote/amd64-usr/1855.4.0/
   - /torcx_manifest.json.asc
   - /images/
     - /my-addon:1.torcx.squashfs
```

Such remote can be consumed using the base URL `https://torcx-remotes.example.com/my-remote/${COREOS_BOARD}/${VERSION_ID}/`.
In order to provision the corresponding configuration on consuming nodes, please follow the [Torcx remotes usage guide][torcx-using-custom-remotes].

## Usage notes

Please note that remote instances are specifically bound to a single OS architecture and version, as there is no ABI compatibility guarantee across different Container Linux releases.

In order to support upgrades through the lifecycle of a Container Linux node, it is enough to instantiate new remotes matching the `${VERSION_ID}` of consuming nodes.

[torcx-remotes-design]: https://github.com/coreos/torcx/blob/master/Documentation/design/remotes.md
[torcx-overview]: torcx-overview.md
[schema-remote-contents]: https://github.com/coreos/torcx/blob/master/Documentation/schemas/remote-contents-v1.md
[squashfs]: https://www.kernel.org/doc/Documentation/filesystems/squashfs.txt
[torcx-using-custom-remotes]: torcx-using-custom-remotes.md
