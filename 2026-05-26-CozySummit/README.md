---
title: Building a Multi-Cluster Service Mesh from the Ground Up with Kilo
event: CozySummit 2026
location: virtual
author: Lu Servén Marín
theme:
  path: ./theme.yaml
---

<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- font_size: 2 -->
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
FAQ
===
<!-- column: 1 -->
* why do we need *another* multi-cluster service mesh?
* how do we automate cluster peering?
* why not just load-balancer services?
* isn't kubernetes basically a service-mesh?
<!-- end_slide -->

<!-- jump_to_middle -->
<!-- font_size: 2 -->
Let's Define Some Terms
===

<!-- end_slide -->

Let's Define Some Terms
===
<!-- font_size: 2 -->
<!-- jump_to_middle -->
## What's a Service Mesh?


<!-- end_slide -->

Let's Define Some Terms
===
## What's a Service Mesh?

<!-- font_size: 2 -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
* enable service connectivity
  * abstract networking
  * abstract discovery
* provide features you'd have to re-implement
  * encryption
  * load-balancing
  * shadowing
  * etc

<!-- end_slide -->

Let's Define Some Terms
===
## What's a Service Mesh?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

>why would you even want that?

<!-- end_slide -->

Let's Define Some Terms
===
## What's a Service Mesh?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

>if they're really so great, name some

<!-- end_slide -->

Let's Define Some Terms
===
## What's a Service Mesh?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

* Linkerd
* Istio
* Cilium
* ...

<!-- end_slide -->

Let's Define Some Terms
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->
## What's a *Multi-Cluster* Service Mesh?

<!-- end_slide -->

Let's Define Some Terms
===
## What's a *Multi-Cluster* Service Mesh?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

it provides the same features but across cluster boundaries

<!-- end_slide -->

Let's Define Some Terms
===
## What's a *Multi-Cluster* Service Mesh?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

>ok, so why would you want *that*?

<!-- end_slide -->

Let's Define Some Terms
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->
## What Are We Building?

<!-- end_slide -->

Let's Define Some Terms
===
## What Are We Building?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

...the hand-wavy part

<!-- end_slide -->

Let's Define Some Terms
===
## What Are We Building?

<!-- font_size: 2 -->
<!-- jump_to_middle -->
>are we really building all of that?
from the ground up?
<!-- pause -->
no, i make the rules!

<!-- end_slide -->

Let's Define Some Terms
===
## What Are We Building?

<!-- font_size: 2 -->
<!-- jump_to_middle -->

<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
we're going to focus on:

<!-- column: 1 -->
<!-- font_size: 1 -->
* enable service connectivity
  * abstract networking
  * abstract discovery
* ~~provide features you'd have to re-implement~~
  * ~~encryption~~
  * ~~load-balancing~~
  * ~~shadowing~~
  * ~~etc~~

<!-- incremental_lists: false -->

<!-- end_slide -->

<!-- font_size: 2 -->
<!-- jump_to_middle -->

The Plan
===

<!-- end_slide -->

The Plan
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->

* enable service connectivity
  * abstract networking
  * abstract discovery

<!-- incremental_lists: false -->

<!-- end_slide -->

The Plan
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
## The Rest of the Owl

<!-- column: 1 -->
![](owl.jpg)

<!-- end_slide -->

The Plan
===
## The Rest of the Owl

<!-- font_size: 2 -->
<!-- newline -->
<!-- newline -->

* enable service connectivity
  * abstract networking
    * full routability within clusters
      * pod-to-pod connectivity
      * pod-to-host connectivity
      * pod-to-service connectivity
    * full routability between clusters
      * cluster-to-cluster connectivity
  * abstract discovery
    * enable local service discovery
    * enable remote service discovery

<!-- incremental_lists: false -->

<!-- end_slide -->

<!-- font_size: 2 -->
<!-- jump_to_middle -->
From the Ground Up
===

<!-- end_slide -->

From the Ground Up
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->

## Pod-to-Pod Connectivity

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->

the laws of Kubernetes networking
<!-- pause -->
1. every pod needs to be able to talk to every other pod
<!-- pause -->
2. ... that's pretty much it

<!-- 
speaker_note: |
  also, every pod needs a unique IP address from the pod CIDR
  every container in a pod needs to be able to talk to other containers on localhost
