---
layout: docs
title: Setup GitHub Build Triggers
category: registry
sub_category: setup
forkurl: https://github.com/coreos/docs/blob/master/enterprise-registry/github-build/index.md
weight: 5
---

# Setup GitHub Build Triggers

CoreOS Enterprise Registry supports using GitHub or GitHub Enterprise as a trigger to building
images.

## Initial Setup

If you have not yet done so, please <a href="{{site.url}}/docs/enterprise-registry/build-support/">enable build support</a> in the Enterprise Registry.

## Create an OAuth Application in GitHub

The first step in supporting GitHub Build is to create an OAuth Application representing the
Enterprise Registry *for building* in GitHub or GitHub Enterprise.

*Note:* A *separate* application must be setup for GitHub build, independent of the one used for [GitHub Authentication]({{site.url}}/docs/enterprise-registry/github-auth/).

- Log into GitHub (Enterprise)
- Visit the applications page under your organization's settings and click "<a href="https://github.com/settings/applications/new">Register New Application</a>".


<img src="{{site.url}}/docs/enterprise-registry/github-auth/register-app.png" class="img-center" alt="Register Application"/>

- Enter your registry's URL as the application URL

Note: If using public GitHub, the URL entered must be accessible by *your users*. It can still be an internal URL.

- Enter `https://{REGISTRY URL HERE}/oauth2/github/callback` as the Authorization callback URL.
- Create the application and note down the `Client ID` and `Client Secret`.

<img src="{{site.url}}/docs/enterprise-registry/github-auth/view-app.png" class="img-center" alt="View Application"/>

## Change the feature flag

Next, in the Enteprise Registry `config.yaml`, change the following to enable GitHub Build:

```yaml
FEATURE_GITHUB_BUILD: false
```

to

```yaml
FEATURE_GITHUB_BUILD: true
```

## Add new configuration

In the Enteprise Registry `config.yaml`, add the following section:

```yaml

# For GitHub Enterprise building
GITHUB_TRIGGER_CONFIG: {
  'GITHUB_ENDPOINT': '(GITHUB ENTERPRISE ENDPOINT HERE)',
  'CLIENT_ID': '(CLIENT ID)',
  'CLIENT_SECRET': '(CLIENT SECRET)',
}

# For GitHub.com building
GITHUB_TRIGGER_CONFIG: {
  'GITHUB_ENDPOINT': 'https://github.com/',
  'API_ENDPOINT': 'https://api.github.com/',
  'CLIENT_ID': '(CLIENT ID)',
  'CLIENT_SECRET': '(CLIENT SECRET)',
}
```

