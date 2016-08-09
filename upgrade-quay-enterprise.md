# Quay Enterprise upgrade guide

This document describes how to upgrade one or more Quay Enterprise containers.

## Backup the Quay Enterprise database

The database is the "source of truth" for Quay, and some version upgrades will trigger a schema update and data migration. Such versions are clearly documented in the [Quay Enterprise release notes][qe-releases].

Backup the database before upgrading Quay Enterprise. Once the backup completes, use the procedure in this document to stop the running Quay Enterprise container, start the new container, and check the health of the upgraded Quay Enterprise service.

## Provide Quay credentials to the Docker client

```
docker login quay.io
```

## Pull the latest Quay Enterprise release from the CoreOS repository

Check the [list of Quay Enterprise releases][qe-releases] for the latest version.

```
docker pull quay.io/coreos/registry:RELEASE_VERSION
```

Replace `RELEASE VERSION` with the desired version of Quay Enterprise.

## Find the running Quay Enterprise container ID

```
docker ps -a
```

The Quay Enterprise image will be labeled `quay.io/coreos/registry`.

## Stop the existing Quay Enterprise container

```
docker stop QE_CONTAINER_ID
```

## Start the new Quay Enterprise container

```
docker run --restart=always -p 443:443 -p 80:80 --privileged=true \
-v /local/path/to/config/directory:/conf/stack \
-v /local/path/to/storage/directory:/datastorage \
-d quay.io/coreos/registry:RELEASE_VERSION
```

Replace `/local/path/to/config/directory` and `/local/path/to/storage/directory` with the absolute paths to those directories on the host. Replace `RELEASE_VERSION` with the desired Quay Enterprise version.

Rarely, but occasionally, the new Quay Enterprise version may perform a database schema upgrade and migration. Versions requiring such database migrations will take potentially much longer to start the first time. These versions are clearly documented in the [release notes][qe-releases], which should be consulted before each Quay Enterprise upgrade.

## Check the health of the upgraded container

Visit the /health/endtoend endpoint on the registry hostname and verify that the code is 200 and `is_testing` is false.

## Upgrade the rest of the containers in the cluster.

If the upgraded container is healthy, repeat this process for all remaining Quay Enterprise containers.


[qe-releases]: https://tectonic.com/quay-enterprise/releases/