-->

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->
>how do we implement this?
<!-- pause -->
CNI

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
[ kubectl create pod ... ] -> [ Kubernetes API ]
[ Kubelet ] -> [ Kubernetes API ]
[ Kubelet ] -> [ container runtime ]
[ container runtime ] -> [ CNI plugin ]
[ CNI plugin ] => [ creates a network namespace\n with the right specs ]
EOF
```
<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

```json
    {
       "cniVersion": "0.4.0",
       "name": "a-basic-cni-network",
       "plugins": [
          {
             "name": "kubernetes",
             "type":" bridge",
             "bridge": "kube-bridge",
             "isDefaultGateway": true,
             "forceAddress": true,
             "mtu": 1500,
             "ipam": {
                "type": "host-local"
             }
          },
          {
             "type": "portmap",
             "snat": true,
             "capabilities": {
                "portMappings": true
             }
          }
       ]
    }
```

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
[ pod-1 ] - default route -> [ bridge device ]
[ bridge device ] - routing table -> [ pod-2 ]
EOF
```

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->
>cool, what about a pod on a different node?

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
[ pod-1 ] - default route -> [ bridge device ]
[ bridge device ] -> [ host network ]
[ host network ] -> [ ??? ]
EOF
```
<!-- 
speaker_note: |
  our basic CNI config only works for a single-node cluster
  we *might* be lucky and our hosts could be running
  on a kubernetes-aware overlay, like in GKE or something
  in which case once the packet leaves the host network
  it would magically find it's way to the right host,
  which would be able to route it to the pod.
  but short of that...
-->

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->
we need a networking provider
<!--
speaker_note: |
  we need to use an overlay network configured
  by  real networking provider.
-->

<!-- pause -->
there's like, a million of them
<!--
speaker_note: |
  networking providers are arbitrary programs that configure routes,
  interfaces, overlays, anything... 
  they do whatever they have to do to connect pods in a kubernetes cluster
  they can use eBPF, BGP, ipip, vxlan, any technology they want
  to discover and program routes, and create the dataplane
  for the pod network.
  they can also do fancy things like enforce network policies, or
  provide multi-cloud connectivity, like Kilo.
-->

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
[ pod-1 ] -> {flow: north} [ bridge device 1 ]
[ bridge device 1 ] -> {flow: north; end: south;} [ host 1 network ]
[ host 1 network ] => [ host 2 network ]
[ host 2 network ] -> {flow: south} [ bridge device 2 ]
[ bridge device 2 ] -> {flow: south} [ pod-2 ]
[ networking\nprovider ] ~ program routes ~> {flow: south} [ host 1 network ]
[ networking\nprovider ] ~ program routes ~> {flow: south} [ host 2 network ]
EOF
```

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->
### Let's Use Kilo

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity
### Let's Use Kilo

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
(host 1
[ pod-1 ]
)
(host 2
[ pod-2 ]
)
[ pod-1 ] = direct routing on physical network => [ pod-2 ]
EOF
```
<!--
speaker_note: |
  easy-mode: 
  you throw the packet out the wire from the right interface and let the physical network route it.
  kilo programs routes that direct packets
  out the device that you would use to contact the host
  to which that pod belongs
-->

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity
### Let's Use Kilo

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
(host 1
[ pod-1 ]
[ o1 ]
)
(host 2
[ pod-2 ]
[ o2 ]
)
[pod-1 ] - encapsulate -> [ o1 ] {label: overlay}
[ o1 ] = physical\nnetwork => [ o2 ] {label: overlay} - decapsulate -> [ pod-2 ]
EOF
```

<!--
speaker_note: |
  hard-mode: 
  you can't trust the physical network to know how to route pod IPs
  e.g. AWS VPCs with strict address checks
  you use an overlay network and wrap the packet in an IPIP header and
  address it to the host node, since the physical network must now how to route that
