# Kubernetes

A list of Kubernetes templates and commands i use

## Table of Contents
- [Notes](#notes)
- [Scheduling](#scheduling)
  - [Manual Scheduling](#manual-scheduling)
  - [Labels](#labels-and-selectors)
  - [Taints and Tolerations](#taints-and-tolerations)
  - [Node Selector](#node-selector)
  - [Node affinity](#node-affinity)
  - [Resource Limits](#resource-limits)
  - [Daemon Sets](#daemon-sets)
  - [Static Pods](#static-pods)
  - [Multiple Schedulers](#multiple-schedulers)
  - [Scheduler Profiles](#scheduler-profiles) 
- [Logging and Monitoring](#monitoring-and-logging)
- [OS Upgrades](#os-upgrades)
- [Security](#security)
  - [Authentication](#authentication)
  - [TLS Certificates](#tls-certificates) 
  - [Kubeconfig](#kubeconfig)
  - [Authorization](#authorization)
  - [Network Policy](#network-policy)
- [Storage](#storage)
- [Networking](#networking)
  -[Network configuration - Cluster Nodes](#network-configuration---cluster-nodes)
  -[Pod Networking ](#pod-networking)
  -[Service Networking](#service-networking)
  -[DNS](#dns)
- [JSONPATH](#json-path)
## Notes

Commands for terminal in exam:

```sh
# in .bashrc
alias k="kubectl"
export drc="--dry-run=client -oyaml"
export drs="--dry-run=server -oyaml"
export kre="kubectl replace --force -f"
# in .vimrc
set expandtab
set tabstop=2
set shiftwidth=2
set nu
set autoindent
```

```sh
kubectl explain po.spec
```

- etcd - key store for information about the cluster i.e nodes, pods, roles, secrets
- kube-api sever - management component in kubernetes. Only component to interact with the etcd data store
- kube-controller-manager - manages contollers in kubernetes and brings the system to the desired state
- kube-scheduler - decides which pod goes to which node
- kubelet - registers nodes,  creates pods on a nodes, monitors the pods and nodes
- kube-proxy - creates forwarding rules for nodes in the cluster

```
If we install the cluster using kubeadmin, we can view :
  - Exec into the etcd pod and run the `etcdctl` command
  - Exec into the kube-apiserver pod and access the `/etc/kubernetes/manifests/kube-apiserver.yaml` file
  - Exec into the kube-controller manager pod and access the `/etc/kubernetes/manifests/kube-controller-manager.yaml` file
  - Exec into the kube-scheduler pod and access the `/etc/kubernetes/manifests/kube-scheduler.yaml` file
  - Kubeadmin doesn't deploy the kubelet, we have to do it manually
```

```
If we install the clustrer without using kubeadmin, we can view:
  - explore the etcd service
  - the apiserver service located at `/etc/systemd/system/kube-apiserver.service` or `ps -aux | grep kube-apiserver` on the master node.
  - the kubecontroller manager service located at `/etc/systemd/system/kube-controller-manager.service` or `ps -aux | grep kube-controller-manager` on the master node.
  - explore the kube-scheduler service or `ps -aux | grep kube-scheduler`
  - explore the kubelet service or `ps -aux | grep kubelet` 
```

- Kubelet config is at: `/var/lib/kubelet/config.yaml` for each node



- Test commands

```sh
kubectl run webapp-green --image=test --dry-run=server -oyaml
```

```sh
kubectl auth can-i
```

- To pass commands to pods on creation:
```sh
kubectl run webapp-green --image=test --command -- --color=green
```         
- To pass args to pods on creation:
 ```sh
 kubectl run webapp-green --image=test -- --color=green
 ```

Update env variables:
```sh
kubectl -n test set env deploy/test --containers=container-name DB_Host=mysql DB_User=user1 DB_Password=pass123
```

Check certificate:
```sh
openssl x509 -in /opt/cert.crt -text
```

Check service logs: 
```sh
journalctl -u service
```

```sh
service servicename status
```

Kubelet file located at: `var/lib/kubelet/config.yaml`
## Scheduling

### Manual scheduling
- Add the `nodeName` field when creating a pod only during creation time
- We can alternatively create a pod binding file as shown below:
```yaml
apiVersion: v1
kind: Binding
metadata:
  name: myapp
target:
  apiVersion: v1
  kind: Node 
  name: my-node
```
- Then, we send a post request to the pod's binding api with data section set to the binding object in a json format as follows: `curl --header "Content-Type:application/json" --request POST --data <<BINDING-OBJECT-YAML>> http://$SERVER/api/v1/namespaces/<namespace>/pods/$PODNAME/binding/`

### Labels and Selectors

- Annotations record other details in pod for informatory purposes

```sh
  kubectl get po --selector type=test
```

### Taints and Tolerations

- Restrict what pods can be scheduled on a node
- Taints set on nodes, tolerations set on pods
- Taint effect = what happens to pods that can't tolerate the taint
  - NoSchedule
  - PreferNoSchedule 
  - NoExecute

Taint and toleration example yaml shown below:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <<pod-name>>
spec:
  containers:
    - name: nginx-container
      image: nginx
  tolerations:
    - key: "type"
      value: "test"
      operator: "Equal"
      effect: "NoSchedule"
```
   
```sh
  kubectl taint nodes my-node type=test:NoSchedule
```

```sh
  kubectl taint node my-node node-role=kubernetes.io/control-plane:NoSchedule-
```

### Node Selector 
- Add node selector section in the pod with the label of the node we want to use as shown below:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: myapp
spec:
  containers:
  - name: myapp
    image: busybox
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
      - containerPort: 80
  nodeSelector:
    type: large
```
   
```sh
  kubectl label nodes my-node type=test
```

### Node affinity

Node affinity example below:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <<pod-name>>
  labels:
    app: <<label-value>>
    type: <<label-value>>
spec:
  containers:
    - name: nginx-container
      image: nginx
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: type
                operator: Exists
          # - matchExpressions:
          #     - key: type
          #       operator: In
          #       values:
          #         - test
```

Node affinity types:

- requiredDuringSchedulingIgnoredDuringExecution
- PreferredDuringSchedulingIgnoredDuringExecution
- requiredDuringSchedulingrequiredDuringExecution

|     | During Scheduling | During Execution |
| :-: | :---------------: | :--------------: |
|  1  |     Required      |     Ignored      |
|  2  |     Preferred     |     Ignored      |
|  3  |     Required      |     Required     |

We can combine node affinity with taints and tolerations

### Resource Limits

We can create limit ranges which need to be followed by pods in a namespace as shown below:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-limit-range
spec:
  limits:
    - default:
        cpu: 1
      defaultRequest:
        cpu: 0.5
      type: Container
---
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
    - default:
        memory: 512Mi
      defaultRequest:
        memory: 256Mi
      type: Container
---
```

### Daemon Sets
Ensures a copy of a pod is always on each node in the cluster. Use case: Logging, monitoring agents as shown below:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: mydaemonset
spec:
  selector:
    matchLabels:
      app: mydaemonset-app
  template:
    metadata:
      labels:
        app: mydaemonset-app
    spec:
      containers:
      - name: myapp
        image: logviewer
```

### Static Pods
Pods created independently by the kubelet without help from the kubeapiserver.
We can do this in the following ways:
  - find the kubelet service config path:
    ```sh
    ps -aux | grep -i kubelet | grep -i config
    ```
  - check the node's `/var/lib/kubelet/config.yaml` path
  - Configure the pod definition path in the kubelet service at with the following entry: `--pod-manifest-path=etc/kubernetes/manifests` 
  - Provide a `--config=mydefinition.yaml` entry in the kubelet service and have the `mydefinition.yaml` file contain the following:  
    ```yaml
      staticPodPath: etc/kubernetes/manifests
    ```
  - For both approaches we then place the pod definition files at the specified directory in our case it's `/etc/kubernetes/manifests` and view pods created via the `docker ps` command

We can use static pods to deploy control plane components as static pods.

### Multiple Schedulers

We can create our custom scheduler in kubernetes then pass the file to the custom scheduler in this format:
` --config=/etc/kubenetes/my-scheduler/my-scheduler-conf.yaml`. 

The `my-scheduler-conf.yaml` file contains the following:

```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta2
kind: KubeSchedulerConfiguration
profiles:
  - schedulerName: my-scheduler
leaderElection:
  leaderElect: true
  resourceNamespace: kube-system
  resourceName: lock-object-my-scheduler
```

The leaderelection section is used when we have multiple master nodes with the custom scheduler running on them in a HA(High Availability) setup and we need to chose the active copy of the scheduler to be running at a time.

Read more at: [Multiple Schedulers](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/)

For pods to use our custom scheduler, we provide the scheduler name field in the pod definition.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  labels:
    name: myapp
spec:
  containers:
  - name: myapp
    image: busybox
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
      - containerPort: 2000
  schedulerName: my-custom-scheduler
```

### Scheduler Profiles
We can disable existing scheduler plugins as well as enable our own custom plugins as below

```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta2
kind: KubeSchedulerConfiguration
profiles:
  - schedulerName: my-scheduler
    plugins:
      filter:
        disabled:
          - name: TaintToleration
        enabled:
          - name: MyCustomPlugin
  - schedulerName: my-scheduler-two
    plugins:
      score:
        disabled:
          - name: 'NodeAffinity'
          - name: 'ImageLocality'  
```

## Monitoring and Logging

We can use the metric server from: [metrics-server](https://github.com/kubernetes-sigs/metrics-server) to collect metrics about our cluster performance. We can also used advanced tools for out monitoring i.e prometheus using this [guide](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/#:~:text=Prometheus%20is%20a%20high%2Dscalable,helps%20with%20metrics%20and%20alerts.)

We can then view performance using
```sh
kubectl top node
```

```sh
kubectl top pods
```

To get streamed logs of a currently running pod we use 

```sh
kubectl logs pod-name -f
```

To get streamed logs of a currently running pod with multiple containers we use 
```sh
kubectl logs pod-name -c container-name -f
```

## Os Upgrades
- We can drain a node to remove the pods currently running on it and then the node is cordoned (marked as unschedulable)
```sh
kubectl drain node1
```
- We can also manually cordon a node
```sh
kubectl cordon node1
```
- After our upgrade/fixes to the node, we then uncordon the node once it's back up
```sh
kubectl uncordon node1
```
- We can have the different components with different versions but not a higher version than the kube api-server but kubectl can be one version higher or lower or the same version

| Component   | Maximum version
| :---------:  | :---------: |
| Kube Api Server | x | 
| Controller Manager | x-1 | 
| Kube Scheduler | x-1 | 
| Kubectl | x-1 or x or x+1|
| Kubelet | x-2 | 
| Kube-Proxy | x-2| 

- To upgrade a cluster managed by kubeadm, 
  - we first start with the master node then the worker nodes.
  - We first get the upgrade plan for our version, 

Step 1 (master node):

```sh
kubeadm upgrade plan
```
```sh
apt-get upgrade kubeadm=<version> -y
```
```sh
kubeadm version
```
```sh
kubeadm upgrade apply <version>
```

If we have kubelets on the master node: 
```sh
apt-get upgrade kubelet=<version> -y
```
```sh
systemctl restart kubelet
```

Step 2 (worker node-> one by one):

```sh
kubectl drain node01 # on master node
```
```sh
apt-get upgrade kubeadm=<version> -y
```
```sh
apt-get upgrade kubelet=<version> -y
```
```sh
systemctl restart kubelet   
```
```sh
kubectl uncordon node01  # on master node
```

Backup candidates : Resource configurations, etcd

- For resource configurations:
  ```sh
  kubectl get all --all-namespaces -o yaml > deploy-and-service.yaml
  ```
- For Etcd, 
  We can either backup the directory where etcd stores to or take a snapshot and restore it 

  ```sh
  export ETCDCTL_API=3 
  ```
  ```sh
  etcdctl snapshot save --endpoints=<enpoints> \
                        --cacert=<path-to-cacert> \
                        --cert=<path-to-cert> \
                        --key=<path-to-key>
                        /path/to/backup/file/mysnapshot.db
  ```
  ```sh
  etcdctl snapshot status /path/to/backup/file/mysnapshot.db
  ```
  ```sh
  service kube-api-server stop
  ```
  ```sh
  etcdctl snapshot restore /path/to/backup/file/mysnapshot.db --data-dir /path/to/restore/to/
  # We then update etcd configuration to use the new directory 
  ```
  ```sh
  service etcd restart
  service kube-api-server start
  ```

We can use scp to copy objects to a pod:
```sh
scp test.txt my-server:/home
```
```sh
scp my-server:/home test.txt 
```

To join cluster:
```sh
kubeadm token create --print-join-command
```

More info: [Disaster Recovery for Kubernetes Clusters](https://www.youtube.com/watch?v=qRPNuT080Hk&ab_channel=CNCF%5BCloudNativeComputingFoundation%5D)

## Security

### Authentication
Authentication to the kube-api server is through:
- Password file:
  - Specify in kubeapiserver service or kubeapi server yaml file `--basic-auth-file=usercreds-basic.csv`
  - The csv file should be in the fomat of:
    ```csv
    password,username,userid,groupid
    ```
  - If using api to authenticate pass via `curl -v -k https://masternod-ip:port/api/vi/pods -u "user1:password1"`
- Token file:
  - Specify in kubeapiserver service or kubeapi server yaml file `--token-auth-file=usercreds-token.csv`
  - The csv file should be in the fomat of:
    ```csv
    token,username,userid,groupid
    ```
  - If using api to authenticate pass as a bearer token `curl -v -k https://masternod-ip:port/api/vi/pods --header "Authorization: Bearer <TOKEN>"`
- Certificates
- External Identity Service

### TLS Certificates

> Cerificates with public key usually end with `.crt` or `.pem` while those with private keys usually end with `.key` or `-key.pem`

List of certificates in the cluster
- Certificate Authority certs (we can use more than one ca)
- Server certificates:
  - kube-api-server 
  - etcd server
  - kubelet server
- Client certificates:
  - users (admins)
  - kube-scheduler
  - kube-controller-manager
  - kube-proxy
  - kube-api-server to kubelet
  - kube-api-server to etcd

All certificate operations done by the kube controller manager. We specify the following:
  ```sh
    - --cluster-signing-cert-file='pathtofile'
    - --cluster-signing-key-file='pathtofile' 
  ```

Certificate signing requests using the following file:

```
cat file.csr | base64 -w 0
```

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: johndoe
spec:
  request: BASE64 ENCODED CSR
  signerName: kubernetes.io/kube-apiserver-client
  groups: 
    - system:authenticated
  expirationSeconds: 86400  # one day
  usages:
  - server auth
  - key encryptment
```

```sh
kubectl get csr
```
```sh
kubectl certificate approve csr-name
```
```sh
kubectl certificate deny csr-name
```
```sh
kubectl get csr csr-name -o yaml
```

### Kubeconfig

We can send request using kubectl command without kubeconfig as follows:
```sh
kubectl get pods --server server --client-key client.key --client-certificate client.crt --certificate-authority ca.crt
```

We can use a kubeconfig file to remove the need to add the details and send a request like:
```sh
kubectl get pods
```

Kubeconfig file has these sections:
- Clusters (dev,prod)
- Users (developer, admin, qa)
- Contexts (user-to-cluster i.e developer@dev, admin@prod)

Sample kubeconfig file:
```yaml
apiVersion: v1
kind: Config
current-context: developer@localcluster-context 
clusters:
- name: remotecluster
  cluster:
    certificate-authority: path/remote-ca.crt
    server: https://ip:port
- name: localcluster
  cluster:
    certificate-authority-data: BASE64 ENCODED CSR
    server: https://ip:port
contexts:
- name: kube-admin@localcluster-context 
  context:
    cluster: remotecluster
    user: kube-admin
    namespace: kube-system
- name: developer@localcluster-context 
  context:
    cluster: localcluster
    user: developer
users:
- name: kube-admin
  user:
    client-certificate: path/admin-client.crt
    client-key: path/client.key
- name: developer
  user:
    client-certificate: path/dev-client.crt
    client-key: path/client.key
```

```sh
kubectl config view 
kubectl config view --kubeconfig path-to-config
```

```sh
kubectl cluster-info --kubeconfig path-to-config
```

```sh
kubectl config use-context developer@localcluster-context 
``` 
```
kubectl config set-credentials user --client-certificate=/path/user.crt
```
  
### Authorization

We set authorization mode in the kubeapiserver entry `--authorization-mode=Node,RBAC` and they are used following the order they were specified

Role file:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "watch", "list"]
    resourceNames:
      - "devhour"
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]

```
Role binding file:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: developer # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

```sh
kubectl get roles 
kubectl get rolebindings
```

```sh
kubectl auth can-i get pods
```

```sh
kubectl auth can-i get pods --as developer --namespace dev
```

```sh
kubectl create role rolename --verb=create,list,delete --resource=pod                 
```   

```sh
kubectl create rolebinding rolebindingname --role=rolename --user=user-to-bind
```

To view namespaced resources: ` --namespaced=true`
We can use cluster roles on namespaced resources to give access to the objects in the whole cluster

Cluster Role file:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "watch", "list"]
```

Cluster Role binding file:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-binding
subjects:
- kind: Group
  name: admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole #this must be Role or ClusterRole
  name: cluster-admin # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io 
```


```sh
kubectl create clusterrole clusterrolerolename --verb=* --resource=pod
```   
        
```sh
kubectl create clusterrolebinding clusterrolebindingname --clusterrole=clusterrolerolename --user=user-to-bind
```

For service accounts:
```sh
kubectl create sa service-account-name`
```

```sh
kubectl create token service-account-name
```

For registry secrets:

```sh 
 kubectl create secret docker-registry NAME --docker-username=user --docker-password=password --docker-email=email --docker-server=string
```

### Network Policy

By default kubernetes allows traffic from all pods to all destinations. 
We can define egress and ingress rules to block traffic to and from pods.

> If we add ingress rule, we don't need to specify the egress rule for the response as it is allowed automatically. 
> We do need an egress rule if we need to send external api calls


```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: network-policy-name
spec:
  podSelector:
    matchLabels:
      test: testing # pods matching this label will have the network policy applied on them
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        # The pod selector and namespace selector rules both need to be met.
        # We can add a - before the namespace selector to make it that either of them need to be met.
        - podSelector:
            matchLabels:
              name: pod-name # allow pods with this label to send ingress traffic
          namespaceSelector:
            matchLabels:
              name: testing # specify pods from which namespace are allowed to to send ingress traffic
        - ipBlock:
            cidr: ip-cidr  # range of ip addresses allowed to send ingress traffic
        ports:
          - protocol: "TCP"
            port: 3306 # port to recieve ingress traffic
  egress:
      - to:
          - podSelector:
              matchLabels:
                name: pod-name  # send egress traffic to pods with this label 
            namespaceSelector:
              matchLabels:
                name: testing # send egress traffic to pods in the namespace with this label
          - ipBlock:
            cidr: ip-cidr  # send egress traffic to this range of ip addresses
          ports:
            - protocol: "TCP"
              port: 80 # port to send egress traffic to
```

## Storage

To create a volume in a pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <<pod-name>>
  labels:
    app: <<label-value>>
    type: <<label-value>>
spec:
  containers:
    - name: nginx-container
      image: nginx
      volumeMounts:
        - mountPath: /opt
          name: test-volume
        - mountPath: /home/
          name: ebs-volume
  volumes:
    - name: test-volume
      hostPath:
        path: /home/data
        type: Directory
    - name: ebs-volume
      awsElasticBlockStore:
        volumeID: <<vol-id>>
        fsType: "ntfs"
```

Persistent Volumes: A cluster wide pool of storage volumes which we can assign to applications on the cluster.
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: persistent-vol
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  awsElasticBlockStore:
    volumeID: <<vol-id>>
    fsType: "ntfs"
```
Persistent Volumes Claim: Select storage from the persistent volumes created.
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: persitent-vol-claim
spec:
  resources:
    requests:
      storage: 500Mi
  accessModes:
    - ReadWriteOnce
```

Using Persistent Volumes Claim in a pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <<pod-name>>
  labels:
    app: <<label-value>>
    type: <<label-value>>
spec:
  containers:
    - name: nginx-container
      image: nginx
      volumeMounts:
        - mountPath: /opt
          name: pvc-volume
  volumes:
    - name: pvc-volume
      persistentVolumeClaim:
        claimName: persitent-vol-claim
```

Storage Classes: We don't need to creat a persitent volume. This is done automatically

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4
  encrypted: true
```
Persitent volume storage class:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: persitent-vol-claim
spec:
  resources:
    requests:
      storage: 500Mi
  storageClassName: ebs-storage
  accessModes:
    - ReadWriteOnce
```

## Networking


### Network configuration - Cluster Nodes
Ports required for kubernetes: [Ports](https://kubernetes.io/docs/reference/networking/ports-and-protocols/)

Find network interfaces:
```sh
ip a
```

Find bridges in network:
```sh
ip a show type bridge
```

List routes in the host
```sh
ip route
```
Get active internet connections
```sh
netstat -nplt
```

Get number of client connections on a program running on a port
```sh
netstat -anp | grep 'etcd\|2379' | wc -l
```


### Pod Networking 

When a container is created, the kubelet looks at the cni configuration passed: 
 - `network-plugin=cni`
 - `cni-conf-dir=/etc/cni/net.d` to find our scipts name 
 - `cni-bin-dir=/opt/cni/bin` to find the script 
  
The kubelet then runs the script with the add command with the name and namespce id of the container  `net-script.sh add <container> <namespace>`


### Service Networking

- Cluster Ip services are not bound to a specific node but are available to all pods cluster wide
- Node Port services exposes application on a port on all nodes in the cluster.

Kube proxy creates forward rules in all nodes such that when we try to reach the ip of a service, the request is forwarded to the ip and port of the pod.

For kubeproxy, we set the proxymode : `--proxy-mode [userspace | iptables | ipvs]` If not set, if defaults to iptables.

For services, we set the range in the kube-api-server `--service-cluster-ip-range <range>` which defaults to 10.0.0.0/24


View rules created by kube proxy
```sh 
iptables -L -t nat | grep -i servicename
```

### DNS

- Domain resolution for services: `web-service.namespace.svc.cluster-root-domain` i.e db-service.test-ns.svc.cluster.local
- For pods , we replace the `.` with `-`. This is turned off by default.
- Domain resolution for pods: `pod-ip-replaced-with-hyphens.namespace.pod.cluster-root-domain` i.e 10-244-1-2.test-ns.pod.cluster.local
- Coredns watches the cluster for new pods or services and adds a record for them in it's database when they're created and it also creates a service named `kube-dns`.
- Core file for coredns at : `etc/coredns/Corefile` and it's passed as a config map object
- For kubelet, we have the ip of dns server and domain in its config


Example Corefile
```
{
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

To get the service full domain name:                
```sh
host service-name
```


## Json Path

Kubernetes docs for json path: [Kubernetes Jsonpath](https://kubernetes.io/docs/reference/kubectl/jsonpath/)
Use the following evaluator for json [JsonPath Evaluator](https://jsonpath.com/)

```sh
#get field names
k explain deploy.spec --recursive 
```

```sh
# Get all car names in an json data is equal to "abc"
# $[] -> return a list
# ?() -> if 
# @ -> Each item in list

$[?(@.name == "abc")]
```

```sh
#Get name and image of first container of the first pod 
kubectl get pods -o=jsonpath='{range .items[0].spec.containers[0]}{.name}{"\n"}{.image}' --sort-by=.name
```


```sh
#Fetch node names 
kubectl get nodes -ojsonpath='{range .items[*].metadata}{.name}
```

```sh
# Sort persisten volumes by capacity
kubectl get pv --sort-by=.spec.capacity.storage
```

kubectl get pv --sort-by=.spec.capacity.storage -o=custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage 
```sh
```

```sh 
# get names of user test in config
kubectl config view --kubeconfig=custom-config -o jsonpath="{.contexts[?(@.context.user=='test')].name}"
```

```sh
#Get deployments as per this format:
# DEPLOYMENT   CONTAINER_IMAGE   READY_REPLICAS   NAMESPACE

kubectl get deploy -n admin2406 --sort-by=.metadata.name -o=custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers.*.image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace
```

```sh
kubectl get svc --sort-by=.metadata.name  -o=custom-columns=NAME:.metadata.name,PORTNAME:.spec.ports.name 
```

```sh
k get nodes -ojsonpath='{range .items[*]}InternalIP of {.metadata.name} {.status.addresses[?(@.type=="InternalIP")].address} {end}'
```