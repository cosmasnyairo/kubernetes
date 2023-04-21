# Kubernetes

A list of Kubernetes templates and commands i use

## Table of Contents
- [Notes](#notes)
- [Scheduling](#scheduling)
  - [Manual Scheduling](#manual-scheduling)
  - [Labels](#labels-and-selectors)
  - [Taints and Tolerations](#taints-and-tolerations)

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

## Scheduling

### Manual scheduling
- Add the `nodeName` field when creating a pod only during creation time
- We can alternatively create a [pod-binding-file](definition-files/pod-binding.yaml) and send a post request to the pod's binding api with data section set to the binding object in a json format as follows: `curl --header "Content-Type:application/json" --request POST --data <<BINDING-OBJECT-YAML>> http://$SERVER/api/v1/namespaces/<namespace>/pods/$PODNAME/binding/`

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
   
```sh
  kubectl taint nodes my-node type=test:NoSchedule
```

```sh
  kubectl taint node my-node node-role=kubernetes.io/control-plane:NoSchedule-
```