# Certified Kubernetes Security Certification

Table of Contents:

- [notes](#notes)
- [verify packages](#verify-packages)
- [certificates](#certificates)
- [etcd](#etcd)
  - [encrypt etcd data at rest](#encrypt-etcd-data-at-rest)
- [kube-apiserver](#kube-apiserver)
  - [authentication](#authentication)
  - [authorization](#authorization)
- [auditing](#auditing)
- [kubelet](#kubelet)
- [service accounts](#service-accounts)
  - [service account security](#service-account-security)
- [pod/container security](#podcontainer-security)
  - [security context](#security-context)
  - [linux capabilities](#linux-capabilities)
- [admission controllers](#admission-controllers)
  - [alwayspullimages admission controllers](#alwayspullimages-admission-controller)
  - [pod security admission controllers](#pod-security-admission-controller)
  - [imagepolicywebhook admission controllers](#imagepolicywebhook-admission-controller)
- [system hardening](#system-hardening)
- [cluster and container scanning](#cluster-and-container-scanning)
  - [trivy](#trivy)
  - [kube-bench](#kube-bench)
  - [sbom](#sbom)
- [runtime security](#runtime-security)
  - [falco](#falco)
- [kubeadm](#kubeadm)
- [cilium](#cilium)
- [further reading](#further-reading)

## notes

> Notes: Following are common commands i use:

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
# Networking
tcpdump -i lo -X port 2379 # etcd dump

netstat -ntlp

scp <file> host:<path>
```

```sh
# Kubernetes Context: 
# get context name only
k config get-contexts -o name

# get client certificate for user 'kind-kind' decoded

k config view --raw -o jsonpath="{.users[?(.name == 'kind-kind')].user.client-certificate-data}" | base64 -d | openssl x509 -text -noout

# set context for testuser:
k config set-cluster cks-lab --server=https://127.0.0.1:6443 --certificate-authority="/opt/cks/certs/cert-authority.crt" --embed-certs

k config set-credentials cks-test-user --client-certificate=/opt/cks/certs/testUser.crt --client-key=/opt/cks/certs/testUser.key
  
k config set-context cks-lab-ctx --cluster=cks-lab --user=cks-test-user

k config use-context cks-lab-ctx
```

## verify packages

We can verify packages have not been modified during transit/where they were stored, before we use them, either on the cluster, nodes or local machines, we can verify the checksum of the files.

Most sites provide the checksum to verify before downloads.

Example, downloading cilium below:

```sh
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/v0.18.4/cilium-linux-amd64.tar.gz{,.sha256sum}
```

We can then verify the packages via:

```sh
# cat <package.sha> | sha256sum --check
cat cilium-linux-amd64.tar.gz.sha256sum | sha256sum --check

# or 

# echo "<sha-value> package>" | sha256sum --check
echo $(cat cilium-linux-amd64.tar.gz.sha256sum | cut -d " " -f -1 ) cilium-linux-amd64.tar.gz | sha256sum --check

# or 

# manual verify with below commands to get the sha:
# sha512sum <package> or sha256sum <package>
sha256sum cilium-linux-amd64.tar.gz

```

> Kubelet  
> If we installed the cluster manually, the kubelet service is not updated automatically if we change the service type a restart is required.

## certificates

We generate below certificates for the cluster using the script at [cert-generator](scripts/cert.sh):

certificate authority certificate:

`generateCACert cert-authority config/cert-authority.cnf`

etcd certificate:

`generateCert etcd config/etcd.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true`

client certificate:

`generateCert k8sClient config/k8sClient.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key false`

kube-apiserver-etcd certificate:

`generateCert kube-apiserver-etcd config/kube-apiserver-etcd.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key false`

kube-apiserver certificate:

`generateCert kube-apiserver config/kube-apiserver.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true`

service account certificate:

`generateCert service-account config/service-account.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key true`

## etcd

> etcd stores data under `/registry/{type}/{namespace}/{name}`

```sh

etcd --cert-file=/opt/cks/certs/etcd.crt \
     --key-file=/opt/cks/certs/etcd.key \
     --trusted-ca-file=/opt/cks/certs/cert-authority.crt \
     --client-cert-auth \
     --listen-client-urls https://localhost:2379 \ 
     --advertise-client-urls https://localhost:2379 \
     --data-dir=/var/lib/etcd
```

etcd get a key

```sh
etcdctl --endpoints=https://127.0.0.1:2379 \ 
        --cacert=/opt/cks/certs/cert-authority.crt \
        --cert=/opt/cks/certs/k8sClient.crt \ 
        --key=/opt/cks/certs/k8sClient.key get key3
```

etcd set a key

```sh
etcdctl --endpoints=https://127.0.0.1:2379 \ 
        --cacert=/opt/cks/certs/cert-authority.crt \
        --cert=/opt/cks/certs/k8sClient.crt \ 
        --key=/opt/cks/certs/k8sClient.key put key3 "test3"
```

create an etcd service file to manage the service using systemctl: [etcd.service](services/etcd.service)

```sh
systemctl start etcd
systemctl status etcd
journalctl -u etcd.service -f -n 10
```

### encrypt etcd data at rest

by default, we use identity provider at default that doesn't encrypt secrets

check if secrets are encrypted (we already created a test secret):

```sh
etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/opt/cks/certs/cert-authority.crt --cert=/opt/cks/certs/k8sClient.crt --key=/opt/cks/certs/k8sClient.key get /registry/secrets/default/test
```

generate encryption key and config for aescbc encryption and move it to `/var/lib/kubernetes/encyption.yaml`

```sh
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

echo $ENCRYPTION_KEY

cat > /opt/cks/auth/encyption.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# move file
mv /opt/cks/auth/encyption.yaml /var/lib/kubernetes/encyption.yaml
```

> add to kube-apiserver `--encryption-provider-config=/var/lib/kubernetes/encyption.yaml`

verify the encryption for new secrets

```sh
k create secret generic test2 --from-env-file=test.env

etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/opt/cks/certs/cert-authority.crt --cert=/opt/cks/certs/k8sClient.crt --key=/opt/cks/certs/k8sClient.key get /registry/secrets/default/test2 | hexdump -C

# output below shows provider used
/registry/secrets/default/test2
k8s:enc:aescbc:v1:key1:
```

This will encrypt the newly created secrets. To encrypt already existing secrets:

```sh
k get secrets --all-namespaces -o json | k replace -f -

etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/opt/cks/certs/cert-authority.crt --cert=/opt/cks/certs/k8sClient.crt --key=/opt/cks/certs/k8sClient.key get /registry/secrets/default/test | hexdump -C
```

## kube-apiserver

```sh
kube-apiserver --advertise-address='ip' \
               --service-cluster-ip-range 10.0.0.0/24 \
               --service-account-issuer=https://127.0.0.1:6443 \
               --service-account-key-file=/opt/cks/certs/service-account.crt \
               --service-account-signing-key-file=/opt/cks/certs/service-account.key \
               --etcd-cafile=/opt/cks/certs/cert-authority.crt \
               --etcd-certfile=/opt/cks/certs/kube-apiserver-etcd.crt \
               --etcd-keyfile=/opt/cks/certs/kube-apiserver-etcd.key \
               --etcd-servers=https://127.0.0.1:2379 \
               --tls-cert-file=/opt/cks/certs/kube-apiserver.crt \
               --tls-private-key-file=/opt/cks/certs/kube-apiserver.key
```

create an kube-apiserver service file to manage the service using systemctl: [kube-apiserver.service](services/kube-apiserver.service)

```sh
systemctl start kube-apiserver
systemctl status kube-apiserver
journalctl -u kube-apiserver.service -f -n 10
```

### authentication

Let's review below authentication possibilities to the kube-apiserver:

- token based
- certificate based

#### token based authentication

> add to kube-apiserver `--token-auth-file="auth.csv"`

format of auth file:

`##token,user,uid,"group1,group2"`

Authenticate to kube-apiserver and interact with it:

```sh
curl -k --header "Authorization: Bearer $password" https://localhost:6443

k create secret generic test --from-env-file=test.env --server=https://localhost:6443 --token $password --insecure-skip-tls-verify 

k get secret test --server=https://localhost:6443 --token $password --insecure-skip-tls-verify

```

#### cert based auth

> add to kube-apiserver `--client-ca-file /opt/cks/certs/cert-authority.crt`

create user cert:

`generateCert testUser config/testUser.cnf cert-authority/cert-authority.crt cert-authority/cert-authority.key false`

authenticate with certificate and interact with kube-apiserver

```sh
k get secret test --server=https://127.0.0.1:6443 --client-certificate=/opt/cks/certs/testUser.crt --certificate-authority=/opt/cks/certs/cert-authority.crt --client-key=/opt/cks/certs/testUser.key
```

### authorization

> add CN and O in user cnf file before generating cert:
>
> ```sh
> CN=testUser
> O=cks-developers
>```

create clusterrole and clusterrolebinding

use context for test user - refer to [notes](#notes)

```sh
k config use-context cks-lab-ctx 

cat<<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cks-developers
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: cks-developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cks-developers
  apiGroup: rbac.authorization.k8s.io
EOF
```

created roles are at: [roles](manifests/roles.yaml)

> A rolebinding can reference a ClusterRole for authorization purposes, this would mean reusable roles per namespace

after the roles are created, we enable RBAC authorization and restart the kube-api server:

> add to kube-apiserver `--authorization-mode=RBAC`

verify the user: `k auth whoami`

check what the user can do 

```sh
k auth can-i --list

 k auth can-i watch deploy --as=system:serviceaccount:<namespace>:<serviceaccount-name> -n <namespace>
```

> with rbac authorization, the default permissions granted are the API discovery permissions granted to all authenticated principals

## auditing

> Audit records begin their lifecycle inside the kube-apiserver component

Each request generates an audit event at each stage of it's execution, the stages are:

- RequestReceived: events generated as soon as the audit handler receives the request
- ResponseStarted: once the response headers are sent, but before the response body is sent e.g watch
- ResponseCompleted: The response body has been completed
- Panic: panic occurance

Audit policy defines rules about what events should be recorded and what data they should include, the levels are:

- None
- Metadata - log event metadata
- Request - +above and request body
- RequestResponse +above and responsebody

rules in the policy are evaluated top to bottom, so the order matters i.e if we do requestresponse first for a secret object and then metadata later, we may still get the whole secret object in the logs.

```sh
cat > /opt/cks/auth/audit.yaml <<EOF
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
    - group: ""
      resources: ["secrets", "configmaps"]
EOF
```

to log all metadata requests:

```sh
cat > /opt/cks/auth/audit.yaml <<EOF
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF
```

> add to kube-apiserver: `--audit-policy-file=/opt/cks/auth/audit.yaml` `--audit-log-path=/var/log/kube-apiserver-audit.log` `--audit-log-maxage=30`  `--audit-log-maxbackup=10`  `--audit-log-maxsize=100`

check the logs

```sh
tail -n 50 -f /var/log/kube-apiserver-audit.log | grep testUser
```

If the control plane runs the kube-apiserver as a Pod, remember to mount the hostPath to the location of the policy file and log file, so that audit records are persisted.

```yaml

volumeMounts:
  - mountPath: /etc/kubernetes/audit-policy.yaml
    name: audit
    readOnly: true
  - mountPath: /var/log/kubernetes/audit/
    name: audit-log
    readOnly: false

```

we can omit stages at the root level or at the policy level: i.e

```yaml
apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  - level: Metadata
    omitStages:
      - "ResponseCompleted
```

More reading at:

- <https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/>
- <https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/#audit-k8s-io-v1-Policy>

## kubelet

> Ensure authorization mode is via webhook and authentication anonymous is disabled. If not, kubelet is accessible to everyone on the internet

```sh
curl <node-ip>/kubeletport/pods

# or 

kubeletctl pods -i
kubeletctl run "whoami" --all-pods -i
```

> if authentication is via cert, add ca path to authentication section, pass tls cert and tls key for kubelet behind https

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
```

## service accounts

Service Account tokens expire in 1 hour by default, you can change the duration during the create token step or set `--service-account-max-token-expiration` in the kube-apiserver

```bash
k create sa/demo

k create token demo --duration=<> 
```

If you want to obtain an API token for a ServiceAccount, you create a new Secret with a special annotation, `kubernetes.io/service-account.name`

service account using token secret:
> the control plane automatically generates a token for the service account, and stores it into the associated secret

- create secret

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: build-robot-secret
    annotations:
      kubernetes.io/service-account.name: build-robot
  type: kubernetes.io/service-account-token
  ```

- review the token:

  ```sh
  k create -oyaml -f - <<EOF
  apiVersion: authentication.k8s.io/v1
  kind: TokenReview
  spec:
    token: $(kubectl get secret/build-robot-secret -ojsonpath='{.data.token}' | base64 -d)
  EOF
  ```

- verify the token:

  ```sh
  k exec deploy/test -it -- curl -k https://kubernetes.default/api/v1/namespaces/default/secrets -H "Authorization: Bearer $(kubectl get secret/build-robot-secret -ojsonpath='{.data.token}' | base64 -d)"
  ```

if the service account is used in a ds/deploy/sts:

- review spec
  > pods uses token generated when it is associated with a service account in path `/var/run/secrets/kubernetes.io/serviceaccount/`

  ```yaml
  ...spec
    "serviceAccount": "cilium",
    "serviceAccountName": "cilium"
  ...spec
  ```

- get the token path where it's mounted:

  ```sh
  # mount -l to list mounts

  # get the token:
  k exec ds/cilium -n kube-system -- /bin/bash -c "mount -l | grep /run/secrets/kubernetes.io/"
  ```

- review the token:

  ```sh
  k create -oyaml -f - <<EOF
  apiVersion: authentication.k8s.io/v1
  kind: TokenReview
  spec:
    token: $(k exec ds/cilium -n kube-system -- cat /run/secrets/kubernetes.io/serviceaccount/token)
  EOF
  ```

- verify the token:

  ```sh
  we could do: k create token cilium -n kube-system but we exec and get the token for now :)

  k exec deploy/test -it -- curl -k https://kubernetes.default/apis/networking.k8s.io/v1/namespaces/default/networkpolicies -H "Authorization: Bearer $(k exec ds/cilium -n kube-system -- cat /run/secrets/kubernetes.io/serviceaccount/token)"
  ```

For the tokens: we can check them via jwt decoder since it matches RFC-519 <https://www.rfc-editor.org/rfc/rfc7519>

### service account security

remove unneeded tokens by the pods esp the default service account with:

```yaml
  serviceaccount:
    automountServiceAccountToken: false
  ...

  pod:
    spec: 
      automountServiceAccountToken: false
  ...

  deploy: 
    spec/template/spec: 
      automountServiceAccountToken: false
```

the automountServiceAccountToken value precedence:  podlevel precendence > serviceaccountlevel value

Projected volumes: combine multiple volume sources into one mount

> We can use it to mount service account to pod if automountServiceAccountToken is set to false on the serviceaccount and we're unable to update podsepc's automountServiceAccountToken value
>
> By default, this mounts the default service account, to change serviceaccount: add the name in the serviceAccountName field.
>
> Note: A container using a projected volume source as a subPath volume mount will not receive updates for those volume .

More Reading:

> - <https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin>
> - <https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/#directly-accessing-the-rest-api>

## pod/container security

### security context

securitycontext: priviledge and access control for a pod/container

to get the structure of a security context on pod and container level:

```sh
k explain po.spec.securityContext --recursive

k explain po.spec.containers[*].securityContext --recursive

```

some important fields:

- runasUser: the user container uses
- runasGroup: the group container uses
- fsGroup: control permissions of files created in a mounted volume
  - (does not work with hostpath volumes)
  - best use case if volume is used by multiple containers
- readOnlyRootFilesystem:
  - mounts root directory as read only, we can mount required directories as empty dir volumes if the applications require it
  - this option may not be needed if the application writes logs, cache or manage runtime config in the root filesystem

if we run our pods as priviledged: they are given all capabilites even the ones they dont need (not recommended to be used,the best option alternatively only add required capabilites)
  
capabilites are added/removed on the container level:

- add: appends the capabilites
- drop: removes capabilities (we can use 'ALL' to drop all capabilities it does not remove above added ones *this is recommended*)

more reading sources:

- <https://kubernetes.io/docs/tasks/configure-pod-container/security-context/>
- <https://linux-audit.com/kernel/capabilities/linux-capabilities-hardening-linux-binaries-by-removing-setuid/>

### linux capabilities

get and remove capability of process

```sh
getcap $(which "process")

setcap "<cap>=''" $(which "process")

setcap -r $(which "process")
```

check granted capabilities via pid

```sh
more /proc/<process-pid>/status

capsh --decode="value of capeff from above" 
```

check syscalls:

```sh
strace -p <pid>
```

> to start a process with port< 1024: we need to give it cap_net_bind_service

more reading sources:

- more capabilites here: `man capabilites` or at <https://man7.org/linux/man-pages/man7/capabilities.7.html>

## admission controllers

- Validating: allow/deny requests based on certain rules
- Mutating: modify requests before processing, then proceed to allow/deny them

Admission phases: <https://kubernetes.io/docs/reference/access-authn-authz/admission-control-phases.svg>

by default we have some enabled admission controllers found here:
<https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/> or at: `kube-apiserver -h | grep -e enable-admission-plugins`

### alwayspullimages admission controller

> add: `--enable-admission-plugins=AlwaysPullImages` to kube-apiserver
>
> to pull images, the kubelet interacts with the runtime(docker, containerd) to pull the image from the registry.
>
> The kubelet also checks the image digest if it matches it's cached image's digest
> never use image with latest tag, specify a version
> image pull policy:
  >
  > - (default is always)
  > - never, assumes image is already on the node

we can use the `AlwaysPullImages` admission controller to ensure images are always pulled by allowed users due to risk of the 'Never' keyword

### pod security admission controller

ensure pods running meet specified security requirements

Pod Security Admission (PSA) controller enforces the pod security standards (PSS): <https://kubernetes.io/docs/concepts/security/pod-security-standards/>

We have three policies in the standards from strict to relaxed:

- priviledged: allows privileged escalations (lack of restrictions)
- baseline: minimally strict while blocking known priviledged escalations i.e prevents hostpath mounting , allows undefined fields
- restrictive: strict, follows pod hardening guides

for each polict we have 3 modes for the policies:

- warn:
- audit: adds audit annotation in the audit log event record
- enforce

the modes don't apply to workload objects i.e daemon,sts, deploy but only when pod is created

to enfore policies on namespace level, we set the label:
`pod-security.kubernetes.io/<mode>=<policy>`

> we can set any/all different levels of modes ie. we can warn, audit and enforce any/all of the policies e.g

```yaml

  pod-security.kubernetes.io/enforce=baseline
  pod-security.kubernetes.io/enforce=restricted
  pod-security.kubernetes.io/audit=priviledged
  pod-security.kubernetes.io/enforce=baseline
  pod-security.kubernetes.io/warn=restricted

```

> we can also set: the mode version *this is recommened*: `pod-security.kubernetes.io/<mode-version>-version=<version>`
>
> The version in this case in the `k version`
>
> if no version is set, we use the default version of the PSA policy supported by the cluster (this is usually the latest stable version)

```yaml

pod-security.kubernetes.io/warn-version: v1.33
pod-security.kubernetes.io/audit-version: v1.33
pod-security.kubernetes.io/enforce-version: v1.33
```

when label is changed, the PSA verifies all pods in the target namespace, it doesn't affect already running pods

> to evaluate security profile changes, it's recommeded to use the --dry-run=server flag to get info on any policy check failures

we can add exemptions for pod security enforcement in the admission controller config file:

```yaml
  apiVersion: apiserver.config.k8s.io/v1
  kind: AdmissionConfiguration
  plugins:
  - name: PodSecurity
    configuration:
      apiVersion: pod-security.admission.config.k8s.io/v1
      kind: PodSecurityConfiguration
      defaults:
        enforce: "privileged"
        enforce-version: "latest"
        audit: "privileged"
        audit-version: "latest"
        warn: "privileged"
        warn-version: "latest"
      exemptions:
        # Array of authenticated usernames to exempt.
        usernames: []
        # Array of runtime class names to exempt.
        runtimeClasses: []
        # Array of namespaces to exempt.
        namespaces: []

```

> add: `--enable-admission-plugins=PodSecurity` to kube-apiserver
>
> add `--admission-control-config-file=""` to kube-apiserver

### imagepolicywebhook admission controller

allows kubernetes to check with external service before allowing pods to run based on their provided container images

> add: `--enable-admission-plugins=ImagePolicyWebhook` to kube-apiserver
>
> add: `--admission-control-config-file` to kube-apiserver

```yaml
  apiVersion: apiserver.config.k8s.io/v1
  kind: AdmissionConfiguration
  plugins:
    - name: ImagePolicyWebhook
      configuration:
        imagePolicy:
          kubeConfigFile: <path-to-kubeconfig-file>
          allowTTL: 50
          denyTTL: 50
          retryBackoff: 500
          defaultAllow: true
```

```yaml
# <path-to-kubeconfig-file>
  # clusters refers to the remote service.
  clusters:
    - name: name-of-remote-imagepolicy-service
      cluster:
        certificate-authority: /path/to/ca.pem    # CA for verifying the remote service.
        server: https://images.example.com/policy # URL of remote service to query. Must use 'https'.

  # users refers to the API server's webhook configuration.
  users:
   - name: name-of-api-server
     user:
      client-certificate: /path/to/cert.pem # cert for the webhook admission controller to use
      client-key: /path/to/key.pem          # key matching the cert
```

with this, we could ideally have a servce running in a separate security cluster to validate the request before it's created

## system hardening

Discrentionary Access Control - allows restriction of access to objects depending on identity of users/groups they belong to

> Issue with this, programs running as users can access the same file users own that could be sensitive

Manadatory Access Control - access to resources is regulated by a central authority based on predefined security policies (confined, unconfined)

App armor helps with the MAC. There are 3 modes:

- unconfined
- complain
- enforce

In k8s, we can use apparmor in the securityContext for pods and containers, profiles are:

- runtimedefault
- localhost  (if profile is in the node's filesystem), unconfined

```sh
apparmor_parser -q <profile-filename>
apparmor_status
```

app armor profile is added on the container:

```yaml
  securityContext:
    appArmorProfile:
      type: Localhost
      localhostProfile: <profile-name>
```

> the container runtime - executes and manages container images on a node e.g docker, podman, containerd.
>
> High level runtime does not launch the container, the low level runtime does it (runc).

the container runtime pulls image, unpacks image to file system, generates oci spec and launches compatible runtime

- high level container runtime: containerd
- low level container runtime: runc (containerd spins up runc runtime to run containers)

*Container Runtime Interface (CRI)* - plugin interface that enables the kubelet use a variety of container runtimes without need for recompiling

> Seccomp filters provide isolation between application and host kernel, it requires whitelist of systemcalls

gVisor is a kernel that runs a normal unpriviledged process, it intercepts application system calls and thus reducing system calls made to the host kernel by creating an isolation boundary

we can use gVisor sandbox runtime (runsc) instead of runc when running untrusted applications e.g (cloning repo and running application from there)

in K8s, to use a runtimeClass, use the RuntimeClass Keyword

To create a runtime class:

- Check your CRI how to configure runtimes e.g containerd: <https://github.com/containerd/containerd/blob/main/docs/cri/config.md#runtime-classes>
- Create runtime..

    ```yaml
    apiVersion: node.k8s.io/v1
    kind: RuntimeClass
    metadata:
      name: demo-rc
    handler: runsc # e.g crun, gvisor, kata, runsc
    ```

- Using it..
  
  ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: demo-rc-pod
    spec:
      runtimeClassName:  demo-rc
  ```

## cluster and container scanning

We can use open source tools to scan images, cluster, static analysis:

- We can use kube-bench to scan the cluster
- We can use open source trivy to scan images, generated SBOMS
- We can use checkov for static analysis

> docker:
>
> remove users from docker group, deny traffic to docker daemon
>
> the COPY --from=0 line copies just the built artifact from the previous stage into this new stage

conftest tool uses the Rego language from Open Policy Agent for writing policies aiming to perform static analysis of Kubernetes, Docker, YAML, JSON, Helm charts, and other file formats.

uncomplicated firewall (UFW) is a simplified frontend for Linux iptables tool, which acts as a host-based firewall on Linux servers.

### trivy

We can use open source trivy to scan images

```bash
trivy image <image-name>
```

### kube-bench

We can use kube-bench to scan the cluster

We can specify targets of the benchmark to run e.g `node`, `master`,`etcd`

```bash
kube-bench run --targets=node
```

list checks to run in a document e.g 4.1.1 and 4.2.1 from above output

```bash
kube-bench run --targets=node --check="4.1.1,4.2.1"
```

More flags and commands:

- <https://github.com/aquasecurity/kube-bench/blob/main/docs/flags-and-commands.md>

### sbom

List of software components that make up the software application

We can use trivy, syft, bom to generate sbom.

common format are `cyclonedx` and `spdx(software package data exchange)`

> spdx: <https://spdx.dev/>
>
> cyclonedx: <https://cyclonedx.org/>

using trivy:

```sh
# spdx
trivy image --format spdx-json --ouput <file-s.json> <image-name> 

# cyclonedx
trivy image --format cyclonedx --ouput <file-c.json> <image-name> 

trivy sbom <file-s.json>
trivy sbom <file-c.json>
```

using bom:

```sh
# spdx
bom generate spdx-json --image <image-RepoDigests> --ouput <file.json>

bom document outline <file.json> 
```

## runtime security

We can use tools to set rules for our runtime e.g falco

### falco

runtime security tool that allows users to set rules that will trigger alerts when conditions are met.

captures:

- Host based events
- Container based events

falco structure:

- config.d  - add your own configs
- falco.yaml  - main config file
- falco_rules.local.yaml - add your own rules here
- falco_rules.yaml  - default rules (don't change)
- rules.d - add your own rules here

falco rule structure:

```yaml
- rule: Rule name
  desc: Rule description
  condition: logical expression of rule when it should trigger an alert
  output: alert message when rule condition is met
  priority: priority -> emergency to debug
```

example rule to trigger when sudo is used in host:

```sh
cat > /etc/falco/rules.d/sudo-rule.yaml <<EOF
- rule: Detect sudo usage
  desc: detects sudo usage in host
  condition: spawned_process and proc.name = "sudo"
  output: sudo used in host machine by user=%user.name user_uid=%user.uid
  priority: CRITICAL
EOF
```

Falco outputs the container id and we can use it to find container name, pods name using tools like docker, podmand and crictl:

```bash
k describe pod <pod-name> (usually shows the container id non truncated)

# crictl container commands
crictl ps --id <container-id> --namespace <namespace> # output contains pod id 

crictl inspect <container-id>  # grep by args to find process args

# crictl pod commands
crictl pods --id <pod-id>

crictl pods --name <deployment-name> --namespace <namespace>

crictl ps --pod <pod-id> # output contains container id

# crictl inspect image
crictl inspecti <image-id>

# docker exec into kind nodes
docker exec <node-name> -it /bin/bash

# docker run a pod in another pod's pid namespace
docker run -d --name test --pid=container:init nginx:latest 

# podman run a pod in another pod's pid namespace
podman run -d --name test --pid=container:init nginx:latest 

```

macros are predefined rule conditions that we can reuse

```yaml
- macro: <name>
  condition: <condition>
```

> priviledged pods have access to /dev/mem or if they have been granted the permission

debug falco and it's rules:

- check the falco logs: `journalctl -u falco-modern-bpf.service -f -n 10`
- check falco status: `systemctl status <falco-service>`
- rules:
  - correct rules section
  - syslog output
  - check priority of rules
- configs:
  - points to correct additional directory for configs
  - points to correct directory for rules

if all else fails, start falco manually:
`falco --unbuffered | grep <>`

more readings:

- <https://falco.org/docs>
- <https://falco.org/docs/rules/supported-fields>

## kubeadm

Upgrade kubelet config:

```bash
kubeadm upgrade node phase kubelet-config --dry-run 

kubeadm upgrade node phase kubelet-config
```

check if changes reflected

```bash
k get --raw "/api/v1/nodes/<node-id>/proxy/configz"
```

> if no runtime is specified, kubeadm checks socket paths and uses it, if it finds docker and containerd, docker takes precendence

## cilium

cilium install:

> For ipsec create the ipsec keys secret first

```bash
cilium install --version 1.17.1 --set encryption.enabled=true --set encryption.type=ipsec

cilium status

cilium hubble enable --ui

cilium hubble ui
```

A good visualization of cilium network policies is: <https://editor.networkpolicy.io/>

> If a Pod doesn't have a NetworkPolicy all traffic is allowed. Once a policy is associated, the policy rules apply to the pod

## further reading

- <https://blog.axiomio.com/demystifying-kubernetes-understanding-cni-csi-and-cri-9bf1976bbc7d>
- allowPrivilegeEscalation: <https://github.com/kubernetes/design-proposals-archive/blob/main/auth/no-new-privs.md#changes-of-securitycontext-objects>