-->

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Pod Connectivity
### Let's Use Kilo

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
(host 1
[ pod-1 ]
[ wg1 ]
)
(host 2
[ pod-2 ]
[ wg2 ]
)
[ pod-1 ] - encrypt -> [ wg1 ] {label: WireGuard}
[ wg1 ] = Internet => [ wg2 ] {label: WireGuard} - decrypt -> [ pod-2 ]
EOF
```

<!--
speaker_note: |
  harder-mode: 
  the IP of the host node is not routable by the physical network because
  it doesn't belong to our network! it's in another cloud or datacenter.
  In that case, we need to send the packet over the internet
  to do that, we discover the public IP address of the host node
  and use WireGuard as an overlay network:
  we encrypt the packet using the target node's public key, wrap it in a UDP
  dataframe and send it to the public IP address
-->

<!-- end_slide -->

From the Ground Up
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->

## Pod-to-Service Connectivity

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Service Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->

>what even is a service?
<!-- pause -->
services are just a convenient abstraction providing a stable network identity for a set of variable pod ips

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Service Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->

kube-proxy

<!--
speaker_note: |
  kube-proxy is the canonical implementation for pod-to-service
  connectivity
  by default it uses runs a daemonset that watches services
  and endpoints in the k8s API and programs iptables rules
  to NAT between the service cluster IP and a random pod IP in the endpoints resource

  you can also run kube-proxy in IPVS mode or replace it entirely with
  something like Cilium, which implements the same functionality using eBPF.
-->

<!-- end_slide -->

From the Ground Up
===
## Pod-to-Service Connectivity

<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
(host network
[ bridge device ]
[ iptables ]
)
[ pod-1 ] - packet to service-a -> [ bridge device ]
[ bridge device ] -> [ pod-2 ]
[ iptables ] - DNAT service-a\nto pod-2 -> [ bridge device ]
EOF
```
<!-- end_slide -->

From the Ground Up
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->

## Cluster-to-Cluster Connectivity

<!-- end_slide -->

From the Ground Up
===
## Cluster-to-Cluster Connectivity

<!-- jump_to_middle -->
<!-- font_size: 1 -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
(cluster 1\nhost 1
[ pod-1 ]
[ bridge device ]
[ host network ]
)
(cluster 2\nhost 2
[ ??? ]
)
[ pod-1 ] - packet to pod-3\nin another cluster\nvia default route -> [ bridge device ]
[ bridge device ] -> [ host network ]
[ host network ] -> [ ??? ]
EOF
```
<!-- pause -->
<!-- font_size: 2 -->
look familiar?

<!-- end_slide -->

From the Ground Up
===
## Cluster-to-Cluster Connectivity

<!-- jump_to_middle -->
<!-- font_size: 2 -->
this is the same problem as pod-to-pod connectivity
<!-- 
speaker_note: |
  it's literally the same issue as pod-to-pod connectivity
  just the problem domain requires discovering routes to hosts
  whose info is in another API and the underlying network can't be trusted
-->

<!-- end_slide -->

From the Ground Up
===
## Cluster-to-Cluster Connectivity

<!-- jump_to_middle -->
<!-- font_size: 2 -->
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
requirements
<!-- column: 1 -->
* discover routes
* secure underlying network
<!-- pause -->
* the rest of the owl!

<!-- end_slide -->

From the Ground Up
===
## Cluster-to-Cluster Connectivity

<!-- font_size: 2 -->
<!-- jump_to_middle -->
we need a networking provider
<!-- 
speaker_note: |
  once again, this problem really is solved best by a networking provider
  it's really the exact same problem
-->

<!-- end_slide -->

From the Ground Up
===
## Cluster-to-Cluster Connectivity

<!-- jump_to_middle -->
```bash +exec_replace
cat <<EOF | graph-easy --as=boxart 
(cluster 1\nhost 1
[ pod-1 ]
[ wg1 ]
)
(cluster 2\nhost 2
[ pod-2 ]
[ wg2 ]
)
[ pod-1 ] - encrypt -> [ wg1 ] {label: WireGuard}
[ wg1 ] = Internet => [ wg2 ] {label: WireGuard} - decrypt -> [ pod-2 ]
EOF
```

<!-- end_slide -->

From the Ground Up
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->
## Local Service Discovery
<!-- 
speaker_note: |
  let's simplify our lives!
  this problem is mostly solved for us by DNS
  Kubernetes implements really nice discovery for services and pods
  using cluster-local DNS
-->

<!-- end_slide -->

From the Ground Up
===
## Local Service Discovery

<!-- font_size: 2 -->
<!-- jump_to_middle -->
### DNS
<!-- end_slide -->

From the Ground Up
===
## Local Service Discovery
### DNS

<!-- font_size: 2 -->
<!-- jump_to_middle -->
>why?

>why not?
<!-- 
speaker_note: |
  one of the reasons we don't "just" use DNS
  is because multi-cluster service mesh normally
  doesn't integrate with a cluster-native DNS
  and that's somewhat dictated by the choice of dataplane

  if our data plane IS kubernetes native services, then
  we get DNS for free!
-->

<!-- end_slide -->

From the Ground Up
===

<!-- font_size: 2 -->
<!-- jump_to_middle -->
## Remote Service Discovery
<!-- 
speaker_note: |
  same problem as before, just on a new scale.
  it's really the same question...
  if we've chosen to use K8s services as our dataplane
  and cluster DNS as our discovery service...
  then we just need a way to synchronize services
  across clusters!
  
-->

<!-- end_slide -->

From the Ground Up
===
## Remote Service Discovery

<!-- font_size: 2 -->
<!-- jump_to_middle -->
enter multi-cluster services api
<!-- 
speaker_note: |
  it turns out there is a standard for this in upstream k8s already!
  how it works?
  someone creates a service
  you create an service export referencing it
  undefined how a service import is created
  controller mirrors a service + endpoitnslice from the service import object
-->

<!-- end_slide -->

From the Ground Up
===
## Remote Service Discovery

<!-- font_size: 2 -->
<!-- jump_to_middle -->
[github.com/squat/service-reflector](https://github.com/squat/service-reflector)

<!-- end_slide -->

From the Ground Up
===

<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- font_size: 2 -->
* enable service connectivity
  * abstract networking
    * full routability within clusters
      * pod-to-pod connectivity
      * pod-to-host connectivity
      * pod-to-service connectivity
    * full routability between clusters
      * cluster-to-cluster connectivity
  * abstract discovery
    * enable local service discovery
    * enable remote service discovery

<!-- end_slide -->

<!-- font_size: 2 -->
<!-- jump_to_middle -->
Demo
===

<!-- end_slide -->

Demo
===
## Create Clusters

```bash +exec +pty:80:15
# create clusters
kind create cluster --config kind-1.yaml --kubeconfig k1
kind create cluster --config kind-2.yaml --kubeconfig k2
```

<!-- end_slide -->

Demo
===
## Install Kilo

```bash +exec +pty:80:5
# install kilo
kubectl --kubeconfig k1 create secret generic kubeconfig --from-file=kubeconfig=k1 -n kube-system
kubectl --kubeconfig k2 create secret generic kubeconfig --from-file=kubeconfig=k2 -n kube-system

