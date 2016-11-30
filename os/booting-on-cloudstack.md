# Running CoreOS on CloudStack

This guide explains how to deploy CoreOS with CloudStack. These instructions will walk you through downloading CoreOS image and running an instance from it. This document assumes that CloudStack is already installed. Please refer to the [Install Guide][install-guide] for CloudStack installation steps.


## Register the CoreOS image (template)

After logging in to CloudStack UI, to upload a template:

1. In the left navigation bar, click Templates.
2. Click Register Template.
3. Provide the following:
  * **Name and Description**: These will be shown in the UI, so choose something descriptive.
  * **URL**: The Management Server will download the file from the specified URL, such as `http://dl.openvm.eu/cloudstack/coreos/x86_64/coreos_production_cloudstack_image-kvm.qcow2.bz2`.
  * **Zone**: Choose the zone where you want the template to be available, or All Zones to make it available throughout CloudStack.
  * **OS Type**: This helps CloudStack and the hypervisor perform certain operations and make assumptions that improve the performance of the guest.
  * **Hypervisor**: The supported hypervisors are listed. Select the desired one.
  * **Format**: The format of the template upload file, such as VHD or OVA.
  * **Extractable**: Choose Yes if the template is available for extraction. If this option is selected, end users can download a full image of a template.
  * **Public**: Choose Yes to make this template accessible to all users of this CloudStack installation. The template will appear in the Community Templates list. See [CoreOS Templates](#coreos-templates).
  * **Featured**: Choose Yes if you would like this template to be more prominent for users to select. The template will appear in the Featured Templates list. Only an administrator can make a template Featured.

Alternatively, the [registerTemplate API][register-template-api] can also be used.

### CoreOS templates

Apache CloudStack community created [CoreOS templates][coreos-templates] are currently available for XenServer, KVM, VMware and HyperV hypervisors.

### Deploy CoreOS instance

To create a VM from a template:

1. Log in to the CloudStack UI as an administrator or user.
2. In the left navigation bar, click Instances.
3. Click Add Instance.
4. Select a zone.
5. Select the CoreOS template registered in the previous step.
6. Click Submit and your VM will be created and started.

Alternatively, the [deployVirtualMachine API][deploy-vm-api] can also be used to deploy CoreOS instances.

### Virtual machine configuration

cloud-config can be provided using userdata while deploying virtual machine. userdata is an optional request parameter for the [deployVirtualMachine API][deploy-vm-api].

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart][coreos-quickstart] guide or dig into [more specific topics][coreos-docs].

[install-guide]: http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/latest/
[register-template-api]: http://cloudstack.apache.org/docs/api/apidocs-4.4/user/registerTemplate.html
[deploy-vm-api]: http://cloudstack.apache.org/docs/api/apidocs-4.4/user/deployVirtualMachine.html
[coreos-templates]: http://dl.openvm.eu/cloudstack/coreos/x86_64/
[coreos-quickstart]: quickstart.md
[coreos-docs]: https://coreos.com/docs
