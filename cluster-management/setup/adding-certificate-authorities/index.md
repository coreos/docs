---
layout: docs
title: Adding Certificate Authorities
category: cluster_management
sub_category: setting_up
weight: 7
---

# Custom Certificate Authorities

What if we restructured this paragraph to list the reasons first, then have it lead into the steps:

CoreOS supports custom Certificate Authorities (CAs) in addition to the default list of trusted CAs. Adding your own CA allows you to:

- Use a corporate wildcard certificate
- Use your own CA to communicate with an installation of CoreUpdate
- Use your own CA to communicate with a private docker registry

The setup process for any of these use-cases is the same:

1. Drop the certificate authority PEM file into `/etc/ssl/certs`

2. Run the `update-ca-certificates` script
