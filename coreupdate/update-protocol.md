# Omaha

The Omaha protocol is the specification that the update service uses to communicate with updaters running in a CoreOS cluster. The protocol is a fairly simple &mdash; it specifies sending HTTP POSTs with XML data bodies for various events that happen during the execution of an update.

## Update Request

The update request sends machine metadata and a list of applications that it is responsible for. In most cases, each updater is responsible for a single package. Here's what a typical request looks like:

```
<?xml version="1.0" encoding="UTF-8"?>
<request protocol="3.0">
 <app appid="e96281a6-d1af-4bde-9a0a-97b76e56dc57" version="1.0.0" track="beta" bootid="{fake-client-018}">
  <event eventtype="3" eventresult="2"></event>
 </app>
</request>
```

### Application Section

The app section is where the action happens. You can submit multiple applications or application instances in one request, but this isn't standard.

| Parameter | Description |
|-----------|-------------|
| appid     | Matches the id of the group that that this instance belongs to in the update service. |
| version   | The current semantic version number of the application code. |
| track     | The channel that the application is requesting. |
| bootid    | The unique identifier assigned to this instance. |

## Already Up to Date

If the application instance is already running the latest version, the response will be short:

```
<?xml version="1.0" encoding="UTF-8"?>
<response protocol="3.0" server="update.core-os.net">
 <daystart elapsed_seconds="0"></daystart>
 <app appid="e96281a6-d1af-4bde-9a0a-97b76e56dc57" status="ok">
  <updatecheck status="noupdate"></updatecheck>
 </app>
</response>
```

As you can see, the response indicated that no update was required for the provided group id and version.

## Update Required

If the application is not up to date, the response returned contains all of the information needed to execute the update:

```
<?xml version="1.0" encoding="UTF-8"?>
<response protocol="3.0" server="update.core-os.net">
 <daystart elapsed_seconds="0"></daystart>
 <app appid="e96281a6-d1af-4bde-9a0a-97b76e56dc57" status="ok">
  <updatecheck status="ok">
   <urls>
    <url codebase="http://index.example.com/webapp:1.0.2"></url>
   </urls>
   <manifest version="1.0.2">
    <packages>
     <package hash="fe7374bddde2ddf07f6bfcc728d115d14338964b" name="update.gz" size="23" required="false"></package>
    </packages>
    <actions>
     <action event="postinstall" sha256="b602d630f0a081840d0ca8fc4d35810e42806642b3127bb702d65c3df227d0f5" needsadmin="false" IsDelta="false" DisablePayloadBackoff="true" MetadataSignatureRsa="ixi6Oebo" MetadataSize="190"></action>
    </actions>
   </manifest>
  </updatecheck>
 </app>
</response>
```

The most important parts of the response are the `codebase`, which points to the location of the package, and the `sha256` which should be checked to make sure the package hasn't been tampered with.

## Report Progress, Errors and Completion

Events are submitted to the update service as the updater passes certain milestones such as starting the download, installing the update and confirming that the update was complete and successful. Events are specified in numerical codes corresponding to the event initiated and the resulting state. You can find a [full list of the event codes](https://code.google.com/p/omaha/wiki/ServerProtocol#event_Element) in Google's documentation. The CoreOS update service implements a subset of these events:

| Event Description | Event Type | Event Result |
|-------------------|------------|--------------|
| Downloading latest version. | `13` | `1` |
| Update package arrived successfully. | `14` | `1` |
| Updater has processed and applied package. | `3` | `1` |
| Install success. Update completion prevented by instance. | `800` | `1` |
| Instances upgraded to current channel version. | `3` | `2` |
| Instance reported an error during an update step. | `3` | `0` |

For example, a `3:2` represents a successful update and a successful reboot. Here's the request and response:

### Request

```
<?xml version="1.0" encoding="UTF-8"?>
<request protocol="3.0">
 <app appid="e96281a6-d1af-4bde-9a0a-97b76e56dc57" version="1.0.0" track="beta" bootid="{fake-client-018}">
  <event eventtype="3" eventresult="2"></event>
 </app>
</request>
```

### Response

The protocol dictates that each event should be acknowledged even if no data needs to be returned:

```
<response protocol="3.0" server="update.core-os.net">
  <daystart elapsed_seconds="0"></daystart>
  <app appid="e96281a6-d1af-4bde-9a0a-97b76e56dc57" status="ok"></app>
</response>
```

## Further Reading

You can read more about the [Omaha tech specs](https://code.google.com/p/omaha/wiki/ServerProtocol) or visit the [project homepage](https://code.google.com/p/omaha/).
