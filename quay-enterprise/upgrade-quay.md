# Upgrade Quay Enterprise

The full list of Quay Enterprise versions can be found on the [Quay Enterprise Releases](https://tectonic.com/quay-enterprise/releases/) page.

### Special Note: Upgrading from Quay Enterprise < 2.0.0 to >= 2.0.0

If you are upgrading from a version of Quay Enterprise older than 2.0.0, you **must** upgrade to Quay Enterprise 2.0.0 **first**. Please follow the [Upgrade to Quay Enterprise 2.0.0 instructions](quay-enterprise-2.md) to upgrade to Quay Enterprise 2.0.0, and then follow the instructions below to upgrade from 2.0.0 to the latest version you'd like.

## Upgrading Note

We **highly** recommend performing upgrades during a scheduled maintainence window, as it will require taking the existing cluster down temporarily. We are working to remove this restriction in a future release.

## Upgrading Quay Enterprise

1. Visit the [Quay Enterprise Releases](https://tectonic.com/quay-enterprise/releases/) page and note the latest version of Quay Enterprise.
2. Shutdown the Quay Enterprise cluster: Remove **all** containers from service.
3. On a **single** node, run the newer version of Quay Enterprise.
4. Quay Enterprise will perform any necessary database migrations before bringing itself back into service.

Watch the logs of the running container to determine when the upgrade has completed:

```sh
docker logs -f {containerId}
```

5. Update all other nodes to refer to the new tag and bring them back into service.
