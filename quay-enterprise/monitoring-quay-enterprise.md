# Monitoring Quay Enterprise

It is essential to identify, measure and evaluate the performance of Quay Enterprise when running in production. 

## Endpoints

There are two main web endpoints to monitor in Quay Enterprise:

`/heath/endtoend` 

`/health/instance` (on every container instance) 

Both of these endpoints return JSON that describes the status of the various components of the registry. It is essential to monitor the `status_code` parameter for a non-200 response as this indicates an issue that should be immediately addressed as it may impact registry functionality. Other services in this JSON report `true` or `false`. With `true` meaning the service is functioning and `false` indicating an issue with the service. 

### Healthcheck Frequency 

Once a minute or so on `/health/instance`

Once every 2 minutes on `/health/endtoend`

### Considerations

Pinging these endpoints opens connections to the various services utilized by the registry. This is essential to ensuring the availability of the registry but may cause issues if checks are improperly configured. For example a improperly configured healthcheck, such as one with an incredibly small interval, may cause db connection timeouts or connection limits to be hit or cause storage engines to trigger automatic rate limiting. 

## Database

Quay Enterprise does not support master-master database setups therefore it is essential to monitor the performance and ensure the availability of the database being utilized by registry. It is advised to follow the upstream documentation of the database vendor or use a third party monitoring tool such as Sysdig, Datadog, or Prometheus. 

## Storage

Quay Enterprise supports a variety of storage engines each with guidelines for monitoring. Setting up monitoring of these services is not within the scope of this document. 

The JSON returned by the `/health/endtoend` endpoint includes a check of the connection between the registry and the storage engine. If this value returns `false` this indicates that the storage engine is down or inaccessible by the registry. 

## Redis

Redis is utilized by Quay Enterprise in a manner that allows toleration of failure. Browse the upstream redis documentation for more information on this topic. 

## Auth 

The endpoints described above will return `"auth": false` if there is any issues related to authentication services that may prevent users from login. This should be monitored closely if the registry is configured to use LDAP or another external auth service. 

## Kubernetes Probes 

The Quay Enterprise deployment manifest does not include any Liveness or Readiness probes. If probes are added the advice in this document should be taken into account. Liveness probes should make use of HTTP GET requests on the endpoints described above. 







