---
layout: docs
title: GitHub Authentication in Enterprise Registry
category: registry
sub_category: setup
forkurl: https://github.com/coreos/docs/blob/master/enterprise-registry/github-auth/index.md
weight: 5
---

# GitHub Authentication

CoreOS Enterprise Registry supports using GitHub or GitHub Enterprise as an authentication system.


## Create an OAuth Application in GitHub

The first step in supporting GitHub Authentication is to create an OAuth Application representing the
Enterprise Registry in GitHub or GitHub Enterprise. 

- Log into GitHub (Enterprise)
- Visit the applications page under your settings and click "<a href="https://github.com/settings/applications/new">Register New Application</a>".


<div class="graphic">
  <div class="screenshot">
    <img src="{{site.url}}/docs/enterprise-registry/github-auth/register-app.png" style="margin: 0 auto; display: block; max-width: 700px;"></img>
  </div>
</div>

- Enter your registry's URL as the application URL
- Enter `https://{REGISTRY URL HERE}/oauth2/github/callback` as the Authorization callback URL.
- Create the application and note down the `Client ID` and `Client Secret`.

## New configuration

In the Enteprise Registry `config.yaml`, add the following section:

```yaml

# For GitHub Enterprise authentication
GITHUB_LOGIN_CONFIG: {
  'GITHUB_ENDPOINT': '(GITHUB ENTERPRISE ENDPOINT HERE)',
  'CLIENT_ID': '(CLIENT ID)',
  'CLIENT_SECRET': '(CLIENT SECRET)',
}

# For GitHub.com authentication
GITHUB_LOGIN_CONFIG: {
  'GITHUB_ENDPOINT': 'https://github.com/',
  'API_ENDPOINT': 'https://api.github.com/',
  'CLIENT_ID': '(CLIENT ID)',
  'CLIENT_SECRET': '(CLIENT SECRET)',
}
```

## Configuration Changes

In the Enteprise Registry `config.yaml`, change:

```yaml
FEATURE_GITHUB_LOGIN: false
```

to 

```yaml
FEATURE_GITHUB_LOGIN: true
```

## Restart

Restart the CoreOS Enterprise Registry image and the `Login with GitHub` button should be present.
