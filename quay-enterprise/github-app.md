# Creating an OAuth application in GitHub

You can authorize your registry to access a GitHub account and its repositories by registering it as a GitHub OAuth application.

## Create new GitHub application

* Log into GitHub (Enterprise)
* Visit the *Applications* page under your organization's settings.
* Click [*Register New Application*](https://github.com/settings/applications/new). The *new OAuth application* configuration screen is displayed:

<img src="img/register-app.png" class="image-center"/>

### Set Homepage URL

* Enter the Quay Enterprise URL as the **Homepage URL**

Note: If using public GitHub, the Homepage URL entered must be accessible by *your users*. It can still be an internal URL.

### Set Authorization callback URL

* Enter `https://{$QUAY ENTERPRISE URL}/oauth2/github/callback` as the **Authorization callback URL**.
* Save your settings by clicking the **Register application** button. The new new application's summary is shown:

<img src="img/view-app.png" class="image-center"/>

* Record the `Client ID` and `Client Secret` shown for the new application.
