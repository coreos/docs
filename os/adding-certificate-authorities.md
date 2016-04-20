# Custom certificate authorities

CoreOS supports custom Certificate Authorities (CAs) in addition to the default list of trusted CAs. Adding your own CA allows you to:

- Use a corporate wildcard certificate
- Use your own CA to communicate with an installation of CoreUpdate
- Use your own CA to [encrypt communications with a container registry](registry-authentication.md)

The setup process for any of these use-cases is the same:

1. Copy the PEM-encoded certificate authority file (usually with a `.pem` file name extension) to `/etc/ssl/certs`

2. Run the `update-ca-certificates` script to update the system bundle of Certificate Authorities. All programs running on the system will now trust the added CA.

## More information

[Generate Self-Signed Certificates](generate-self-signed-certificates.md)

[Use an insecure registry behind a firewall](registry-authentication.md#using-a-registry-without-ssl-configured)

[etcd Security Model]({{site.baseurl}}/etcd/docs/latest/security.html)
