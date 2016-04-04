# Creating an OAuth Application in BitBucket

This document describes how to authenticate Quay Enterprise registry users with their [BitBucket][bitbucket] identities.

- Log into BitBucket
- Visit the Settings page for your organization
- Click the "OAuth" tab under "Access Management"
- Click the Add Consumer button:

<img src="img/bb-add-consumer.png" class="image-center"/>

Next, configure BitBucket to redirect you back to Quay upon a successful login:

- Enter your registry's URL as the `URL`
- Enter `https://{REGISTRY URL HERE}/oauth2/bitbucket/callback` as the `Callback URL`.
- Grant permissions on the repositories and webhooks:

<img src="img/bb-app-permissions.png" class="image-center"/>

- Save the application
- Record the Key and Secret shown in the new entry in the list of OAuth consumers after saving the application:

<img src="img/bb-app-info.png" class="image-center"/>

Return to the Quay Enterprise setup tool to enter the Key and Secret recorded above, and complete the setup procedure.

[bitbucket]:https://bitbucket.org