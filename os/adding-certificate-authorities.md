# Custom Certificate Authorities

CoreOS supports custom Certificate Authorities (CAs) in addition to the default list of trusted CAs. Adding your own CA allows you to:

- Use a corporate wildcard certificate
- Use your own CA to communicate with an installation of CoreUpdate
- Use your own CA to communicate with a private Docker registry

The setup process for any of these use-cases is the same:

1. Drop the certificate authority PEM file into `/etc/ssl/certs`

2. Run the `update-ca-certificates` script

# More Information

For another examples, check out these documents:

[Generate Self Signed Certificates]({{site.baseurl}}/os/docs/latest/generate-self-signed-certificates)
[etcd Security Model]({{site.baseurl}}/etcd/docs/latest/security.html)
