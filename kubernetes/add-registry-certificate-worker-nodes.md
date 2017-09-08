# Adding Registry Certificate to Kubernetes Worker Nodes 

Many enterprise's use self-signed certificates to protect container registries. On k8s this can present a problem as docker requires that self-signed certificates be nested under the `/etc/docker/certs.d` on every host that will pull from a registry with a self-signed certificate. 

This restriction can be solved with a DaemonSet that copies the `ca.crt` file to the needed directory on each host. 

A secret will be mounted into the DaemonSet as a file and then copied. This secret must include the base64 encoded contents of the root CA (pem format) used to sign the container registry certs.

```bash
$ cat rootCA.pem | base64 -w 0
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURWekNDQWorZ0F3SUJBZ0lKQUxRd3FGRWVpakdyTUEwR0NTcUdTSWIzRFFFQkN3VUFNRUl4Q3pBSkJnTlYKQkFZVEFsaFlNUlV3[...]
```


#### registry-secret.yaml 

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-ca
  namespace: kube-system
type: Opaque
data:
  registry-ca: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURWekNDQWorZ0F3SUJBZ0lKQUxRd3FGRWVpakdyTUEwR0NTcUdTSWIzRFFFQkN3VUFNRUl4Q3pBSkJnTlYKQkFZVEFsaFlNUlV3[...]
```

Use kubectl to create the `registry-ca` secret: 

```
kubectl create -f registry-secret.yaml 
```

The following DaemonSet mounts the CA as the file `/home/core/registry-ca` and then copies this file to the `/etc/docker/certs.d/reg.example.com/ca.crt`. 

Replace `reg.example.com` with the hostname of your container registry. 

NOTE: This is a privileged container as the hostPath volume type requires for write privileges. 

#### registry-ca-ds.yaml 

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: registry-ca
  namespace: kube-system
  labels:
    k8s-app: registry-ca
spec:
  template:
    metadata:
      labels:
        name: registry-ca
    spec:
      containers:
      - name: registry-ca
        image: fedora
        securityContext:
          privileged: true
        command: [ 'bash' ]
        args: [ '-c', 'cp /home/core/registry-ca /etc/docker/certs.d/reg.example.com/ca.crt && sleep 500' ]
        volumeMounts:
        - name: etc-docker
          mountPath: /etc/docker/certs.d/reg.example.com
          readOnly: false
        - name: ca-cert
          mountPath: /home/core
      terminationGracePeriodSeconds: 30
      volumes:
      - name: etc-docker
        hostPath:
          path: /etc/docker/certs.d/reg.example.com
      - name: ca-cert
        secret:
          secretName: registry-ca
```

Use kubectl to create the `registry-ca` DaemonSet: 

```
kubectl create -f registry-ca-ds.yaml
```

Checking for success can be accomplished by deploying a Pod or DaemonSet that pulls from the container registry. 

As DaemonSets must have RestartPolicy equal to Always the registry-ca DaemonSet should be removed after succes:

```
kubectl -n kube-system delete ds registry-ca
```