kubectl --kubeconfig k1 apply -f https://raw.githubusercontent.com/squat/kilo/refs/heads/main/manifests/crds.yaml
kubectl --kubeconfig k2 apply -f https://raw.githubusercontent.com/squat/kilo/refs/heads/main/manifests/crds.yaml

kubectl --kubeconfig k1 apply -f kilo-kind-userspace.yaml
kubectl --kubeconfig k2 apply -f kilo-kind-userspace.yaml

# patch k2 to give it a different kilo CIDR
kubectl --kubeconfig k2 patch ds -n kube-system kilo -p '{"spec": {"template":{"spec":{"containers":[{"name":"kilo","args":["--hostname=$(NODE_NAME)","--create-interface=false","--kubeconfig=/etc/kubernetes/kubeconfig","--mesh-granularity=full","--subnet=10.6.0.0/16"]}]}}}}'

# ensure cluster is stable
kubectl --kubeconfig k1 wait nodes --all --for=condition=Ready
kubectl --kubeconfig k2 wait nodes --all --for=condition=Ready
```

<!-- end_slide -->

Demo
===
## Install Webcam Service

```bash +exec +pty:80:5
# install webcam service in k2
kubectl --kubeconfig k2 apply -f https://raw.githubusercontent.com/squat/generic-device-plugin/main/manifests/generic-device-plugin.yaml
kubectl --kubeconfig k2 apply -f mjpeg.yaml
kubectl --kubeconfig k2 wait --for=condition=Ready pod/mjpeg
```

<!-- end_slide -->

Demo
===
## Generate Image from Webcam Service

```bash +exec
# connect to service
PORT_FORWARD_OUTPUT="$((kubectl --kubeconfig k2 port-forward svc/mjpeg http & echo $!) | (sed '/Forwarding from/q' ; cat > /dev/null &))"
PORT_FORWARD_PID="$(echo "$PORT_FORWARD_OUTPUT" | sed -n 1p)"
PORT_FORWARD_HOST="$(echo "$PORT_FORWARD_OUTPUT" | sed -n 's/Forwarding from \(.*\) -> 8080/\1/p')"
trap 'kill "$PORT_FORWARD_PID"' EXIT

# get jpeg
curl -s "http://$PORT_FORWARD_HOST/jpeg" | chafa --format symbols --size 50x50
kill "$PORT_FORWARD_PID"
trap - EXIT
```

<!-- end_slide -->

Demo
===
## Peer Clusters

```bash +exec +pty:80:5
# Register the nodes in cluster1 as peers of cluster2.
for n in $(kubectl --kubeconfig k1 get no -o name | cut -d'/' -f2); do
    # Specify the service CIDR as an extra IP range that should be routable.
    kgctl --kubeconfig k1 showconf node "$n" --as-peer -o yaml --allowed-ips 10.43.0.0/16 | kubectl --kubeconfig k2 apply -f -
