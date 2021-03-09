#!/bin/bash

# INVENTORY
###########
generateInventory() {
    cat > /tmp/hosts << ENDOFFILE
[all:vars]
ansible_python_interpreter=/usr/bin/python3

kube_network_plugin=${CNI_PLUGIN}
nic=${KUBE_NIC_NAME}

kube_exec_on_master=${EXEC_ON_MASTER}

offline=${OFFLINE}
offline_binaries_folder=${KAST_BINARIES}

registry_storage={'filesystem': {'rootdirectory': '/data/registry'}}
registry_capacity_storage=10Gi

node_prefix=${OS}

ceph_local_storage_type=raw
ceph_useAllDevices=false
ceph_deviceFilter=^vd[b-d]
ceph_normal_sized_disks=false

ceph_dashboard_enabled=true
ceph_monitoring_enabled=false

ceph_hostnetwork_enabled=false
ceph_public_network=11.100.200.0/24
ceph_cluster_network=11.100.210.0/24

ceph_multus_network_enabled=${MULTUS_ENABLED}
ceph_multus_cluster_network=kube-system/cluster-conf
ceph_multus_public_network=kube-system/public-conf

cephfs_enabled=false
cephfs_erasurecoded_pool=false
cephfs_datapool_replica_size=3
cephfs_metadatapool_replica_size=3

ceph_rbd_enabled=true
ceph_rbd_replica_size=3

ceph_crash_collector_enabled=false

ceph_rgw_enabled=false
ceph_rgw_erasurecoded_pool=false
ceph_rgw_metadatapool_replica_size=3
ceph_rgw_replica_size=3

[kube_master]
${OS}master1 internal_address=11.${net_addr[${OS}]}.150.11 kube_hostname=${OS}master1

[kube_worker]
$(
for node_num in `seq 1 $WORKER_NB`; do
echo ${OS}worker${node_num} internal_address=11.${net_addr[${OS}]}.150.2${node_num} kube_hostname=${OS}worker${node_num}
done
)

[kube:children]
kube_master
kube_worker

[containerd:children]
kube

[registry]
${OS}worker1 internal_address=11.${net_addr[${OS}]}.150.21 kube_hostname=${OS}worker1

[any]
${OS}master1 internal_address=11.${net_addr[${OS}]}.150.11 kube_hostname=${OS}master1

[ingress]
${OS}worker1 internal_address=11.${net_addr[${OS}]}.150.21 kube_hostname=${OS}worker1

[s3]
${OS}master1 internal_address=11.${net_addr[${OS}]}.150.11 kube_hostname=${OS}master1
$(
for node_num in `seq 1 $WORKER_NB`; do
echo ${OS}worker${node_num} internal_address=11.${net_addr[${OS}]}.150.2${node_num} kube_hostname=${OS}worker${node_num}
done
)

[s3:vars]
s3_cpu_requests=1
s3_browser=true
s3_disk_per_node=4
s3_storage_dir=/data/s3

[ceph_osd]
$(
for node_num in `seq 1 $WORKER_NB`; do
echo ${OS}worker${node_num} internal_address=11.${net_addr[${OS}]}.150.2${node_num} kube_hostname=${OS}worker${node_num}
done
)
ENDOFFILE
}

retrieveArtifacts() {
    if [ "$OFFLINE" = true ]; then
        cd ${KAST_DIR}
        utils/resources-helper.sh download --components="containerd,kube,registry,s3_storage,distributed_storage" --to=${KAST_BINARIES}
    fi
}

calicoClient() {
# deploy calicoctl
    if [ "$CNI_PLUGIN" = 'calico' ]; then
        kubectl apply -f https://docs.projectcalico.org/manifests/calicoctl.yaml
        alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"

        cat <<EOF | calicoctl create -f -
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: pool-test
spec:
  cidr: 192.168.192.0/19
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
EOF

    fi
}

Longhorn() {
    if [ "$LONGHORN_ENABLED" = true ]; then
        kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v0.8.0/deploy/longhorn.yaml

        USER=admin; PASSWORD=admin; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> /tmp/auth
        kubectl -n longhorn-system create secret generic basic-auth --from-file=/tmp/auth

        cat <<EOF | kubectl create -n longhorn-system -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: longhorn-frontend
          servicePort: 80
EOF
    fi
}

Multus() {
    if [ "${MULTUS_ENABLED}" = true ]; then
        ## WHEREABOUTS BEGIN
        kubectl apply -f ${WHEREABOUTS_DIR}/doc/daemonset-install.yaml -f ${WHEREABOUTS_DIR}/doc/whereabouts.cni.cncf.io_ippools.yaml
        ## WHEREABOUTS END

        ## MULTUS BEGIN
        kubectl apply -f ${MULTUS_DIR}/images/multus-daemonset.yml

        if [ "${MULTUS_TECH}" = "macvlan" ]; then
            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: public-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth2",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.200.0/24",
        "range_start": "11.100.200.100",
        "range_end": "11.100.200.200",
        "gateway": "11.100.200.1",
        "log_file" : "/tmp/whereabouts-public.log",
        "log_level" : "debug"
      }
    }'
EOF

            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth3",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.210.0/24",
        "range_start": "11.100.210.100",
        "range_end": "11.100.210.200",
        "gateway": "11.100.210.1",
        "log_file" : "/tmp/whereabouts-cluster.log",
        "log_level" : "debug"
      }
    }'
EOF
        elif [ "${MULTUS_TECH}" = "ipvlan" ]; then
            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: public-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "ipvlan",
      "master": "eth2",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.200.0/24",
        "range_start": "11.100.200.100",
        "range_end": "11.100.200.200",
        "gateway": "11.100.200.1",
        "log_file" : "/tmp/whereabouts-public.log",
        "log_level" : "debug"
      }
    }'
EOF

            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "ipvlan",
      "master": "eth3",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.210.0/24",
        "range_start": "11.100.210.100",
        "range_end": "11.100.210.200",
        "gateway": "11.100.210.1",
        "log_file" : "/tmp/whereabouts-cluster.log",
        "log_level" : "debug"
      }
    }'
EOF
        elif [ "${MULTUS_TECH}" = "bridge" ]; then
            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: public-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "multus_br2",
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.200.0/24",
        "range_start": "10.100.200.100",
        "range_end": "10.100.200.200",
        "gateway": "10.100.200.1",
        "log_file" : "/tmp/whereabouts-public.log",
        "log_level" : "debug"
      }
    }'
EOF

            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "multus_br3",
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.210.0/24",
        "range_start": "10.100.210.100",
        "range_end": "10.100.210.200",
        "gateway": "10.100.210.1",
        "log_file" : "/tmp/whereabouts-cluster.log",
        "log_level" : "debug"
      }
    }'
EOF
        fi
    fi
}
