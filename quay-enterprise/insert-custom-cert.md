# Add Certificate to the Quay Enterprise Container

In the config directory create the a new directory `extra_ca_certs/` and copy any custom certs required to this directory. On boot Quay Enterprise will update the list of trusted certificates via the `update-ca-certificates` command. 

#### Example

View certificate to be added to the container: 

```
$ cat storage.crt  
-----BEGIN CERTIFICATE-----
MIIDTTCCAjWgAwIBAgIJAMVr9ngjJhzbMA0GCSqGSIb3DQEBCwUAMD0xCzAJBgNV
[...]
-----END CERTIFICATE-----
```

Created directory and copy certificate:

```
$ mkdir quay/config/extra_ca_certs

$ cp storage.crt quay/config/extra_ca_certs/

$ ls quay/config/extra_ca_certs/
storage.crt 
```

Restart QE container and check cert with `docker exec`:

```
$ docker ps      
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS              PORTS 
5a3e82c4a75f        quay.io/coreos/quay:v2.0.0           "/sbin/my_init"          24 hours ago        Up 18 hours         0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 8443/tcp   grave_keller

$ docker restart 5a3e82c4a75f

$ docker exec -it 5a3e82c4a75f cat /etc/ssl/certs/storage.pem
-----BEGIN CERTIFICATE-----
MIIDTTCCAjWgAwIBAgIJAMVr9ngjJhzbMA0GCSqGSIb3DQEBCwUAMD0xCzAJBgNV
```

