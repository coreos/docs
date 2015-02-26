---
layout: docs
title: CloudStack
category: running_coreos
sub_category: platforms
weight: 5
---

# Running CoreOS on CloudStack

This guide explains how to deploy CoreOS with CloudStack. These instructions will walk you through downloading CoreOS image and running an instance from it.
This document assumes that CloudStack is already installed. Please refer <a href="http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/latest/">Install Guide</a> for CloudStack installation steps.


## Register the CoreOS image (Template)

After logging in to CloudStack UI, to upload a template:

<ol>
<li><p>In the left navigation bar, click Templates.</p>
</li>
<li><p>Click Register Template.</p>
</li>
<li><p>Provide the following:</p>
<ul>
<li><p><strong>Name and Description</strong>. These will be shown in the UI, so choose
something descriptive.</p>
</li>
<li><p><strong>URL</strong>. The Management Server will download the file from the
specified URL, such as <tt><span class="pre">http://dl.openvm.eu/cloudstack/coreos/x86_64/coreos_production_cloudstack_image-kvm.qcow2.bz2</span></tt>.</p>
</li>
<li><p><strong>Zone</strong>. Choose the zone where you want the template to be
available, or All Zones to make it available throughout
CloudStack.</p>
</li>
<li><p><strong>OS Type</strong>: This helps CloudStack and the hypervisor perform
certain operations and make assumptions that improve the
performance of the guest. </p>
</li>
<li><p><strong>Hypervisor</strong>: The supported hypervisors are listed. Select the
desired one.</p>
</li>
<li><p><strong>Format</strong>. The format of the template upload file, such as VHD or
OVA.</p>
</li>
<li><p><strong>Extractable</strong>. Choose Yes if the template is available for
extraction. If this option is selected, end users can download a
full image of a template.</p>
</li>
<li><p><strong>Public</strong>. Choose Yes to make this template accessible to all
users of this CloudStack installation. The template will appear in
the Community Templates list. See <a class="reference external" href="#private-and-public-templates">“Private and
Public Templates”</a>.</p>
</li>
<li><p><strong>Featured</strong>. Choose Yes if you would like this template to be
more prominent for users to select. The template will appear in
the Featured Templates list. Only an administrator can make a
template Featured.</p>
</li>
</ul>
</li>
</ol>

Alternatively <a href="http://cloudstack.apache.org/docs/api/apidocs-4.4/user/registerTemplate.html">registerTemplate</a> API can also be used.

### CoreOS Templates

Apache CloudStack community created CoreOS templates are located at <a href="http://dl.openvm.eu/cloudstack/coreos/x86_64/">http://dl.openvm.eu/cloudstack/coreos/x86_64/</a>
CoreOS templates are currently available for XenServer, KVM, VmWare and HyperV hypervisors.

### Deploy CoreOS Instance

<p>To create a VM from a template:</p>
<ol>
<li><p>Log in to the CloudStack UI as an administrator or user.</p>
</li>
<li><p>In the left navigation bar, click Instances.</p>
</li>
<li><p>Click Add Instance.</p>
</li>
<li><p>Select a zone.</p>
</li>
<li><p>Select the CoreOS template registered in the previous step.
</li>
<li><p>Click Submit and your VM will be created and started.</p>
</li>
</ol>

Alternatively <a href="http://cloudstack.apache.org/docs/api/apidocs-4.4/user/deployVirtualMachine.html">deployVirtualMachine</a> API can also be used to deploy CoreOS instance.

### Virtual machine configuration

cloud-config can be provided using userdata while deploying virtual machine. userdata is an optional request parameter for deployVirtualMachine API

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
