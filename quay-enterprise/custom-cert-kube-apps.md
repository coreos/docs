## Using Helm Registry Plug-in with a self-signed certificate

This document assumes you have deployed [Quay Enterprise with a self-signed certificate.][self-signed]

[Appr](https://github.com/app-registry/appr) uses a [Python Requests library][python-requests], which trusts only a standard set of certificates by default. This prevents Helm from interacting with a Quay Enterprise instance that is using a self-signed certificate.

The error is reported as a connection error when attempting to interact with the registry:

```
$ helm registry version https://reg.example.com
Api-version: .. Connection error
Client-version: 0.3.7
```

To work around this restriction, add the CA for the self-signed certificate to the default list of trusted Certificate Authorities. This process is described for the following platforms:

[Container Linux][container-linux]
[Red Hat][red-hat]
[Ubuntu/Debian][ubuntu]


### Add an environment variable that points Python Requests to the correct certificate chain:

```
$ export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
```

This will allow Helm to connect to Quay Enterprise:

````
$ helm registry version reg.example.com   
Api-version: {u'cnr-api': u'0.2.7'}
Client-version: 0.3.7
````
[self-signed]: quay-ssl.md
[python-requests]: http://docs.python-requests.org/en/master/
[container-linux]: https://coreos.com/os/docs/latest/adding-certificate-authorities.html
[red-hat]: https://access.redhat.com/solutions/1519813
[ubuntu]: https://askubuntu.com/questions/73287/how-do-i-install-a-root-certificate
