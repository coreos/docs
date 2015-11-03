# Setup GitHub Build Triggers

CoreOS Enterprise Registry supports using GitHub or GitHub Enterprise as a trigger to building
images.

## Initial Setup

If you have not yet done so, please [enable build support](build-support.md) in the Enterprise Registry.

## Create an OAuth Application in GitHub

Following the instructions at [Create a GitHub Application](github-app.md).

**NOTE:** This application must be **different** from that used for GitHub Authentication.

## Visit the Management Panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Enterprise Registry Management Panel"/>

## Enable GitHub Triggers

<img src="img/enable-trigger.png" class="img-center" alt="Enable GitHub Trigger"/>

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled <strong> GitHub (Enterprise) Build Triggers</strong>.
- Check the "Enable GitHub Triggers" box
- Fill in the credentials from the application created above
- Click "Save Configuration Changes"
- Restart the container (you will be prompted)

## Tag an Automated Build

After getting automated builds working, it may be desired to tag a specific build with a name. By default, the last image pushed to a repository will be tagged as `latest`.
Because tagging is [usually done client side](https://docs.docker.com/userguide/dockerimages/#setting-tags-on-an-image) before an image is pushed, it may not be clear how to tag an image that was built and pushed by GitHub. Luckily, there is a interface for doing so on the repository page. After clicking to select a given build on the build graph, the right side of the page displays tag information which when clicked provides a drop-down menu with the option of creating a new tag.

<img src="img/new-tag.png" class="img-center" alt="Create a new tag"/>

There is currently no ability to automatically tag GitHub triggered builds.
