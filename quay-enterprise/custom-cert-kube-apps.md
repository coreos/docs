## Using Helm Registry Plug-in with a self-signed certificate



This document assumes you have deployed Quay Enterprise with a self-signed certificate.

[Appr](https://github.com/app-registry/appr) makes use of the python requests library, which by default only trusts a standard set of certificates. This prevents helm from interacting with a Quay Enterprise instance that is using a self-signed certificate.

The error is reported as a connection error when attempting to interact with the registry:

```
$ helm registry version https://reg.example.com
Api-version: .. Connection error
Client-version: 0.3.7
```

To get around this restriction add the CA for the self signed certificate to the default list of trusted Certificate Authorities. The following links highlight how this can be accomplished:

[Container Linux](https://coreos.com/os/docs/latest/adding-certificate-authorities.html)

[Red Hat](https://access.redhat.com/solutions/1519813)

[Ubuntu/Debian](https://askubuntu.com/questions/73287/how-do-i-install-a-root-certificate)



### Add an environment variable that points python-requests to the correct certificate chain:

```
$ export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
```


This will allow helm to connect to Quay Enterprise:

````
$ helm registry version reg.example.com   
Api-version: {u'cnr-api': u'0.2.7'}
Client-version: 0.3.7
````
