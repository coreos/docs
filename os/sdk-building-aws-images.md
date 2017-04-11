# Building AWS images

## Build the image

Prior to creating an AMI, you must have built the image in the first place.

Follow the instruction for building [production images][prodimages] or [development images][devimages].

## Pushing an AMI image to Google Storage

Once the image is built, convert it to an AMI in Google Cloud Storage. The can be accomplished with something like the following (from within the sdk):

```shell
$ ./image_to_vm.sh --from=../build/images/amd64-usr/developer-$VERSION --prod_image --upload_root='gs://users.developer.core-os.net/$USER' --upload --format=ami
```

*Note*: The `./build_image` script will output most of the above command. The important additional pieces are `--upload` and `--format=ami`

## Converting the AMI image to an EC2 Snapshot

The image stored in Google Cloud Storage must now be created as a "snapshot" which can then be converted into a proper AMI.

In order to do this, you will need an EC2 instance. The following
prerequisites must be satisfied on the instance:

* `python2` must be available
* The `gsutil` command must be installed and configured to have access to the GS bucket used above
* The `ec2-api-tools` package must be installed
* You must have IAM credentials with at least the following policy:

```json
{
	"Version": "2012-10-17",
		"Statement": [{
			"Sid": "Stmt1482277952000",
			"Effect": "Allow",
			"Action": [
				"ec2:AttachVolume",
				"ec2:CreateSnapshot",
				"ec2:CreateVolume",
				"ec2:DeleteVolume",
				"ec2:DescribeSnapshots",
				"ec2:DescribeVolumes",
				"ec2:DetachVolume",
				"ec2:RegisterImage"
			],
			"Resource": [
				"*"
			]
		}]
}

```

Once all that's setup, it's a simple matter of cloning the scripts repo and running the right script:

```shell
$ git clone https://github.com/coreos/scripts && cd scripts
$ export AWS_ACCESS_KEY=<access key>
$ export AWS_SECRET_KEY=<secret key>
$ ./oem/ami/build_ebs_on_ec2.sh -u gs://users.developer.core-os.net/$USER/boards/amd64-usr/$VERSION/coreos_production_ami_image.bin.bz2
# This will take quite some time
```

HVM and PV AMI ids will be printed at the end which may be launched.


[devimages]: sdk-building-development-images.md
[prodimages]: sdk-building-production-images.md
