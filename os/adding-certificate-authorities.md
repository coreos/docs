# Custom certificate authorities

CoreOS Container Linux supports custom Certificate Authorities (CAs) in addition to the default list of trusted CAs. Adding your own CA allows you to:

- Use a corporate wildcard certificate
- Use your own CA to communicate with an installation of CoreUpdate

The setup process for any of these use-cases is the same:

1. Copy the PEM-encoded certificate authority file (usually with a `.pem` file name extension) to `/etc/ssl/certs`

2. Run the `update-ca-certificates` script to update the system bundle of Certificate Authorities. All programs running on the system will now trust the added CA.

## More information

[Generate Self-Signed Certificates](generate-self-signed-certificates.md)

[etcd Security Model](https://github.com/coreos/etcd/blob/master/Documentation/op-guide/security.md)
