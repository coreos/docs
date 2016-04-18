# Running CoreOS on Packet

Packet is a bare metal cloud hosting provider. CoreOS is installable as one of the default operating system options. You can deploy CoreOS servers via the Packet portal or API.

## Channels

Currently the Packet OEM is making it's way through the 3 CoreOS channels. As it becomes available to a new channel it will become available on Packet. There are no seperate instructions per channel that are outside of the normal CoreOS instructions.

## Deployment instructions

The first step in deploying any devices on Packet is to first create an account and decide if you'd like to deploy via our portal or API. The portal is appropriate for small clusters of machines that won't change frequently. If you'll be deploying a lot of machines, or expect your workload to change frequently it is much more efficient to use the API. You can generate an API token through the portal once you've set up an account and payment method. Create an account here: [Packet Account Registration](https://www.packet.net/promo/coreos/).

### Projects

Packet has a concept of 'projects' that represent a grouping of machines that defines several other aspects of the service. A project defines who on the team has access to manage the machines in your account. Projects also define your private network; all machines in a given project will automatically share backend network connectivity. The SSH keys of all team members associated with a project will be installed to all newly provisioned machines in a project. All servers need to be in a project, even if there is only one server in that project.

### Portal instructions

Once logged into the portal you will be able to click the 'Deploy' button and choose CoreOS from the menu of operating systems, and choose which project you want the server to be deployed in. If you choose to enter custom cloud-config, you can click the 'manage' link and add that as well. The SSH key that you associate with your account and any other team member's keys that are on the project will be added to your CoreOS machine once it is provisioned.

### API instructions

If you elect to use the API to provision machines on Packet you should consider using [one of our language libraries](https://www.packet.net/dev/) to code against. As an example, this is how you would launch a single Type 1 machine in a curl command. [Packet API Documentation](https://www.packet.net/dev/api/).

```bash
# Replace items in brackets (<EXAMPLE>) with the appropriate values.

curl -X POST \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'X-Auth-Token: <API_TOKEN>' \
-d '{"hostname": "<HOSTNAME>", "plan": "baremetal_1", "facility": "ewr1", "operating_system": "coreos_alpha", "userdata": "<USERDATA>"}' \
https://api.packet.net/projects/<PROJECT_ID>/devices
```

Double quotes in the `<USERDATA>` value must be escaped such that the request body is valid JSON. See the Cloud-Config section below for more information about accepted forms of userdata.

### Cloud-config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config). Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. Once a machine is created on Packet, the cloud-config cannot be modified. This example can be used to spin up a minimal cluster.

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379
    initial-advertise-peer-urls: http://$private_ipv4:2380
    listen-client-urls: http://0.0.0.0:2379
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

#### IP addresses

The `$private_ipv4`, `$public_ipv4`, and `$public_ipv6` variables are fully supported in cloud-config on Packet. Packet is fully IPv6 compliant and we encourage you to utilize IPv6 for public connectivity with your running containers. Make sure to read up on [IPv6 and Docker](https://docs.docker.com/articles/networking/#ipv6) if you choose to take advantage of this functionality.

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
