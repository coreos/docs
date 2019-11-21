# Using custom Torcx remotes

## Remotes Overview

A Torcx [remote][torcx-remotes-design] is a collection of addon images for torcx, served from a remote source, which can be fetched by a node for use by [torcx-generator][torcx-overview].
Images for configured addons can be retrieved automatically on first-boot provisioning (i.e. in initramfs) and when preparing for new OS updates (i.e. before marking a node as "reboot needed").

## Usage notes

Before starting to configure Torcx remotes, a word of caution on their usage.
Torcx is not a full package manager, and trying to use it as such may result in unexpected behaviors.

In particular, there is no dependency resolution across addons, and images are supposed to be self-contained and re-built for each specific Container Linux version.

Provisioning images from remotes is coupled with both first-boot setup and OS upgrade mechanisms.
Configuring an image not available on a remote can result in first-boot provisioning failures or in blocked upgrades.

All of the above behaviors are by-design restrictions in order to minimize possible breakages at runtime.

Unless it is strictly required for very specific usecases, it is usually reccommended not use custom Torcx addons and remotes.

## Provisioning a Torcx remote

Torcx remotes use a reverse-domain naming scheme, and can be configured on nodes during first-boot provisioning via a JSON manifest and an armored OpenPGP keyring.
The local manifest describes where a Torcx remote is located and which public keys to use for metadata verification, according to the documented [schema][schema-remote-manifest].

A sample remote named `com.example.my-remote` signed by key `4C8413AA38176150A8906994BB1A3A854F3BBEBF` can be provisioned with the following [Container Linux Config][ct-configs] snippet:

```yaml container-linux-config
storage:
  files:
    - path: /etc/torcx/remotes/com.example.my-remote/remote.json
      filesystem: root
      mode: 0640
      contents:
        inline: |
          {
            "kind": "remote-manifest-v0",
            "value": {
              "base_url": "https://torcx-remotes.example.com/my-remote/${COREOS_BOARD}/${VERSION_ID}/",
              "keys": [
                { "armored_keyring": "4C8413AA38176150A8906994BB1A3A854F3BBEBF.pgp.asc" }
              ]
            }
          }

    - path: /etc/torcx/remotes/com.example.my-remote/4C8413AA38176150A8906994BB1A3A854F3BBEBF.pgp.asc
      filesystem: root
      mode: 0640
      contents:
        inline: |
          -----BEGIN PGP PUBLIC KEY BLOCK-----
          
          mQINBFPOTCkBEADVqHsjLwgh9RrDln/oOS3MQgYnYhI72IpAiNhp9j+kdKWCrc7S
          [...]
          DQzFS07A45A=
          =dYyN
          -----END PGP PUBLIC KEY BLOCK-----
```

The base URL for a remote is a templated string which is evaluated at runtime for simple variable substitution.
Commonly used variables include:

 * `${COREOS_BOARD}`: board type (e.g. "amd64-usr")
 * `${VERSION_ID}`: OS version (e.g. "1680.2.0")
 * `${ID}`: OS vendor ID (e.g. "coreos")


## Enabling a Torcx addon from a remote

In order to use a Torcx addon from a remote, it must be configured in the active profile and it should reference the remote where it can be located.

After having configured the remote `com.example.my-remote`, provisioning an addon named `my-addon` at version `1` out of it can be done with the following configuration snippet:

```yaml container-linux-config
storage:
  files:
    - path: /etc/torcx/profiles/my-profile.json
      filesystem: root
      mode: 0640
      contents:
        inline: |
          {
            "kind": "profile-manifest-v1",
            "value": {
              "images": [
                {
                  "name": "my-addon",
                  "reference": "1",
                  "remote": "com.example.my-remote"
                }
              ]
            }
          }
          
    - path: /etc/torcx/next-profile
      filesystem: root
      mode: 0640
      contents:
        inline: "my-profile\n"
```

Please note that a single user-profile can be active at any point, thus further customizations should be done directly against the profile manifest above.

## Behavior on updates

Whenever a new OS update is available and before applying it to the running node, [Update Engine][update_engine] checks and tries to provision all configured Torcx addons from remotes.

If it is not possible to provision any of the configured addons for the upcoming OS, the update will not applied and the process will be re-tried later.

This can happen if an addon is not anymore present on a remote, if the image matching the new OS version is not yet available, or in case of any other error when fetching from a remote.

In that case, errors will be logged to the system journal and can be inspected as follows:

```
$ sudo journalctl -t coreos-postinst
```

[torcx-remotes-design]: https://github.com/coreos/torcx/blob/master/Documentation/design/remotes.md
[torcx-overview]: torcx-overview.md
[schema-remote-manifest]: https://github.com/coreos/torcx/blob/master/Documentation/schemas/remote-manifest-v0.md
[ct-configs]: provisioning.md
[update_engine]: https://github.com/coreos/update_engine
