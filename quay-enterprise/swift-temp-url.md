# Enterprise Registry Swift Direct Download

## Direct Download

The Swift storage engine supports using a feature called [temporary URLs](http://docs.openstack.org/juno/config-reference/content/object-storage-tempurl.html) to allow for faster pulling of images.

To enable direct download with Swift, please follow these instructions.

## Create a Swift temporary URL token

To enable temporary URLs, first set the `X-Account-Meta-Temp-URL-Key` header on your Object Storage account to an arbitrary string. This string serves as a secret key. For example, to set a key of `somecoolkey` using the swift command-line tool:

```
$ swift post -m "Temp-URL-Key:somecoolkey"
```

## Visit the Management Panel

Sign in to a super user account and visit `http://registry.example.com/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Enterprise Registry Management Panel"/>

## Go to the settings tab

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled <strong>Registry Storage</strong>.
- Ensure that "OpenStack Storage (Swift)" is selected

## Enter the temporary URL key

Enter the key generated above into the `Temp URL Key` field under the Swift storage engine settings.

## Save configuration

Hit `Save Configuration` to save and validate your configuration. The Swift storage engine system will automatically
test that the direct download feature is enabled and working.