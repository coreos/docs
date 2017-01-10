# Setup GitHub build triggers

Quay Enterprise supports using GitHub or GitHub Enterprise as a trigger to building
images.

## Initial setup

If you have not yet done so, please [enable build support in Quay Enterprise](build-support.md).

## Create an OAuth application in GitHub

Following the instructions at [Create a GitHub Application](github-app.md).

**NOTE:** This application must be **different** from that used for GitHub Authentication.

## Visit the management panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Quay Enterprise Management Panel"/>

## Enable GitHub triggers

<img src="img/enable-trigger.png" class="img-center" alt="Enable GitHub Trigger"/>

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled **GitHub (Enterprise) Build Triggers**.
- Check the "Enable GitHub Triggers" box
- Fill in the credentials from the application created above
- Click "Save Configuration Changes"
- Restart the container (you will be prompted)

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/quay-enterprise/github-build.md?pixel)]() <!-- END ANALYTICS -->