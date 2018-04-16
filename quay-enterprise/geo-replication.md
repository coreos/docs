# Georeplication of storage in Quay Enterprise

Georeplication allows for a single globally-distributed Quay Enterprise to serve container images from localized storage.

When georeplication is configured, container image pushes will be written to the preferred storage engine for that QE instance. After the initial push, image data will be replicated in the background to other storage engines. Georeplication provides eventually consistentency of the image store. The list of replication locations is configurable. An image pull will always use the closest available storage engine, to maximize pull performance. Images pushed when georeplication is enabled will usually be available at other storage site after just a few minutes although this is dependent on the network route between the QE instance and the various storage engines.

## Prerequisites

Georeplication requires that there be a high availability storage engine (S3, GCS, RADOS, Swift) in each geographic region. Further, each region must be able to access **every** storage engine due to replication requirements.

**NOTE:** Local disk storage is not compatible with georeplication at this time.

## Visit the Management Panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Quay Enterprise Management Panel"/>

## Enable storage replication

1. Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled <strong>Registry Storage</strong>.
2. Click "Enable Storage Replication".
3. Add each of the storage engines to which data will be replicated. All storages to be used must be listed.
4. If complete replication of all images to all storage engines is required, under each storage engine configuration click "Replicate to storage engine by default". This will ensure that all images are replicated to that storage engine. To instead enable per-namespace replication, please contact support.
5. Click Save to validate.

## Run Quay Enterprise with storage preferences

1. Copy the config.yaml to all machines running Quay Enterprise
2. For each machine in each region, add a `QUAY_DISTRIBUTED_STORAGE_PREFERENCE` environment variable with the preferred storage engine for the region in which the machine is running.

    For example, for a machine running in Europe:

    ```
    docker run -d -p 443:443 -p 80:80 -v /conf/stack:/conf/stack -e QUAY_DISTRIBUTED_STORAGE_PREFERENCE=europestorage quay.io/coreos/quay:versiontag
    ```

    *NOTE: The value of the environment variable specified must match the name of a storage engine as defined in the config panel*

3. Restart all Quay Enterprise containers
