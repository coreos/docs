# Running CoreOS Container Linux on Google Compute Engine

Before proceeding, you will need a GCE account ([GCE free trial ][free-trial]) and [install gcloud][gcloud-documentation] on your machine. In each command below, be sure to insert your project name in place of `<project-id>`.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcloud-documentation]: https://cloud.google.com/sdk/
[free-trial]: https://cloud.google.com/free-trial/?utm_source=coreos&utm_medium=partners&utm_campaign=partner-free-trial

After installation, log into your account with `gcloud auth login` and enter your project ID when prompted.

## Container Linux Config

Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs].

You can provide a raw Ignition config to Container Linux via the Google Cloud console's metadata field `user-data` or via a flag using `gcloud`.

As an example, this config will configure and start etcd:

```container-linux-config:gce
etcd:
  # All options get passed as command line flags to etcd.
  # Any information inside curly braces comes from the machine at boot time.

  # multi_region and multi_cloud deployments need to use {PUBLIC_IPV4}
  advertise_client_urls:       "http://{PRIVATE_IPV4}:2379"
  initial_advertise_peer_urls: "http://{PRIVATE_IPV4}:2380"
  # listen on both the official ports and the legacy ports
  # legacy ports can be omitted if your application doesn't depend on them
  listen_client_urls:          "http://0.0.0.0:2379"
  listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
  # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
  # specify the initial size of your cluster with ?size=X
  discovery:                   "https://discovery.etcd.io/<token>"
```

[cl-configs]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/getting-started.md

## Choosing a channel

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

Create 3 instances from the image above using our Ignition from `example.ign`:

<div id="gce-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-alpha --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-beta --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-stable --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
  </div>
</div>

### Additional storage

Additional disks attached to instances can be mounted with a `.mount` unit. Each disk can be accessed via `/dev/disk/by-id/google-<disk-name>`. Here's the Container Linux Config to format and mount a disk called `database-backup`:

```container-linux-config:gce
storage:
  filesystems:
    - mount:
        device: /dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
        format: ext4
        create:

systemd:
  units:
    - name: media-backup.mount
      enable: true
      contents: |
        [Mount]
        What=/dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
        Where=/media/backup
        Type=ext4

        [Install]
        RequiredBy=local-fs.target
```

For more information about mounting storage, Google's [own documentation](https://developers.google.com/compute/docs/disks#attach_disk) is the best source. You can also read about [mounting storage on Container Linux](mounting-storage.md).

### Adding more machines

To add more instances to the cluster, just launch more with the same Ignition config inside of the project.

## SSH

You can log in your Container Linux instances using:

```sh
gcloud compute ssh --zone us-central1-a core@<instance-name>
```

Users other than `core`, which are set up by the GCE account manager, may not be a member of required groups. If you have issues, try running commands such as `journalctl` with sudo.

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).
