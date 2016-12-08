# Overview of a Pod

A Kubernetes pod is a group of containers that are deployed together on the same host. If you frequently deploy single containers, you can generally replace the word "pod" with "container" and accurately understand the concept.

Pods operate at one level higher than individual containers because it's very common to have a group of containers work together to produce an artifact or process a set of work.

For example, consider this pair of containers: a caching server and a cache "warmer". You could build these two functions into a single container, but now they can each be tailored to the specific task and shared between different projects/teams.

Another example is an app server pod that contains three separate containers: the app server itself, a monitoring adapter, and a logging adapter. The logging and monitoring containers could be shared across all projects in your organization. These adapters could provide an abstraction between different cloud monitoring vendors or other destinations.

Any project requiring logging or monitoring can include these containers in their pods, but not have to worry about the specific logic. All they need to do is send logs from the app server to a known location within the pod. How does that work? Let's walk through it.

## Shared Namespaces, Volumes and Secrets

By design, all of the containers in a pod are connected to facilitate intra-pod communication, ease of management and flexibility for application architectures. If you've ever fought with connecting two raw containers together, the concept of a pod will save you time and is much more powerful.

### Shared Network

All containers share the same network namespace &amp; port space. Communication over localhost is encouraged. Each container can also communicate with any other pod or service within the cluster.

### Shared Volumes

Volumes attached to the pod may be mounted inside of one or more containers. In the logging example above, a volume named `logs` is attached to the pod. The app server would log output to `logs` mounted at `/volumes/logs` and the logging adapter would have a read-only mount to the same volume. If either of these containers needed to restarted, the log data is preserved instead of being lost.

There are many types of volumes supported by Kubernetes, including native support for mounting Github repos, network disks (EBS, NFS, etc), local machine disks, and a few special volume types, like secrets.

Here's an example pod:

```
apiVersion: v1
kind: Pod
metadata:
  name: example-app
  labels:
    app: example-app
    version: v1
    role=backend
spec:
  containers:
  - name: java
    image: companyname/java
    ports:
    - containerPort: 443
    volumeMounts:
    - mountPath: /volumes/logs
      name: logs
  - name: logger
    image: companyname/logger:v1.2.3
    ports:
    - containerPort: 9999
    volumeMounts:
    - mountPath: /logs
      name: logs
  - name: monitoring
    image: companyname/monitoring:v4.5.6
    ports:
    - containerPort: 1234
```

### Resources

Resource limits such as CPU and RAM are shared between all containers in the pod.

## Creating Pods

Pods are considered ephemeral "cattle" and won't survive a machine failure and may be terminated for machine maintenance. For high resiliency, pods are managed by a [replication controller][controller-overview], which creates and destroys replicas of pods as needed. Individual pods can also be created outside of a replication controller, but this isn't a common practice.

[Kubernetes services][service-overview] should always be used to expose pod(s) to the rest of the cluster in order to provide the proper level of abstraction since individual pods will come and go.

Replication controllers and services use the *pod labels* to select a group of pods that they interact with. Your pods will typically have labels for the application name, role, environment, version, etc. Each of these can be combined in order to select all pods with a certain role, a certain application, or a more complex query. The label system is extremely flexible by design and experimentation is encouraged to establish the practices that work best for your company or team.

<div class="co-m-docs-next-step">
  <p><strong>Are you familiar with replication controllers and services?</strong></p>
  <a href="replication-controller.md" class="btn btn-default">Replication Controller overview</a>
  <a href="services.md" class="btn btn-default">Services overview</a>
  <a href="index.html" class="btn btn-link">Back to Listing</a>
</div>

[controller-overview]: replication-controller.md
[service-overview]: services.md