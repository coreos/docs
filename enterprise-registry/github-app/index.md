---
layout: docs
title: Register GitHub Application
category: registry
sub_category: none
forkurl: https://github.com/coreos/docs/blob/master/enterprise-registry/github-app/index.md
weight: 5
---

# Creating an OAuth Application in GitHub

- Log into GitHub (Enterprise)
- Visit the applications page under your organization's settings and click "<a href="https://github.com/settings/applications/new">Register New Application</a>".

<img src="{{site.url}}/docs/enterprise-registry/github-app/register-app.png" class="image-center"/>

- Enter your registry's URL as the application URL

Note: If using public GitHub, the URL entered must be accessible by *your users*. It can still be an internal URL.

- Enter `https://{REGISTRY URL HERE}/oauth2/github/callback` as the Authorization callback URL.
- Create the application

<img src="{{site.url}}/docs/enterprise-registry/github-app/view-app.png" class="image-center"/>

- Note down the `Client ID` and `Client Secret`.
