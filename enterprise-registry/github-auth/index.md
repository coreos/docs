---
layout: docs
title: Configure GitHub Authentication
category: registry
sub_category: setup
fork_url: https://github.com/coreos/docs/blob/master/enterprise-registry/github-auth/index.md
weight: 5
---

# GitHub Authentication

CoreOS Enterprise Registry supports using GitHub or GitHub Enterprise as an authentication system.

## Create an OAuth Application in GitHub

Following the instructions at <a href="{{site.baseurl}}/docs/enterprise-registry/github-app/">Create a GitHub Application</a>.

**NOTE:** This application must be **different** from that used for GitHub Build Triggers.

## Visit the Management Panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="../build-support/superuser.png" class="img-center" alt="Enterprise Registry Management Panel"/>

## Enable GitHub Authentication

<img src="enable-auth.png" class="img-center" alt="Enable GitHub Authentication"/>

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled <strong> GitHub (Enterprise) Authentication</strong>.
- Check the "Enable GitHub Authentication" box
- Fill in the credentials from the application created above
- Click "Save Configuration Changes"
- Restart the container (you will be prompted)
