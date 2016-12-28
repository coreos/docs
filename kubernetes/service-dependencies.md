# Service startup dependencies

Service startup often demands an order of operations for functional dependencies. For instance your application depends on a caching system, without the caching container the entire service will fall on it's face. The simplest solution to this problem is to create a service dependency in which one container only starts after another has successfully begun running.


## fleet: ExecStartPre

Fleet uses the systemd `ExecStartPre` `[Service]` directive [to ensure a command is run before a service starts][fleet-exec-pre], and the `Requires` `[Unit]` directive to ensure a dependency unit is running before a unit starts.

For instance one might create a file `myapp.service` which looks like this:

```
[Unit]
Description=MyApp
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill busybox1
ExecStartPre=-/usr/bin/docker rm busybox1
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name busybox1 busybox /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done"
ExecStop=/usr/bin/docker stop busybox1
```

This depends on `docker.sevice` and before beggining the application does some cleanup work with the three `ExecStartPre` commands which kill, remove, and pull the application's container.


## Kubernetes: init containers

[Kubernetes init containers][k8s-init-containers] operate in a similar way to the `ExecStartPre` directive in that they:

* Run before a specified Pod.
* Run to completion before the next init container.
* All run to completion before the specified Pod.

The feature is currently a beta feature of Kubernetes and so can only be invoked with raw JSON in the `.metadata.annotations` section of a Kubernetes specification file.

### Example: init container fetching data

An example of using an init container to download some local data for use in a container later looks like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  annotations:
    pod.beta.kubernetes.io/init-containers: '[
        {
            "name": "index-page",
            "image": "busybox",
            "command": ["wget", "-O", "/work-dir/index.html", "http://kubernetes.io/index.html"],
            "volumeMounts": [
                {
                    "name": "workdir",
                    "mountPath": "/work-dir"
                }
            ]
        }
    ]'
spec:
  containers:
  - name: frontend
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}
```

### Example: Delaying pod startup

One way we can solve the first example (waiting for a a caching service before starting our the application) is by creating an init container which runs and monitors for the caching Pod. Once the application's caching Pod is up and running the monitoring container exits and the main service begins running.

Application `yaml` file:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: frontend-label
  ports:
  - name: redis-svc-port
    port: 6379
  clusterIP: None
---
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: frontend-label
  annotations:
    pod.beta.kubernetes.io/init-containers: '[
        {
            "name": "index-page",
            "image": "busybox",
            "command": ["sh", "-c", "until ping redis-service -c 1; do sleep 3; done;"]
        }
    ]'
spec:
  containers:
  - name: app-container
    image: busybox
    command:
    - sleep
    - "3600"
    ports:
    - containerPort: 6379
      name: redis-pod-port
```

The above application container specifies an init container which continuously pings the `redis-service`; once it successfully reaches that service the init-container exists and the pod which depends on redis continues to be spun up.

You can test this by creating the writing the above into a file `app.yaml` and monitoring the startup process of the pod.

```
$ kubectl create -f app.yaml
service "app-service" created
pod "app-pod" created
$ kubectl get pods
NAME      READY     STATUS     RESTARTS   AGE
app-pod   0/1       Init:0/1   0          5m
```

Redis container:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis-label
  ports:
  - name: redis-svc-port
    port: 6379
  clusterIP: None
---
apiVersion: v1
kind: Pod
metadata:
  name: redis-pod
  labels:
    app: redis-label
spec:
  containers:
  - name: redis-container
    image: redis
    ports:
    - name: redis-pod-port
      containerPort: 6379
```

We can complete the exercise by copying the above into a file `redis.yaml` and begin create that service and pod.

```
$ kubectl create -f redis.yaml
service "redis-service" created
service "redis-pod" created
$ kubectl get pods
NAME        READY     STATUS              RESTARTS   AGE
app-pod     0/1       Init:0/1            0          6m
redis-pod   0/1       ContainerCreating   0          5s
$ kubectl get pods
NAME        READY     STATUS    RESTARTS   AGE
app-pod     1/1       Running   0          8m
redis-pod   1/1       Running   0          2m
```

As we can see once the `redis-service` was created the `app-pod` successfully completed the initialization and the pod was created.

[fleet-exec-pre]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[k8s-init-containers]: http://kubernetes.io/docs/user-guide/production-pods/#handling-initialization
[k8s-nit-containers-design]: https://github.com/kubernetes/community/blob/master/contributors/design-proposals/container-init.md