done
# Register the nodes in cluster2 as peers of cluster1.
for n in $(kubectl --kubeconfig k2 get no -o name | cut -d'/' -f2); do
    # Specify the service CIDR as an extra IP range that should be routable.
    kgctl --kubeconfig k2 showconf node "$n" --as-peer -o yaml --allowed-ips 10.45.0.0/16 | kubectl --kubeconfig k1 apply -f -
done
```

<!-- end_slide -->

Demo
===
## Generate Image from Peered Cluster Using Remote Service

```bash +exec
(
    docker exec 1-control-plane apt update
    docker exec 1-control-plane apt install --yes dnsutils
) > /dev/null 2>&1
docker exec 1-control-plane bash -c 'curl "http://$(dig mjpeg.default.svc.cluster.local @10.45.0.10 +short):8080/jpeg" --output - 2>/dev/null' | chafa --format symbols --size 50x50
```

<!-- end_slide -->

Demo
===
## Generate Image from Peered Cluster Using Local Service

```bash +exec
(
    docker exec 1-control-plane apt update
    docker exec 1-control-plane apt install --yes dnsutils
) > /dev/null 2>&1
docker exec 1-control-plane bash -c 'curl "http://$(dig mjpeg.default.svc.cluster.local @10.43.0.10 +short):8080/jpeg" --output - 2>/dev/null' | chafa --format symbols --size 50x50
```

<!-- font_size: 2 -->
this fails!

<!-- end_slide -->

Demo
===
## Manually Mirror Service

```bash +exec +pty:80:5
cat <<EOF | kubectl --kubeconfig k1 apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mjpeg
spec:
  ports:
    - name: http
      port: 8080
      protocol: TCP
      targetPort: http
---
apiVersion: v1
kind: Endpoints
metadata:
    name: mjpeg
subsets:
  - addresses:
      - ip: $(kubectl --kubeconfig k2 get pod mjpeg -o jsonpath='{.status.podIP}')
    ports:
      - name: http
        port: 8080
        protocol: TCP
EOF
```

<!-- end_slide -->

Demo
===
## Generate Image from Peered Cluster Using Local Service

```bash +exec
(
    docker exec 1-control-plane apt update
    docker exec 1-control-plane apt install --yes dnsutils
) > /dev/null 2>&1
docker exec 1-control-plane bash -c 'curl "http://$(dig mjpeg.default.svc.cluster.local @10.43.0.10 +short):8080/jpeg" --output - 2>/dev/null' | chafa --format symbols --size 50x50
```

<!-- font_size: 2 -->
this works now!

<!-- end_slide -->

Demo
===
## Generate Image from Peered Cluster Using Kubernetes Service Discovery

```bash +exec
docker exec 1-control-plane curl "http://$(kubectl --kubeconfig k1 get service mjpeg -o jsonpath='{.spec.clusterIP}'):8080/jpeg" --output - 2>/dev/null | chafa --format symbols --size 50x50
```

<!-- end_slide -->

Demo
===
## Manually Mirrored Endpoints Are Static and Fragile

```bash +exec
kubectl --kubeconfig k2 delete pod mjpeg
kubectl --kubeconfig k2 apply -f mjpeg.yaml
docker exec 1-control-plane curl "http://$(kubectl --kubeconfig k1 get service mjpeg -o jsonpath='{.spec.clusterIP}'):8080/jpeg" --output - 2>/dev/null | chafa --format symbols --size 50x50
```
<!-- jump_to_middle -->
<!-- font_size: 2 -->
restarting the pod rolls its IP and breaks service discovery on the peered cluster

<!-- end_slide -->

Demo
===

<!-- jump_to_middle -->
<!-- font_size: 2 -->
## We Need a Control Loop
<!-- end_slide -->

Demo
===
## We Need a Control Loop

<!-- jump_to_middle -->
<!-- font_size: 2 -->
[github.com/squat/service-reflector](https://github.com/squat/service-reflector)

<!-- end_slide -->

<!-- jump_to_middle -->
<!-- font_size: 2 -->
Thank You!
===

<!-- end_slide -->

<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- newline -->
<!-- font_size: 2 -->
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
FAQ
===
<!-- column: 1 -->
* why do we need *another* multi-cluster service mesh?
* how do we automate cluster peering?
* why not just load-balancer services?
* isn't kubernetes basically a service-mesh?
