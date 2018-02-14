# High Availability for Quay Enterprise

Quay Enterprise is designed to be run as a *single global* high availability service with minimal setup. This guide
explains the best practices for running Quay Enterprise in an HA setup.

## Required Dependencies

The following services are required in order to run Quay Enterprise as HA:

- A decent sized Postgres or MySQL database with **automatic backup and failover**. Amazon RDS is an example of a service that has automatic backup and failover.
- A high availability distributed storage engine such as Amazon S3, Google Cloud Storage, Ceph RADOS or Swift. **Using local storage with NFS is not recommended** for HA setups.
- A Redis server running on a medium sized machine. Redis is not considered critical and therefore does not require failover or backup.
- A load balancer capable of TCP passthrough.
- At least three medium-sized machines for the cluster.

## Basic setup

Perform the basic [Quay Enterprise Setup](initial-setup.md) process, using the above database, storage, redis and using the *load balancer hostname* as the server hostname. Once complete, save the contents of the `conf/stack` directory.

## High Availability Setup

The ensure high availability, it is recommended that machines running in the cluster be self-initializing.

Each machine will need to be able to:

1. Start from a predefined init script. [coreos-cloudinit](https://github.com/coreos/coreos-cloudinit) can be used with Container Linux.
2. Populate the `conf/stack` directory saved in the previous step
3. Pull down the Quay Enterprise image via `docker pull`. **It is _highly_ recommended that you lock to a specific tagged version of Quay Enterprise**
4. Run the Quay Enterprise image, with the configuration directory mounted

## Health checking instances

Once a cluster has been setup, the next step is to setup health checking to ensure that if a machine fails, it is automatically removed and replaced in the cluster.

Quay Enterprise exports a health checking endpoint at `https://{yourloadbalancerhostname}/health/instance` that will return a `200` HTTP status code if the machine is healthy.

### Specialized RDS health checking

If the backing database is RDS, an additional healthcheck config can be specified to ensure that machines report as healthy even if RDS is current in failover mode.

```yaml
HEALTH_CHECKER:
- RDSAwareHealthCheck
- access_key: access_key_here
  secret_key: secret_key_here
  region: us-east-1
  db_instance: quay-database
```

## Health checking the cluster

To ensure the cluster as a whole is healthy, Quay Enterprise also exports a cluster-wide services status endpoint at `https://{yourloadbalancerhostname}/health/endtoend` that will return a `200` HTTP status code only if all services (database, redis, etc) are healthy.

## Autoscaling

The final step in ensuring high availability for a Quay Enterprise cluster is ensuring it can scale to meet incoming demand. Scaling is typically accomplished by monitoring metrics such as CPU and memory, and adding (or removing) machines based on thresholds. On Amazon, CloudWatch alarms and Autoscaling Groups can be used to accomplish this task.
