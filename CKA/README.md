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

## Notes
- etcd - key store for information about the cluster i.e nodes, pods, roles, secrets
- kube-api sever - management component in kubernetes. Only component to interact with the etcd data store
- kube-controller-manager - manages contollers in kubernetes and brings the system to the desired state
- kube-scheduler - decides which pod goes to which node
- kubelet - registers nodes,  creates pods on a nodes, monitors the pods and nodes
- kube-proxy - 

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

- To pass commands to pods on creation:
```sh
kubectl run webapp-green --image=test --command -- --color=green
```
- To pass args to pods on creation:
 ```sh
 kubectl run webapp-green --image=test -- --color=green
 ```

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