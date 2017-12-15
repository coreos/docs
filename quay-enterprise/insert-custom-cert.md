# Adding TLS Certificates to the Quay Enterprise Container

To add custom TLS certificates to Quay Enterprise, create a new directory named `extra_ca_certs/` beneath the Quay Enterprise config directory. Copy any required site-specific TLS certificates to this new directory.

## Example

### View certificate to be added to the container:

```
$ cat storage.crt
-----BEGIN CERTIFICATE-----
MIIDTTCCAjWgAwIBAgIJAMVr9ngjJhzbMA0GCSqGSIb3DQEBCwUAMD0xCzAJBgNV
[...]
-----END CERTIFICATE-----
```

### Create certs directory and copy certificate there:

```
$ mkdir -p quay/config/extra_ca_certs

$ cp storage.crt quay/config/extra_ca_certs/

$ tree quay/config/
├── config.yaml
├── extra_ca_certs
│   ├── storage.crt
```

### Restart QE container and check cert with docker-exec:

Obtain the quay container's `CONTAINER ID` with `docker ps`:

```
$ docker ps
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS              PORTS
5a3e82c4a75f        quay.io/coreos/quay:v2.6.1           "/sbin/my_init"          24 hours ago        Up 18 hours         0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 8443/tcp   grave_keller
```

Restart the container with that ID:

```
$ docker restart 5a3e82c4a75f
```

Examine the certificate copied into the container namespace:

```
$ docker exec -it 5a3e82c4a75f cat /etc/ssl/certs/storage.pem
-----BEGIN CERTIFICATE-----
MIIDTTCCAjWgAwIBAgIJAMVr9ngjJhzbMA0GCSqGSIb3DQEBCwUAMD0xCzAJBgNV
```


## Add certs when deployed on Kubernetes

When deployed on Kubernetes, QE mounts in a secret as a volume to store config assets. Unfortunately, this currently breaks the upload certificate function of the superuser panel.

To get around this error, a base64 encoded certificate can be added to the secret *after* Quay Enterprise has been deployed.

Begin by base64 encoding the contents of the certificate:

```
$ cat ca.crt
-----BEGIN CERTIFICATE-----
MIIDljCCAn6gAwIBAgIBATANBgkqhkiG9w0BAQsFADA5MRcwFQYDVQQKDA5MQUIu
TElCQ09SRS5TTzEeMBwGA1UEAwwVQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTE2
MDExMjA2NTkxMFoXDTM2MDExMjA2NTkxMFowOTEXMBUGA1UECgwOTEFCLkxJQkNP
UkUuU08xHjAcBgNVBAMMFUNlcnRpZmljYXRlIEF1dGhvcml0eTCCASIwDQYJKoZI
[...]
-----END CERTIFICATE-----

$ cat ca.crt | base64 -w 0
[...]
c1psWGpqeGlPQmNEWkJPMjJ5d0pDemVnR2QNCnRsbW9JdEF4YnFSdVd3PT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
```

Use the `kubectl` tool to edit the quay-enterprise-config-secret.
```
$ kubectl --namespace quay-enterprise edit secret/quay-enterprise-config-secret
```

Add an entry for the cert and paste the full base64 encoded string under the entry:

```
  custom-cert.crt:
c1psWGpqeGlPQmNEWkJPMjJ5d0pDemVnR2QNCnRsbW9JdEF4YnFSdVd3PT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
```

Add the env variable `REQUESTS_CA_BUNDLE` to the quay deployment: 

```
kubectl --namespace quay-enterprise edit deploy/quay-enterprise-app 

```

The `REQUESTS_CA_BUNDLE` env should be defined under the `containers:` section: 

```
      containers:
      - name: quay-enterprise-app
        image: quay.io/coreos/quay:v2.6.1
        ports:
        - containerPort: 80
      env: 
      - name: REQUESTS_CA_BUNDLE 
	value: /conf/stack/custom-cert.crt
```


Finally, recycle all QE pods. Use `kubectl delete` to remove all QE pods. The QE Deployment will automatically schedule replacement pods with the new certificate data.
