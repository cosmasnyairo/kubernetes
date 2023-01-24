# Kubernetes

A list of Kubernetes templates and commands

## Table of Contents

- [Notes](#notes)
- [Pod](#pod)
- [Replication Controller and replicaset](#replication-controller-and-replicaset)
- [Deployments](#deployments)
- [Namespaces](#namespaces)
- [Services](#services)
- [Config Map](#config-map)
- [Secrets](#secrets)
- [Security Context](#security-context)
- [Service Account](#service-account)
- [Resource Limits](#resource-limits)
- [Taints and Tolerations](#taints-and-tolerations)
- [Node Selectors](#node-selectors)
- [Node Affinity](#node-affinity)
- [Multicontainer Pods](#multicontainer-pods)
- [Observability](#observability)
- [Jobs and Cronjobs](#jobs-and-cronjobs)
- [Ingress](#ingress)
- [Network Policies](#network-policies)
- [Storage](#storage)
- [Authentication](#authentication)
- [Authorization](#authorization)
- [Admission Controllers](#admission-controllers)
- [Custom Resource Definition](#custom-resource-definition)
- [Custom Controller](#custom-controller)


## Notes

---

- [ ] [Definition file](definition-files/definition.yaml)

Cluster is a collection of nodes

Master node has:

- api sever (frontend for kube)
- etcd (key store for data used to manage cluster)
- scheduler (assigns containers to nodes)
- controller (bring up containers when they go down)

Worked node has:

- kubelet (agent in each node in cluster that ensures containers running on nodes as expected)
- runtime (software to run containers in the background i.e docker)

Multi container pods can communicate to each other through localhost

Resources in a namespace can refer to each other by their names

```
pods have a 1 to 1 relationship with containers
entrypoint in docker -> command in kubernetes
cmd in docker -> args in kubernetes
kube system - resources for internal purposes for kubernetes
kube public - resources to be made available to all users
```

kubeapiserver path is `/etc/kubernetes/manifests/kube-apiserver.yaml`
To check settings passed to kubeapi server: `ps -aux | grep authorization`

To view api resources and their shortnames:

```
kubectl api-resources
```

To enable alpha versions: `--runtime-config=api/version`
To handle api deprecations:
```
kubectl convert -f <old-file> --output-version <new-api-version> > <new-file>
```

---

## Pod

---

Single instance of an application (smallest object we can create in k8)

We scale pods up or down

- [ ] [Pod Definition file](definition-files/deployment.yaml)

```console
kubectl get pods -o wide
```

```console
kubectl get pods -A
```

```console
kubectl label pod/<pod-name> <label>=<value>
```

```console
kubectl get pods,svc
```

```console
kubectl get pods --no-headers | wc -l
```

```console
kubectl run <pod-name> --image=<image-name>  -n <namespace> --dry-run=client -o yaml > test.yaml
```

```console
kubectl set image pod <pod-name> <container-name>=<image>
```

```console
kubectl get pod <pod-name> -o yaml > pod-definition.yaml
```

```console
kubectl exec -it podname -- commandtorun
```

```console
kubectl replace --force -f app.yaml
```

```console
kubectl apply -f test.yaml
```

```console
kubeclt edit pod <pod-name>
```

```console
kubectl explain pods --recursive | less
```

```console
kubectl explain pods --recursive | grep envFrom -A<number-of-lines>
```

- [ ] [Pod Design Definition file ](definition-files/labels-selectors-annotations.yaml)

- Pod labels - used to group objects i.e pods, services, replicasets

```console
kubectl get pods --selector label=value
```

```console
kubectl get pods --selector label=value,label2=value2
```

- Selectors match labels described i.e match labels on the pod or service to match labels of a pod

- Annotation records details for informatory purposes e.g build information, tool used.

---

## Replication Controller and Replicaset

---

```
Replication controller is in v1 while replicaset in apps/v1

Replica set uses selector to determine pods to watch and manage even existing pods

```

- [ ] [Replicaset Definition file ](definition-files/replicaset.yaml)
- [ ] [Replicationcontroller Definition file](definition-files/replicationcontroller.yaml)

```console
kubectl create -f definition.yaml
```

```console
kubectl get replicationcontroller
```

```console
kubectl get rs
```

```console
kubectl delete replicaset <replicaset-name>
```

```console
kubectl edit replicaset <replicaset-name>
```

```console
kubectl set image rs <replica-set> <container-name>=<image>

```

```console
kubectl describe replicaset <replicaset-name>
```

```console
kubectl apply -f definition.yaml
```

```console
kubectl replace -f definition.yaml
```

```console
kubectl scale -replicas=10 -f definition.yaml
```

```console
kubectl scale --replicas=0 replicaset/<replicaset-name>
```

---

## Deployments

---

- [ ] [Deployment Definition file ](definition-files/deployment.yaml)

```console
kubectl create deployment nginx --image=nginx
```

```console
kubectl scale deploy/webapp --replicas=3
```

```console
kubectl get deploy
```

```console
kubectl get deploy -o wide
```

```console
kubectl delete deployment <deployment -name>
```

```console
kubectl create deploy redis-deploy --image=redis --replicas=2 -n dev-ns
```

- Deployment strategies:
  - Recreate - Remove all applications running on older verision and bring up applications running on newer verision
  - Rolling update (default strategy) - Remove a single application and bring up a new one one by one until the newer version is running on all applications
  - A new replica set is created under the hood when we do deployment upgrades
  - We use record flag to save commands used to create/update deployments
  - We use the to revision flag to rollback to a specific revision

```console
kubectl set image deploy/deploymentname <container-name>=<image>
```

```console
kubectl set image deploy/deploymentname <container-name>=<image> --record
```

```console
kubectl rollout restart deploy/deploymentname
```

```console
kubectl rollout status deploy/deploymentname
```

```console
kubectl rollout history deploy/deploymentname
```

```console
kubectl rollout undo deploy/deploymentname
```

```console
kubectl rollout undo deploy/deploymentname --to-revision=1
```

---

## Namespaces

---

- [ ] [Namespace Definition file ](definition-files/namespace.yaml)
- [ ] [Resource Quota Definition file](definition-files/resourcequota.yaml)

```console
kubectl create ns <namespace-name>
```

```console
kubectl config set-context $(kubectl config current-context) -n <namespace-name>
```

---

## Services

---

Enable communication between components within the application

Types:

- Node Port
  - [ ] [Node Port Definition file ](definition-files/nodeport-service.yaml)
  - Map a port on node to a port on the pod
  - The node's port Can only be in the range 30000 to 32767
  - Node port -> Service -> Target port (Pod's port)
  - Node port and service port are not mandatory, if not provided, node port is allocated an available ip in the range 30000 to 32767 while service port is assumed to be same as port
  - Acts as loadbalancer if we have multiple pods with the same label, it uses a random algorithm to select which pod to send requests to.
- Cluster Ip

  - [ ] [Cluster Ip Definition file ](definition-files/clusterip-service.yaml)
  - Service assigned an ip in the cluster and it's used to access the service by other pods in the service.

- Load Balancer
  - Builds on top of node port and allows balancing of requests to the service to it's target applications

To connect to another service in a different namespace: we use the following syntax:

```
<service-name>.<namespace>.<svc>.<domain>
test-service.test-ns.svc.cluster.local

```

```console
kubectl expose resource <resource-name> --type=<type> --port=<port> --target-port=<target-port> --name=<service-name>
```

```console
kubectl create service <type> <service-name> --tcp=<port>:<port>
```

---

## Config Map

---

- [ ] [ConfigMap Definition file ](definition-files/configmap.yaml)
- [ ] [Pod with configMap Definition file](definition-files/configmap-pod.yaml)

- Imperative

  ```console

  kubectl create configmap \
      app-config --from-literal=APP_COLOR=RED \
                 --from-literal=APP_TYPE=AAB \
                 --from-literal=APP_ENV=PROD \
  ```

  ```console
  kubectl create configmap \
      app-config --from-file=app_config.properties
  ```

- Declarative:

  ```console
  kubectl create -f test-config-map.yaml
  ```

  ```console
  kubectl get configmaps
  kubectl get cm
  kubectl describe configmap
  ```

---

## Secrets

---

- [ ] [Secret Definition file ](definition-files/secret.yaml)
- [ ] [Pod with Secret Definition file](definition-files/secret-pod.yaml)

- Imperative

  ```console
  kubectl create secret generic \
      app-secret --from-literal=DB_HOST=mysql \
                 --from-literal=DB_PORT=1000
                 --from-literal=DB_NAME=test \
  ```

  ```console
  kubectl create secret generic \
      app-secret --from-file=test.env
  ```

- Declarative

  ```console
  kubectl create -f test-secret.yaml
  ```

  ```console
  kubectl get secrets
  ```

  ```console
  kubectl get secret <secret-name> -o yaml
  ```

  ```console
  kubectl describe secrets
  ```

---

## Security Context

---

- [ ] [Security Context Definition file ](definition-files/securitycontext.yaml)

We can add security context on the pod level or the container level. If both are specified, the container level takes precedence.

Cabapilites are supported only on the container level

---

## Service Account

---

- [ ] [Service Account Definition file ](definition-files/serviceaccount.yaml)

```console
kubectl create serviceaccount test-sa
```

```console
kubectl get serviceaccount
```

```console
kubectl describe serviceaccount test-sa
```

```console
kubectl create token SERVICEACCOUNTNAME
```

## Taints and Tolerations

---

- [ ] [Taints and Tolerations Definition file ](definition-files/taint%26toleration-pod.yaml)

<!-- To add the taint -->

```console
kubectl taint nodes NODENAME app=red:taint-effect
```

<!-- To remove the taint -->

```console
kubectl taint nodes NODENAME app=red:taint-effect-
```

taint-effects include: `NoSchedule|NoExecute|PreferNoSchedule`

---

## Node Selectors

---

- [ ] [Node Selectors Definition file ](definition-files/nodeselector-pod.yaml)

```console
kubectl label nodes NODENAME type=test
```

We cannot apply advanced filters e.g not , or

---

## Node Affinity

---

- [ ] [Node Affinity Definition file ](definition-files/nodeaffinity-pod.yaml)

Node affinity types:

- requiredDuringSchedulingIgnoredDuringExecution
- PreferredDuringSchedulingIgnoredDuringExecution
- requiredDuringSchedulingrequiredDuringExecution

|     | During Scheduling | During Execution |
| :-: | :---------------: | :--------------: |
|  1  |     Required      |     Ignored      |
|  2  |     Preferred     |     Ignored      |
|  3  |     Required      |     Required     |

---

## Multicontainer Pods

---

- [ ] [Multicontainer Pods Definition file ](definition-files/multicontainer.yaml)

- Sidecar containers -> help the main container e.g to logging agent to send logs to log server
- Adapter containers -> process data for the main container e.g converts logs to readable format before sending to logging server
- Ambassador containers -> proxy requests from the main container e.g send requests to db on main container's behalf

- [ ] [Init Containers Definition file ](definition-files/initcontainer.yaml)

- Init containers -> Process inside init container must finish before other containers start.
- If the init container fails, the pod is restarted until the init container succeeds

---

## Observability

---

Readiness Probe:

- Perform test to check if the container is up before marking the container as ready.
- For readiness, we can do http calls, tcp calls or run a command that when succesfull, we mark the container as ready

Liveness Probe:

- Periodically test if application within container is healthy.
- For liveness, we can do http calls, tcp calls or run a command that when they fail, we mark the container as unhealthy and it's restarted

- [ ] [Readiness & Liveness Probe Definition file ](definition-files/readiness-probe.yaml)

Logging:

Show logs

```console
kubectl logs podname
```

Show live logs

```console
kubectl logs -f podname
```

For multi container we specify container name

```console
kubectl logs -f podname container-name
```

Metric Server:

- We can have 1 metric server per cluster
- Receives metrics from nodes and pods and stores them in memory ( we can't see historical data with metric server)
- To install on cluster,we clone the metric server repo and run kubectl create -f repourl

```console
kubectl top node
```

```console
kubectl top pod
```

---

## Jobs and Cronjobs

Job - Tasks that can be run and exit after they've finalized

- [ ] [Job Definition file ](definition-files/job.yaml)

---

```console
kubectl get jobs
```

Cronjob - To run jobs periodically

- [ ] [Cronjob Definition file ](definition-files/cronjob.yaml)

```console
kubectl get cronjob
```

---

## Ingress

- [ ] [Ingress Definition file ](definition-files/ingress.yaml)

- Enables users access application through an externally accessible url that we can configure to route to different services in the cluster based on url path while implementing ssl as well
- We need to expose it so it can be accessible outside the cluster
- Ingress controller:

  - Does not come with kubernetes as default. We need to deploy if first.
  - Examples are istio, nginx, haproxy

- Ingress resources:
  - Rules and configs applied to ingress controller to forward traffic to single applications, via paths or via domain name

```console
kubectl get ingress
```

```console
kubectl create ingress <ingress-name> --rule="host/path=service-name:port"
```

## Network Policies

- Allow and deny rules configured on the pod
- [ ] [Network Policies Definition file ](definition-files/network-policy.yaml)

```console
kubectl get netpol
```

## Storage

- Volumes

  - [ ] [Volume Definition file ](definition-files/volume.yaml)

- Persistent Volumes

  - Cluster wide pool of storage volumes to be used by applications on the cluster
  - Applications can then request storage from the pool to use

  - [ ] [Persistent Volumes Definition file ](definition-files/persistent-volume.yaml)
  - [ ] [Persistent Volume in a Pod Definition file ](definition-files/persistent-volume-pod.yaml)

- Persistent Volume Claim

  - Users create persistent volume claims to use the storage in the persistent volume
  - Kubernetes binds pvc to pv based on request and properties on the volume

  - [ ] [Persistent Volume Claim Definition file ](definition-files/persitent-volume-claim.yaml)

  ```console
  kubeclt delete pvc <pvc-claim>
  ```

- Storage Class

  - We define a provisioner to automatically provision storaage which can be used by pods.
  - If we specify the storage class, we don't need to specify the persistent volume as it would be created automatically when storage class is created.

  - [ ] [Storage Class Definition file ](definition-files/storageclass.yaml)
  - [ ] [Persistent Volume Claim Storage Class Definition file ](definition-files/persistent-volume-claim-storageclass.yaml)

## Authentication

All user access is managed by the api server

We can store user credentials as:

- Static Password File:

  ```console
    # Add this to kubeapi server service or pod definition file
    --basic-auth-file=user-credentials.csv
  ```

  ```console
    curl -v -k <api-url> -u "user:password"
  ```

- Static Token File:

  ```console
   # Add this to kubeapi server service or pod definition file
   --token-auth-file=user-credentials.csv
  ```

  ```console
    curl -v -k <api-url> --header "Authorization: Bearer <TOKEN>"
  ```

We can use kubeconfig to manage which clusters we can access

- [ ] [Kubeconfig Definition file ](definition-files/kubeconfig.yaml)

```console
kubectl config view --kubeconfig=my-custom-file
```

```console
kubectl config use-context developer-development-playground
```

```
kubectl config get-context developer-development-playground
```

## Authorization

Authorization modes:

- Node authorizer -> handles node requests (user should have name prefixed system node)
- Attribute based authotization -> Assosiate users/group of users with a set of permissions(difficult to manage)
- Role bases access control -> We define roles and associate users with specific roles
- Webhook -> Outsource authorization to 3rd party tools
- AlwaysAllow -> Allows all requests without doing authorization checks (default)
- AlwaysDeny -> Denys all requests

On kubeapiserver, we specify modes to use `--authorization-mode=Node,RBAC,Webhook`

Role based access control:

- [ ] [Role Definition file ](definition-files/role.yaml)
- [ ] [Role Binding Definition file ](definition-files/role-binding.yaml)

```console
kubectl get roles
```

```console
kubectl create role test --verb=list,create --resource=pods
```

```console
kubectl describe role <role-name>
```

```console
kubectl get rolebindings
```

```console
kubectl create rolebinding test-rb --role=test --user=user1 --group=group1
```

```console
kubectl describe rolebindings <rolebindings-name>
```

```console
kubectl auth can-i create deploy
```

```console
kubectl auth can-i create deploy --as dev-user --namespace dev
```

```console
kubectl api-resources --namespaced=false
```

We can create roles scoped on clusters. We can also create cluster roles on namespace scoped resources

Cluster Role based access control:

- [ ] [Cluster Role Definition file ](definition-files/role.yaml)
- [ ] [Cluster Role Binding Definition file ](definition-files/role-binding.yaml)

```console
kubectl create clusterrole test --verb=* --resource=*
```

```console
kubectl create clusterrolebinding test-rb --clusterrole=test --user=user --group=group
```

## Admission Controllers

- Implement security measures to enforce how a cluster is used.
- It can validate, change or reject requests from users
- It can also perform operations in the backend

```console
kube-apiserver -h | grep enable-admission-plugins
```

On kubeapiserver, to enable an admission controller we update the `--enable-admission-plugins=NodeRestriction,NamespaceLifecycle`
On kubeapiserver, to disable an admission controller we update the `--disable-admission-plugins=DefaultStorageClass`

We can create custom admission contollers:

- We use the `Mutating and Validating` webhooks that we configure to a server hosting our admission webhook service.
  If a request is made, it goes sends an admission review object to admission webhook server that responds whith an admission review object of whether the result is allowed or not

- We then deploy our admission webhook server

- We then configure to reach out to the service and validate or mutate requests by creating a validating configuration object
  - [ ] [Validating Configuration Definition file ](definition-files/validating-configuration.yaml)

## Custom Resource Definition

An extension of the Kubernetes API that isn't available in the Kubernetes installation

- [ ] [Custom Resource Definition file ](definition-files/customresourcedefinition.yaml)


## Custom Controller

Process or code running in a loop and monitoring the kubernetes cluster and listening to events of specific objects

We build the custom controller then provide kubeconfig file the controller would need to authenticate to the kubernetes api