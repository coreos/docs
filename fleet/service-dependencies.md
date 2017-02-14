# Service startup dependencies

Services often depend on other services, and must start in a certain order. For example, an application that depends on a caching system should start after the cache. fleet and Kubernetes express such dependencies in different ways, but achive the same effect of controlling the order in which applications are executed.

## fleet: ExecStartPre

Fleet uses the systemd `ExecStartPre` `[Service]` directive [to ensure a command is run before a service starts][fleet-exec-pre], and the `Requires` `[Unit]` directive to ensure a dependency unit is running before a unit starts.

For instance, one might create a unit file `myapp.service`:

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

This unit depends on `docker.sevice`, and before starting, the application does some housekeeping work with the three `ExecStartPre` commands which kill, remove, and pull the application's container.

## Kubernetes: init containers

[Kubernetes init containers][k8s-init-containers] operate in a similar way to the `ExecStartPre` directive in that they:

* Run before a specified Pod.
* Run to completion before the next init container.
* All run to completion before the specified Pod.

The feature is currently a beta feature of Kubernetes v1.5.x, and must be specified in the `.metadata.annotations` of a Kubernetes manifest file.

### Example: init container fetching data

This example uses an init container to download some data for use in a container. The init container fetches the Kubernetes home page so that the nginx container can serve it:

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


One way to wait for a caching service before starting a primary application is by creating an init container to ping the caching Pod. Once the caching Pod is up and running, the cache checking container exits and the main Pod starts.

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

The above application container specifies an init container which continuously pings the `redis-service`. Once it successfully reaches that service, the init-container exists and the pod that depends on redis can continue.

You can test this by writing the above into a file `app.yaml` and monitoring the startup process of the pod.

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

We can complete the exercise by copying the above into a file `redis.yaml` and create that service and pod:

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

Once the `redis-service` was created, the `app-pod` successfully completed initialization and the pod was created.


[fleet-exec-pre]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[k8s-init-containers]: https://kubernetes.io/docs/concepts/abstractions/init-containers/
