# Configure CoreUpdate to serve packages from AWS S3  

The [updateservicectl][updateservicectl] tool can be used to fetch Container Linux updates from upstream and push the update payload to AWS S3. This process is documented for a general file server at: [CoreUpdate - Air Gapped Package Management][airgap]

Download the update payload from the upstream public CoreUpdate instance. The command below fetches the update payload for Container Linux release 1632.2.1:

```
$ updateservicectl --server=https://public.update.core-os.net package download --dir=/packages/ --version=1632.2.1
```

Now the /packages/ directory contains a JSON file with update metadata and the Gzipped update payload:

```
$ tree packages 
packages
├── e96281a6-d1af-4bde-9a0a-97b76e56dc57_1632.2.1_info.json
└── e96281a6-d1af-4bde-9a0a-97b76e56dc57_1632.2.1_update.gz

0 directories, 2 files
```

Use the `updateservicectl package create bulk` command to create the package on a CoreUpdate instance. In the example below, CoreUpdate is running at: `http://coreupdate.example.com:8000`. 

```
$ updateservicectl --server=http://coreupdate.example.com:8000 --user=admin --key=4025a24d-b1e4-4294-b0ca package create bulk --base-url=https://s3-us-west-1.amazonaws.com/core-update-support --dir=/packages
```

Note the use of the flags `--user` and `--key` these will be required. Most often the user will be `admin` and the key can be found in the `/etc/coreupdate/config.yaml` file. 

Be certain to format the URL passed to the `--base-url` flag as described in the AWS document: "[AWS S3 Regions and Endpoints][aws-endpoints]". 

On successful creation of the package, the output of this command will state where to upload payloads:

```
2018/02/06 15:59:41 Creating package with AppId=e96281a6-d1af-4bde-9a0a-97b76e56dc57 and Version=1632.2.1
2018/02/06 15:59:41 Package metadata uploaded. Total=1 Errors=0
2018/02/06 15:59:41 Please upload payloads to https://s3-us-west-1.amazonaws.com/core-update-support.
```

Upload the update package to the S3 bucket:

```
aws s3 cp /packages/e96281a6-d1af-4bde-9a0a-97b76e56dc57_1632.2.1_update.gz s3://core-update-support
```

Access is a very important thing to consider. It is required to have a bucket policy that will allow the machines updating to download the payload. A tool such as `curl` can be used to verify the payload can be fetched:

```
curl -L https://s3-us-west-1.amazonaws.com/core-update-support/e96281a6-d1af-4bde-9a0a-97b76e56dc57_1632.2.1_update.gz -o test.gz
```

Consult the document [CoreUpdate - Configure Machines][core-update-config] for details on configuring a Container Linux host to use CoreUpdate.


[updateservicectl]: https://github.com/coreos/updateservicectl/releases
[airgap]: on-premises-deployment.html#air-gapped-package-management
[aws-endpoints]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
[core-update-config]: configure-machines.html

